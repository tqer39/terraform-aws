"""Check task dispatch without installing or updating host software."""

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
        (self.root / 'mise.toml').write_text(config[config.index('[tasks.install]'):])
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
        # Intercept only the script interpreter, so real installers cannot run.
        bash = self.bin / 'bash'
        bash.write_text('#!/bin/sh\nprintf "%s\\n" "$PWD" "$@" > "$TASK_LOG"\n'
                        'exit "${TASK_EXIT_CODE:-0}"\n')
        bash.chmod(0o755)
        shutil.copyfile(bash, self.bin / 'lefthook')
        (self.bin / 'lefthook').chmod(0o755)
        self.log = self.root / 'task.log'
        self.env['TASK_LOG'] = str(self.log)

    def run_task(self, task, cwd=None, exit_code=0):
        return subprocess.run(
            [self.mise, 'run', task], cwd=cwd or self.root,
            env=dict(self.env, TASK_EXIT_CODE=str(exit_code)),
            capture_output=True, text=True, timeout=30,
        )

    def test_install_and_update_dispatch_from_repository_root(self):
        nested = self.root / 'docs'
        nested.mkdir()
        for task, script in (('install', 'setup-repository.sh'),
                             ('update', 'update-repository.sh')):
            for cwd in (self.root, nested):
                with self.subTest(task=task, cwd=cwd):
                    result = self.run_task(task, cwd=cwd)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(self.log.read_text().splitlines(),
                                     [str(self.root.resolve()), script])

    def test_lint_dispatch_and_failure(self):
        for code in (0, 23):
            with self.subTest(code=code):
                result = self.run_task('lint', exit_code=code)
                self.assertEqual(result.returncode, code, result.stderr)
                self.assertEqual(self.log.read_text().splitlines(),
                                 [str(self.root.resolve()), 'run', 'pre-commit',
                                  '--all-files', '--no-auto-install', '--fail-on-changes'])

    def test_script_failure_is_reported(self):
        for task in ('install', 'update'):
            with self.subTest(task=task):
                result = self.run_task(task, exit_code=23)
                self.assertEqual(result.returncode, 23, result.stderr)


if __name__ == '__main__':
    unittest.main()
