"""Check the local CI-equivalent validation boundary and failure propagation."""

import os
import re
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class TerraformValidationScriptTest(unittest.TestCase):
    def test_local_and_ci_use_the_required_terraform_version(self):
        version = re.search(r'^terraform = "([^"]+)"', (REPO / 'mise.toml').read_text(), re.M)[1]
        configs = list((REPO / 'terraform/envs').glob('*/*/terraform.tf'))
        configs.append(REPO / 'tests/terraform/main.tf')
        for path in configs:
            required = re.search(r'required_version\s*=\s*"([^"]+)"', path.read_text())[1]
            self.assertEqual(required, version, str(path))
        for name in ('.github/actions/setup-terraform/action.yml',
                     '.github/workflows/terraform-graph.yml',
                     '.github/workflows/terraform-renovate.yml'):
            action = (REPO / name).read_text()
            self.assertIn('uses: jdx/mise-action@', action)
            self.assertIn('install_args: terraform', action)
            self.assertNotIn('hashicorp/setup-terraform', action)
        node = (REPO / '.github/actions/setup-node/action.yml').read_text()
        self.assertIn('install_args: node', node)
        self.assertNotIn('uses: actions/setup-node@', node)
        for legacy in ('.node-version', '.terraform-version'):
            self.assertFalse((REPO / legacy).exists())

    def run_validation(self, fail=False, directories=()):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            log = root / 'commands'
            terraform = root / 'terraform'
            terraform.write_text(
                '#!/usr/bin/env bash\n'
                'printf "%s\\n" "$*" >> "$COMMAND_LOG"\n'
                'if [[ "$FAIL_VALIDATE" == true && "$2" == validate ]]; then\n'
                '  exit 17\n'
                'fi\n')
            terraform.chmod(0o755)
            env = dict(os.environ, PATH=f'{root}:{os.environ["PATH"]}',
                       COMMAND_LOG=str(log), FAIL_VALIDATE=str(fail).lower(),
                       TF_PLUGIN_CACHE_DIR=str(root / 'plugins'))
            result = subprocess.run(
                ['bash', str(REPO / 'scripts/validate-terraform.sh'), *directories],
                cwd=root, env=env, capture_output=True, text=True, check=False)
            return result, log.read_text().splitlines() if log.exists() else []

    def test_all_roots_are_validated_without_backend_or_lockfile_writes(self):
        result, commands = self.run_validation()
        self.assertEqual(result.returncode, 0, result.stderr)
        roots = sorted((REPO / 'terraform/envs').glob('*/*/terraform.tf'))
        self.assertEqual(len(commands), len(roots) * 3)
        for index, config in enumerate(roots):
            directory = config.parent.relative_to(REPO)
            self.assertEqual(commands[index * 3:index * 3 + 3], [
                f'-chdir={directory} fmt -check -recursive -diff',
                f'-chdir={directory} init -backend=false -input=false -lockfile=readonly',
                f'-chdir={directory} validate -no-color',
            ])

    def test_single_environment_can_be_checked_quickly(self):
        directory = 'terraform/envs/sandbox/test-statement'
        result, commands = self.run_validation(directories=(directory,))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(commands), 3)
        self.assertTrue(all(line.startswith(f'-chdir={directory} ') for line in commands))

    def test_invalid_targets_fail_before_any_terraform_command(self):
        for directory in ('/tmp', 'terraform/envs/../../tests',
                          'terraform/envs/missing/environment', '-upgrade'):
            with self.subTest(directory=directory):
                result, commands = self.run_validation(directories=(
                    'terraform/envs/sandbox/test-statement', directory))
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertEqual(commands, [])

    def test_mise_forwards_target_before_terraform_is_started(self):
        result = subprocess.run(
            ['mise', 'run', 'terraform-validate', 'terraform/envs/missing/environment'],
            cwd=REPO, capture_output=True, text=True, timeout=30)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('検証対象の環境ディレクトリが不正です:', result.stderr)
        self.assertNotIn('Failed to render', result.stderr)

    def test_validation_failure_is_propagated_immediately(self):
        result, commands = self.run_validation(fail=True)
        self.assertEqual(result.returncode, 17)
        self.assertEqual(len(commands), 3)


if __name__ == '__main__':
    unittest.main()
