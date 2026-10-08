"""Verify graph generation stays read-only and propagates failures."""

import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import textwrap
import unittest

REPO = Path(__file__).resolve().parents[1]
WORKFLOW = REPO / '.github/workflows/terraform-graph.yml'


class TerraformGraphTest(unittest.TestCase):
    def test_matrix_covers_all_roots_and_has_unique_artifact_names(self):
        text = WORKFLOW.read_text()
        code = textwrap.dedent(text.split("python3 - <<'PY'\n", 1)[1].split('\n          PY', 1)[0])
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'output'
            for environment in ('management', 'portfolio', 'sandbox', '../../outside'):
                output.write_text('')
                result = subprocess.run(
                    ['python3', '-c', code], cwd=REPO, capture_output=True, text=True,
                    env=dict(os.environ, TF_ENVIRONMENT=environment, GITHUB_OUTPUT=str(output)))
                if environment == '../../outside':
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual(output.read_text(), '')
                    continue
                self.assertEqual(result.returncode, 0, result.stderr)
                matrix = json.loads(output.read_text().removeprefix('matrix='))['include']
                roots = sorted(str(path.parent) for path in
                               (REPO / 'terraform/envs' / environment).glob('*/terraform.tf'))
                self.assertEqual([item['directory'] for item in matrix],
                                 [str(Path(path).relative_to(REPO)) for path in roots])
                artifacts = [item['artifact'] for item in matrix]
                self.assertEqual(len(set(artifacts)), len(roots))
                self.assertTrue(all('/' not in name for name in artifacts))

    def test_manual_workflow_has_no_deployment_or_aws_access(self):
        text = WORKFLOW.read_text()
        triggers = text.split('on:\n', 1)[1].split('\npermissions:', 1)[0]
        self.assertEqual(re.findall(r'^  (\w+):', triggers, re.M), ['workflow_dispatch'])
        for forbidden in ('id-token:', 'secrets.', 'aws-credential', 'terraform-plan',
                          'terraform-apply', 'contents: write', 'deployments:'):
            self.assertNotIn(forbidden, text)

    def run_graph(self, failure=''):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            log = root / 'commands.jsonl'
            for name in ('terraform', 'dot'):
                stub = root / name
                stub.write_text(
                    '#!/usr/bin/env python3\n'
                    'import json, os, pathlib, sys\n'
                    'name = pathlib.Path(sys.argv[0]).name\n'
                    'args = sys.argv[1:]\n'
                    'with open(os.environ["COMMAND_LOG"], "a") as log:\n'
                    '    log.write(json.dumps([name, args, os.environ["TF_DATA_DIR"]]) + "\\n")\n'
                    'operation = args[1] if name == "terraform" else "dot"\n'
                    'if name == "terraform":\n'
                    '    config = pathlib.Path(args[0].removeprefix("-chdir="))\n'
                    '    assert "backend \\"local\\"" in (config / "graph_backend_override.tf").read_text()\n'
                    '    assert not (config / "terraform.tfstate").exists()\n'
                    'if operation == os.environ["FAIL_OPERATION"]:\n'
                    '    sys.exit(17)\n'
                    'if operation == "graph":\n'
                    '    print("digraph { a -> b }")\n'
                    'if name == "dot":\n'
                    '    pathlib.Path(args[args.index("-o") + 1]).write_text("<svg/>")\n')
                stub.chmod(0o755)
            # Inputs must be passed as one argument, without shell evaluation.
            repo = root / 'repo'
            script = repo / 'scripts/terraform-graph.py'
            script.parent.mkdir(parents=True)
            shutil.copy2(REPO / 'scripts/terraform-graph.py', script)
            terraform_root = repo / 'terraform/envs/portfolio/root with spaces $(touch INJECTED)'
            terraform_root.mkdir(parents=True)
            (terraform_root / 'terraform.tf').write_text('terraform { backend "s3" {} }\n')
            (terraform_root / 'terraform.tfstate').write_text('original state')
            (terraform_root / '.terraform.lock.hcl').write_text('original lockfile')
            output = root / 'output with spaces'
            inherited_data = root / 'existing-backend'
            inherited_data.mkdir()
            env = dict(os.environ, PATH=f'{root}:{os.environ["PATH"]}',
                       COMMAND_LOG=str(log), FAIL_OPERATION=failure,
                       TF_DATA_DIR=str(inherited_data))
            result = subprocess.run(
                [sys.executable, str(script), str(terraform_root), str(output)],
                cwd=root, env=env, capture_output=True, text=True)
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            self.assertFalse((root / 'INJECTED').exists())
            self.assertTrue(inherited_data.exists())
            self.assertEqual((terraform_root / 'terraform.tfstate').read_text(), 'original state')
            self.assertEqual((terraform_root / '.terraform.lock.hcl').read_text(), 'original lockfile')
            self.assertFalse((terraform_root / 'graph_backend_override.tf').exists())
            self.assertNotEqual(calls[0][2], str(inherited_data))
            self.assertFalse(Path(calls[0][2]).exists(), 'Temporary init data must be cleaned up')
            files = sorted(path.name for path in output.iterdir()) if output.exists() else []
            return result, calls, files, calls[0][1][0]

    def test_generates_both_files_without_reading_state_or_updating_lockfile(self):
        result, calls, files, root = self.run_graph()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(files, ['dependency-graph.dot', 'dependency-graph.svg'])
        self.assertEqual([call[1] for call in calls[:3]], [
            [root, 'init', '-backend=true', '-input=false', '-lockfile=readonly'],
            [root, 'validate', '-no-color'],
            [root, 'graph'],
        ])
        self.assertEqual(calls[3][0], 'dot')

    def test_failures_do_not_publish_partial_graphs(self):
        for failure, count in (('init', 1), ('validate', 2), ('graph', 3), ('dot', 4)):
            with self.subTest(failure=failure):
                result, calls, files, _ = self.run_graph(failure)
                self.assertEqual(result.returncode, 17)
                self.assertEqual(len(calls), count)
                self.assertEqual(files, [])

    def test_real_terraform_graph_does_not_require_the_original_s3_backend(self):
        terraform_bin = subprocess.check_output(
            ['mise', 'where', 'terraform'], cwd=REPO, text=True).strip()
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory)
            script = repo / 'scripts/terraform-graph.py'
            script.parent.mkdir()
            shutil.copy2(REPO / 'scripts/terraform-graph.py', script)
            root = repo / 'terraform/envs/portfolio/example'
            root.mkdir(parents=True)
            (root / 'terraform.tf').write_text(
                'terraform {\n  required_version = "' +
                (REPO / '.terraform-version').read_text().strip() +
                '"\n  backend "s3" {}\n}\n'
                'resource "terraform_data" "first" { input = "example" }\n'
                'resource "terraform_data" "second" { input = terraform_data.first.output }\n')
            # Invalid state would fail if accidentally copied or loaded.
            (root / 'terraform.tfstate').write_text('do not read the original state')
            (root / '.terraform').mkdir()
            (root / '.terraform/terraform.tfstate').write_text('do not read the original backend')
            dot = repo / 'dot'
            dot.write_text('#!/usr/bin/env python3\nimport pathlib, sys\n'
                           'pathlib.Path(sys.argv[-1]).write_text("<svg/>")\n')
            dot.chmod(0o755)
            output = repo / 'output'
            result = subprocess.run(
                [sys.executable, str(script), str(root), str(output)], cwd=repo,
                env=dict(os.environ, PATH=terraform_bin + os.pathsep + str(repo)
                         + os.pathsep + os.environ['PATH']), capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            graph = (output / 'dependency-graph.dot').read_text()
            self.assertIn('terraform_data.first', graph)
            self.assertIn('terraform_data.second', graph)
            self.assertIn('->', graph)
            self.assertEqual((root / 'terraform.tfstate').read_text(),
                             'do not read the original state')


if __name__ == '__main__':
    unittest.main()
