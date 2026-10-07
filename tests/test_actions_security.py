"""Keep privileged execution away from PR code and mutable dependencies."""

import ast
import fnmatch
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
WORKFLOWS = sorted((REPO / '.github/workflows').glob('*.y*ml'))
ACTIONS = sorted((REPO / '.github/actions').rglob('action.y*ml'))


def condition_value(expression, values):
    """Evaluate the boolean subset used by job gates, without executing code."""
    expression = expression.removeprefix('${{').removesuffix('}}').strip()
    expression = expression.replace('&&', ' and ').replace('||', ' or ')
    for index, (name, value) in enumerate(sorted(values.items(), key=lambda item: -len(item[0]))):
        alias = f'context_{index}'
        expression = expression.replace(name, alias)
        values = dict(values, **{alias: value})

    def evaluate(node):
        if isinstance(node, ast.Constant):
            return node.value
        if isinstance(node, (ast.Name, ast.Attribute)):
            return values[ast.unparse(node)]
        if isinstance(node, ast.BoolOp):
            results = [evaluate(value) for value in node.values]
            return all(results) if isinstance(node.op, ast.And) else any(results)
        if isinstance(node, ast.Compare) and len(node.ops) == 1:
            left, right = evaluate(node.left), evaluate(node.comparators[0])
            if isinstance(node.ops[0], ast.Eq):
                return left == right
            if isinstance(node.ops[0], ast.NotEq):
                return left != right
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Name):
            args = [evaluate(arg) for arg in node.args]
            if node.func.id == 'fromJSON':
                return json.loads(*args)
            if node.func.id == 'contains':
                return args[1] in args[0]
        raise ValueError(f'Unsupported gate: {ast.dump(node)}')

    return evaluate(ast.parse(expression, mode='eval').body)


