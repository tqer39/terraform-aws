"""Check the local CI-equivalent validation boundary and failure propagation."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class TerraformValidationScriptTest(unittest.TestCase):
    def run_validation(self, fail=False):
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
                       COMMAND_LOG=str(log), FAIL_VALIDATE=str(fail).lower())
            result = subprocess.run(
                ['bash', str(REPO / 'scripts/validate-terraform.sh')],
                cwd=root, env=env, capture_output=True, text=True, check=False)
            return result, log.read_text().splitlines()

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

    def test_validation_failure_is_propagated_immediately(self):
        result, commands = self.run_validation(fail=True)
        self.assertEqual(result.returncode, 17)
        self.assertEqual(len(commands), 3)


if __name__ == '__main__':
    unittest.main()
