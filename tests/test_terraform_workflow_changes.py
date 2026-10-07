"""Exercise event selection with real Git history, without AWS credentials."""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / '.github/scripts/terraform_matrix.py'
SPEC = importlib.util.spec_from_file_location('terraform_matrix', SCRIPT)
MATRIX = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MATRIX)


class WorkflowChangesTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.git('init', '-q')
        self.git('config', 'user.email', 'test@example.com')
        self.git('config', 'user.name', 'Test')
        self.write('.github/workflows/deploy_pipeline/management', 'base\nbase_apne1\n')
        self.write('terraform/envs/management/base/main.tf', '# root\n')
        self.write('terraform/modules/shared/main.tf', '# shared\n')
        self.base = self.commit()

    def git(self, *args):
        return subprocess.check_output(['git', *args], cwd=self.root, text=True).strip()

    def write(self, path, content='changed\n'):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)

    def commit(self):
        self.git('add', '.')
        self.git('commit', '-qm', 'fixture')
        return self.git('rev-parse', 'HEAD')

    def select(self, event_name='push', event=None, expected_code=0):
        head = self.git('rev-parse', 'HEAD')
        event = event if event is not None else {'before': self.base, 'after': head}
        event_path = self.root / 'event.json'
        output = self.root / 'output.txt'
        event_path.write_text(json.dumps(event))
        output.write_text('')
        result = subprocess.run(
            ['python3', str(SCRIPT)], cwd=self.root, capture_output=True, text=True,
            env=dict(os.environ, AWS_ENV_NAME='management', GITHUB_EVENT_NAME=event_name,
                     GITHUB_EVENT_PATH=str(event_path), GITHUB_OUTPUT=str(output)),
        )
        self.assertEqual(result.returncode, expected_code, result.stderr)
        if expected_code:
            self.assertEqual(output.read_text(), '')
            return
        return json.loads(output.read_text().removeprefix('matrix='))

    def test_root_change_selects_only_affected_root(self):
        self.write('terraform/envs/management/base/main.tf')
        self.commit()
        self.assertEqual(self.select(), ['base'])

    def test_shared_change_selects_all_consumers_conservatively(self):
        self.write('terraform/modules/shared/main.tf')
        self.commit()
        self.assertEqual(self.select(), ['base', 'base_apne1'])

    def test_deleted_shared_file_is_detected(self):
        (self.root / 'terraform/modules/shared/main.tf').unlink()
        self.commit()
        self.assertEqual(self.select(), ['base', 'base_apne1'])

    def test_documentation_push_selects_nothing(self):
        self.write('docs/plan.md')
        self.write('terraform/envs/management/base/README.md')
        self.commit()
        self.assertEqual(self.select(), ['_empty'])

    def test_unrelated_root_and_workflow_select_nothing(self):
        self.write('terraform/envs/portfolio/base/main.tf')
        self.write('.github/workflows/pre-commit.yml')
        self.commit()
        self.assertEqual(self.select(), ['_empty'])

    def test_common_workflow_change_selects_all(self):
        self.write('.github/workflows/_terraform-aws-management.yml')
        self.commit()
        self.assertEqual(self.select(), ['base', 'base_apne1'])

    def test_new_branch_selects_all(self):
        self.assertEqual(self.select(event={'before': '0' * 40, 'after': self.base}),
                         ['base', 'base_apne1'])

    def test_push_includes_all_commits_in_range(self):
        self.write('terraform/envs/management/base/.terraform.lock.hcl')
        self.commit()
        self.write('docs/last-commit.md')
        self.commit()
        self.assertEqual(self.select(), ['base'])

    def test_renamed_file_marks_old_root(self):
        self.git('mv', 'terraform/envs/management/base/main.tf', 'moved.tf')
        self.commit()
        self.assertEqual(self.select(), ['base'])

    def test_renamed_file_between_roots_selects_both(self):
        self.write('terraform/envs/management/base_apne1/.gitkeep', '')
        self.base = self.commit()
        self.git('mv', 'terraform/envs/management/base/main.tf',
                 'terraform/envs/management/base_apne1/main.tf')
        self.commit()
        self.assertEqual(self.select(), ['base', 'base_apne1'])

    def test_invalid_pipeline_list_fails(self):
        self.write('.github/workflows/deploy_pipeline/management', '../outside\n')
        self.commit()
        self.select(expected_code=2)

    def test_missing_commit_fails_instead_of_skipping(self):
        self.select(event={'before': '1' * 40, 'after': self.base}, expected_code=2)

    def test_unknown_event_fails(self):
        self.select('unknown', {}, expected_code=2)

    def test_missing_event_fields_fail(self):
        self.select('pull_request', {}, expected_code=2)

    def test_manual_and_schedule_select_all(self):
        for event in ('schedule', 'workflow_dispatch'):
            with self.subTest(event=event):
                self.assertEqual(self.select(event, {}), ['base', 'base_apne1'])

    def test_pr_uses_merge_base_and_preserves_checkout(self):
        self.git('checkout', '-qb', 'feature')
        self.write('docs/feature.md')
        head = self.commit()
        self.git('checkout', '-qb', 'base-advance', self.base)
        self.write('terraform/envs/management/base/main.tf')
        advanced = self.commit()
        self.assertEqual(self.select('pull_request', {'pull_request': {
            'base': {'sha': advanced}, 'head': {'sha': head}}}), ['_empty'])
        self.assertEqual(self.git('rev-parse', 'HEAD'), advanced)

    def test_paths_with_spaces_and_root_prefix_collision(self):
        self.assertTrue(MATRIX.affects_root('terraform/envs/management/base/file name.tf',
                                          'terraform/envs/management/base'))
        self.assertFalse(MATRIX.affects_root('terraform/envs/management/base_apne1/main.tf',
                                           'terraform/envs/management/base'))

    def test_change_detector_and_shared_usecases_are_inputs(self):
        for path in ('.github/scripts/terraform_matrix.py',
                     '.github/scripts/check_for_changes_in_terraform_files.sh',
                     'terraform/usecases/example/main.tf'):
            self.assertTrue(MATRIX.affects_root(path, 'terraform/envs/management/base'))

    def test_wrapper_distinguishes_changed_unchanged_and_failure(self):
        wrapper = REPO / '.github/scripts/check_for_changes_in_terraform_files.sh'
        self.write('terraform/envs/management/base/main.tf')
        head = self.commit()
        for base, end, expected in ((self.base, head, 0), (head, head, 1), ('missing', head, 2)):
            result = subprocess.run(['bash', str(wrapper), 'terraform/envs/management/base',
                                     base, end], cwd=self.root, capture_output=True)
            self.assertEqual(result.returncode, expected, result.stderr)


