"""Exercise setup ordering and failures without modifying host software."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class MiseTasksTest(unittest.TestCase):
    def setUp(self):
        self.mise = shutil.which('mise')
        self.assertIsNotNone(self.mise, 'mise is required to run task regression tests')
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        # Exercise task dispatch independently of installed tool versions.
        config = (REPO / 'mise.toml').read_text()
        (self.root / 'mise.toml').write_text(config[config.index('[tasks.setup]'):])
        # Keep all mise state isolated, including trust and global configuration.
        self.env = dict(os.environ)
        for key in list(self.env):
            if key.startswith('MISE_'):
                del self.env[key]
        for name in ('CONFIG', 'CACHE', 'DATA', 'STATE'):
            self.env[f'MISE_{name}_DIR'] = str(self.root / name.lower())
        global_config = self.root / 'global.toml'
        global_config.write_text('')
        self.env['MISE_GLOBAL_CONFIG_FILE'] = str(global_config)
        self.env['MISE_TRUSTED_CONFIG_PATHS'] = str(self.root)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.env['PATH'] = str(self.bin) + os.pathsep + os.environ['PATH']
        self.log = self.root / 'task.log'
        self.env['TASK_LOG'] = str(self.log)
        # Stub installers while allowing mise to execute each command normally.
        for name in ('npm', 'lefthook'):
            stub = self.bin / name
            stub.write_text('#!/bin/sh\n'
                            f'printf "%s\\n" "$PWD {name} $*" >> "$TASK_LOG"\n'
                            f'exit "${{{name.upper()}_EXIT_CODE:-0}}"\n')
            stub.chmod(0o755)

    def run_task(self, task, cwd=None, npm_exit=0, lefthook_exit=0):
        return subprocess.run(
            [self.mise, 'run', task], cwd=cwd or self.root,
            env=dict(self.env, NPM_EXIT_CODE=str(npm_exit),
                     LEFTHOOK_EXIT_CODE=str(lefthook_exit)),
            capture_output=True, text=True, timeout=30,
        )

    def test_setup_runs_from_repository_root(self):
        nested = self.root / 'docs'
        nested.mkdir()
        for cwd in (self.root, nested):
            with self.subTest(cwd=cwd):
                self.log.unlink(missing_ok=True)
                result = self.run_task('setup', cwd=cwd)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.log.read_text().splitlines(), [
                    f'{self.root.resolve()} npm ci --ignore-scripts',
                    f'{self.root.resolve()} lefthook install',
                ])

    def test_dependency_failure_prevents_hook_installation(self):
        result = self.run_task('setup', npm_exit=23)
        self.assertEqual(result.returncode, 23, result.stderr)
        self.assertEqual(self.log.read_text().splitlines(), [
            f'{self.root.resolve()} npm ci --ignore-scripts',
        ])

    def test_hook_failure_is_reported(self):
        result = self.run_task('setup', lefthook_exit=23)
        self.assertEqual(result.returncode, 23, result.stderr)
        self.assertEqual(len(self.log.read_text().splitlines()), 2)

    def test_lint_dispatch_and_failure(self):
        for code in (0, 23):
            with self.subTest(code=code):
                self.log.unlink(missing_ok=True)
                result = self.run_task('lint', lefthook_exit=code)
                self.assertEqual(result.returncode, code, result.stderr)
                self.assertEqual(self.log.read_text().splitlines(), [
                    f'{self.root.resolve()} lefthook run pre-commit '
                    '--all-files --no-auto-install --fail-on-changes',
                ])


if __name__ == '__main__':
    unittest.main()