class ActionsSecurityTest(unittest.TestCase):
    def test_external_actions_and_containers_are_immutable(self):
        for path in WORKFLOWS + ACTIONS:
            for ref in re.findall(r'^\s*(?:- )?uses:\s*([^\s#]+)', path.read_text(), re.M):
                ref = ref.strip('\"\'')
                if ref.startswith('./'):
                    continue
                pattern = (r'docker://[^@]+@sha256:[0-9a-f]{64}' if ref.startswith('docker://')
                           else r'[^@]+@[0-9a-f]{40}')
                self.assertRegex(ref, '^' + pattern + '$', (path.name, ref))

    def test_pinact_rejects_mutable_workflow_and_composite_refs_without_editing(self):
        pinact = subprocess.check_output(['mise', 'which', 'pinact'], cwd=REPO, text=True).strip()
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'action.yml'
            for ref, accepted in (('v4', False), ('main', False), ('a' * 40 + ' # v4.0.0', True)):
                for content in (
                    f'name: Test\non: push\njobs:\n  test:\n    runs-on: ubuntu-latest\n'
                    f'    steps:\n      - uses: actions/checkout@{ref}\n',
                    f'name: Test\ndescription: Test\nruns:\n  using: composite\n'
                    f'  steps:\n    - uses: actions/checkout@{ref}\n',
                ):
                    with self.subTest(ref=ref, composite='composite' in content):
                        path.write_text(content)
                        result = subprocess.run([pinact, 'run', '--fix=false', '--no-api', str(path)],
                                                cwd=directory, capture_output=True, text=True)
                        self.assertEqual(result.returncode == 0, accepted, result.stderr)
                        self.assertEqual(path.read_text(), content)

    def test_workflow_defaults_and_checkout_do_not_grant_write_access(self):
        for path in WORKFLOWS:
            text = path.read_text()
            permissions = re.search(r'^permissions:\n((?:[ \t]+[^\n]*\n)+)', text, re.M)
            self.assertIsNotNone(permissions, path.name)
            self.assertEqual(permissions[1].strip(), 'contents: read', path.name)
            for checkout in re.finditer(r'uses: actions/checkout@[^\n]+\n([^\n]+)\n([^\n]+)', text):
                self.assertEqual(checkout[1].strip(), 'with:', path.name)
                self.assertEqual(checkout[2].strip(), 'persist-credentials: false', path.name)
            self.assertNotIn('pull_request_target:', text, path.name)

    def test_lefthook_rejects_mutable_refs_in_workflows_and_composite_actions(self):
        lefthook = subprocess.check_output(['mise', 'which', 'lefthook'], cwd=REPO, text=True).strip()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ('lefthook.yml', 'mise.toml'):
                (root / name).write_bytes((REPO / name).read_bytes())
            subprocess.run(['git', 'init', '-q', str(root)], check=True)
            for name in ('.github/workflows/test.yml', '.github/actions/test/action.yml'):
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                for ref, accepted in (('v4', False), ('a' * 40 + ' # v4.0.0', True)):
                    content = ('name: Test\njobs:\n  test:\n    steps:\n'
                               f'      - uses: actions/checkout@{ref}\n')
                    path.write_text(content)
                    result = subprocess.run(
                        [lefthook, 'run', 'pre-commit', '--no-auto-install', '--command', 'pinact',
                         '--file', name], cwd=root, capture_output=True, text=True,
                        env=dict(os.environ, MISE_TRUSTED_CONFIG_PATHS=str(root.resolve())))
                    self.assertEqual(result.returncode == 0, accepted, result.stdout + result.stderr)
                    self.assertIn('pinact', result.stdout + result.stderr)
                    self.assertEqual(path.read_text(), content)

    def test_aws_execution_requires_trusted_main_events_and_opt_in(self):
        for account in ('management', 'portfolio', 'sandbox'):
            text = (REPO / f'.github/workflows/_terraform-aws-{account}.yml').read_text()
            block = text.split(f'  terraform-aws-{account}:\n', 1)[1].split('\n  workflow-result-', 1)[0]
            condition = re.search(r'^    if: (.+)$', block, re.M)[1]
            for event in ('pull_request', 'pull_request_target', 'push', 'schedule', 'workflow_dispatch'):
                for ref in ('refs/heads/main', 'refs/heads/feature', 'refs/tags/v1'):
                    for enabled in ('true', 'false', ''):
                        for matrix in ('["base"]', '["_empty"]'):
                            values = {'github.event_name': event, 'github.ref': ref,
                                      'vars.TERRAFORM_EXECUTION_ENABLED': enabled,
                                      'needs.set-matrix.outputs.matrix': matrix}
                            expected = (event in ('push', 'schedule', 'workflow_dispatch')
                                        and ref == 'refs/heads/main' and enabled == 'true'
                                        and matrix != '["_empty"]')
                            self.assertEqual(condition_value(condition, values), expected, values)
            pr = text.split('  terraform-pr-validation:\n', 1)[1].split(f'  terraform-aws-{account}:', 1)[0]
            self.assertIn('backend: "false"', pr)
            self.assertNotIn('aws-credential', pr)
            self.assertNotIn('SLACK_WEBHOOK', pr)
            self.assertNotIn('permissions:', pr)
            self.assertNotIn('delete-pr-comments:', text)
            self.assertIn('terraform-pr-validation,', text)

    def test_pr_generation_cannot_push_repository_changes(self):
        for name in ('terraform-docs.yml', 'terraform-renovate.yml'):
            text = (REPO / '.github/workflows' / name).read_text()
            self.assertNotIn('contents: write', text)
            self.assertNotIn('git-push: true', text)
            self.assertNotIn('EndBug/add-and-commit', text)
        docs = (REPO / '.github/workflows/terraform-docs.yml').read_text()
        self.assertIn('INPUT_GIT_PUSH: "false"', docs)
        self.assertIn('INPUT_FAIL_ON_DIFF: "true"', docs)
        renovate = (REPO / '.github/workflows/terraform-renovate.yml').read_text()
        self.assertIn('git diff --exit-code', renovate)
        self.assertIn('-lockfile=readonly', renovate)
        self.assertNotIn('-upgrade', renovate)

    def test_aws_trust_rejects_pr_branches_tags_other_repositories_and_audiences(self):
        text = (REPO / 'terraform/modules/deploy_role/terraform_aws/main.tf').read_text()
        # Interpret the actual trust conditions, including wildcard behavior.
        conditions = re.findall(
            r'condition\s*\{\s*test\s*=\s*"([^"]+)"\s*'
            r'variable\s*=\s*"([^"]+)"\s*values\s*=\s*\[\s*"([^"]+)"', text)
        self.assertEqual(len(conditions), 2)
        self.assertEqual({key for _, key, _ in conditions}, {
            'token.actions.githubusercontent.com:sub', 'token.actions.githubusercontent.com:aud'})
        for subject in ('repo:tqer39/terraform-aws:ref:refs/heads/main',
                        'repo:tqer39/terraform-aws:pull_request',
                        'repo:tqer39/terraform-aws:ref:refs/heads/feature',
                        'repo:tqer39/terraform-aws:ref:refs/tags/v1',
                        'repo:tqer39/terraform-aws:environment:production',
                        'repo:other/terraform-aws:ref:refs/heads/main'):
            for audience in ('sts.amazonaws.com', 'untrusted.example'):
                claims = {'token.actions.githubusercontent.com:sub': subject,
                          'token.actions.githubusercontent.com:aud': audience}
                checks = []
                for operator, key, value in conditions:
                    value = value.replace('${var.organization}', 'tqer39').replace(
                        '${var.repository}', 'terraform-aws')
                    self.assertIn(operator, ('StringEquals', 'StringLike'))
                    checks.append(claims[key] == value if operator == 'StringEquals'
                                  else fnmatch.fnmatchcase(claims[key], value))
                self.assertEqual(all(checks), subject == 'repo:tqer39/terraform-aws:ref:refs/heads/main'
                                 and audience == 'sts.amazonaws.com', (subject, audience))

    def test_shell_steps_treat_action_inputs_as_data(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            capture = root / 'args.json'
            for tool in ('tflint',):
                stub = root / tool
                stub.write_text('#!/usr/bin/env python3\nimport json, os, sys\n'
                                'open(os.environ["CAPTURE"], "w").write(json.dumps(sys.argv[1:]))\n')
                stub.chmod(0o755)
            malicious = 'terraform/envs/$(touch INJECTED); "quoted directory"'
            env = dict(os.environ, PATH=directory + os.pathsep + os.environ['PATH'],
                       CAPTURE=str(capture), TF_WORKING_DIRECTORY=malicious,
                       TF_PLAN_EXIT_CODE='2', GITHUB_ENV=str(root / 'github-env'))
            validate = (REPO / '.github/actions/terraform-validate/action.yml').read_text()
            command = validate.split('    - name: Run TFLint\n', 1)[1].split('      run: ', 1)[1].split('\n', 1)[0]
            subprocess.run(['bash', '-e', '-c', command], cwd=root, env=env, check=True)
            self.assertEqual(json.loads(capture.read_text()), ['--chdir=' + malicious, '--call-module-type=all'])
            self.assertFalse((root / 'INJECTED').exists())

    def test_plan_failure_and_missing_exit_code_fail_closed(self):
        text = (REPO / '.github/actions/terraform-plan/action.yml').read_text()
        status = text.split('    - name: Set Terraform Plan status\n', 1)[1]
        script = status.split('      run: |\n', 1)[1].split('      env:\n', 1)[0]
        gate = text.split('    - name: Require successful Terraform Plan\n', 1)[1]
        self.assertIn('if: always()', gate)
        self.assertIn('if: always()', status)
        command = gate.split('      run: ', 1)[1].split('\n', 1)[0]
        self.assertNotIn('tfcmt', text)
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'env'
            for code, expected, accepted in (('0', 'no-changes', True), ('2', 'has-diff', True),
                                             ('1', 'error', False), ('', 'unknown-error', False)):
                env = dict(os.environ, TF_PLAN_EXIT_CODE=code, GITHUB_ENV=str(output))
                output.write_text('')
                subprocess.run(['bash', '-e', '-c', script], env=env,
                               check=True, capture_output=True)
                self.assertEqual(output.read_text().strip(), 'TF_PLAN_STATUS=' + expected)
                result = subprocess.run(['bash', '-e', '-c', command],
                                        env=dict(env, TF_PLAN_STATUS=expected))
                self.assertEqual(result.returncode == 0, accepted)

    def test_scripts_do_not_interpolate_github_expressions(self):
        for path in WORKFLOWS + ACTIONS:
            lines = path.read_text().splitlines()
            for i, line in enumerate(lines):
                if not re.match(r'^\s*(?:- )?run:', line):
                    continue
                indent = len(line) - len(line.lstrip())
                script = line
                for following in lines[i + 1:]:
                    if following.strip() and len(following) - len(following.lstrip()) <= indent:
                        break
                    script += '\n' + following
                self.assertNotIn('${{', script, path.name)


if __name__ == '__main__':
    unittest.main()