class ApplyGateTest(unittest.TestCase):
    def test_apply_requires_explicit_manual_main_and_diff(self):
        # Evaluate the actual restricted expression used by all three workflows.
        for account in ('management', 'portfolio', 'sandbox'):
            workflow = (REPO / f'.github/workflows/_terraform-aws-{account}.yml').read_text()
            condition = workflow.split('- name: Terraform Apply\n        if: ', 1)[1].split('\n', 1)[0]
            for event, ref, check, status, expected in (
                ('push', 'refs/heads/main', '_false', 'has-diff', False),
                ('pull_request', 'refs/heads/main', '_false', 'has-diff', False),
                ('schedule', 'refs/heads/main', '_false', 'has-diff', False),
                ('workflow_dispatch', 'refs/heads/main', '_true', 'has-diff', False),
                ('workflow_dispatch', 'refs/heads/feature', '_false', 'has-diff', False),
                ('workflow_dispatch', 'refs/heads/main', '_false', 'no-changes', False),
                ('workflow_dispatch', 'refs/heads/main', '_false', 'has-diff', True),
            ):
                values = {'github.event_name': event, 'github.ref': ref,
                          'inputs.CHECK_DIFF': check, 'env.TF_PLAN_STATUS': status}
                # The gate consists only of equality clauses joined by &&.
                clauses = [clause.strip().split(' == ') for clause in condition.split('&&')]
                actual = all(values[key] == literal.strip("'") for key, literal in clauses)
                self.assertEqual(actual, expected, (account, event, ref, check, status))
            self.assertIn("vars.TERRAFORM_EXECUTION_ENABLED == 'true' && needs.set-matrix.outputs.matrix", workflow)
            self.assertIn(f'needs: [set-matrix, terraform-aws-{account}]', workflow)
            caller = (REPO / f'.github/workflows/terraform-aws-{account}-diff-check.yml').read_text()
            self.assertIn('CHECK_DIFF: "_true"', caller)


if __name__ == '__main__':
    unittest.main()
