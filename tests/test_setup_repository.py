"""Exercise setup with fake installers so host software is never changed."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class SetupRepositoryTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.log = self.root / 'commands.log'
        self.github_path = self.root / 'github-path'
        self.env = dict(os.environ, HOME=str(self.root),
                        PATH=str(self.bin) + os.pathsep + '/usr/bin:/bin',
                        SETUP_TEST_ROOT=str(self.root),
                        SETUP_TEST_LOG=str(self.log),
                        SETUP_PROFILE='full',
                        GITHUB_PATH=str(self.github_path))
        (self.root / '.anyenv/envs/tfenv').mkdir(parents=True)
        for name in ('git', 'tfenv', 'rancher-desktop',
                     'session-manager-plugin', 'aws-vault'):
            self.stub(name)
        self.stub('brew', 'if [ "$1" = --prefix ]; then\n'
                  '  printf "%s\\n" "$SETUP_TEST_ROOT/brew"\nfi\n')
        self.stub('anyenv', 'if [ "$1" = root ]; then\n'
                  '  printf "%s\\n" "$SETUP_TEST_ROOT/.anyenv"\nfi\n')
        # Reject unexpected downloads and privileged operations.
        for name in ('curl', 'sudo'):
            self.stub(name, 'exit 97\n')

    def stub(self, name, body=''):
        path = self.bin / name
        path.write_text('#!/bin/bash\n'
                        f'printf "{name} %s\\n" "$*" >> "$SETUP_TEST_LOG"\n'
                        + body)
        path.chmod(0o755)

    def run_setup(self, *args):
        return subprocess.run(
            ['/bin/bash', str(REPO / 'setup-repository.sh'), *args],
            cwd=self.root, env=self.env, capture_output=True, text=True, timeout=10)

    def hide_homebrew(self):
        (self.bin / 'brew').rename(self.root / 'brew-fixture')
        # Hide real host prefixes from this isolated shell only.
        bash_env = self.root / 'bash-env'
        bash_env.write_text('function [ {\n'
                            '  if [[ "$1" = -x && "$2" = */bin/brew ]]; then\n'
                            '    return 1\n'
                            '  fi\n'
                            '  builtin [ "$@"\n}\n')
        self.env['BASH_ENV'] = str(bash_env)
        self.stub('uname', 'echo Linux\n')

    def test_missing_homebrew_is_installed_before_setting_path(self):
        self.hide_homebrew()
        installer = self.root / 'installer'
        installer.write_text('cp "$SETUP_TEST_ROOT/brew-fixture" '
                             '"$SETUP_TEST_ROOT/bin/brew"\n')
        self.stub('curl', 'cat "$SETUP_TEST_ROOT/installer"\n')
        result = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Homebrew/install', self.log.read_text())
        self.assertEqual(self.github_path.read_text().splitlines(),
                         [str(self.root / 'brew/bin'), str(self.root / 'brew/sbin')])

    def test_homebrew_download_failure_stops_setup(self):
        self.hide_homebrew()
        result = self.run_setup()
        self.assertEqual(result.returncode, 1)
        self.assertNotIn('anyenv ', self.log.read_text())
        self.assertFalse(self.github_path.exists())

    def test_existing_homebrew_is_reused_on_both_platforms(self):
        for platform in ('Darwin', 'Linux'):
            with self.subTest(platform=platform):
                self.stub('uname', f'printf "%s\\n" "{platform}"\n')
                result = self.run_setup()
                self.assertEqual(result.returncode, 0, result.stderr)
                commands = self.log.read_text().splitlines()
                self.assertFalse(any(line.startswith('curl ') for line in commands))
                self.assertFalse(any(line.startswith('sudo ') for line in commands))
                self.assertEqual(self.github_path.read_text().splitlines(),
                                 [str(self.root / 'brew/bin'),
                                  str(self.root / 'brew/sbin')])
                self.log.unlink()
                self.github_path.unlink()

    def test_cli_profile_skips_desktop_but_installs_cli_tools(self):
        for platform in ('Darwin', 'Linux'):
            with self.subTest(platform=platform):
                self.stub('uname', f'printf "%s\\n" "{platform}"\n')
                for name in ('rancher-desktop', 'session-manager-plugin', 'aws-vault'):
                    (self.bin / name).unlink(missing_ok=True)
                self.stub('curl')
                self.stub('sudo')
                self.env['SETUP_PROFILE'] = 'cli'
                result = self.run_setup()
                self.assertEqual(result.returncode, 0, result.stderr)
                commands = self.log.read_text()
                self.assertNotIn('rancher', commands)
                self.assertIn('session-manager-plugin', commands)
                self.assertIn('aws-vault', commands)
                self.log.unlink()

    def test_default_profile_keeps_desktop_installation(self):
        self.env.pop('SETUP_PROFILE')
        (self.bin / 'rancher-desktop').unlink()
        self.stub('curl')
        self.stub('sudo')
        for platform, installer in (('Darwin', 'brew install --cask rancher'),
                                    ('Linux', 'sudo apt-get install -y rancher-desktop')):
            with self.subTest(platform=platform):
                self.stub('uname', f'printf "%s\\n" "{platform}"\n')
                result = self.run_setup()
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(installer, self.log.read_text())
                self.log.unlink()

    def test_invalid_profile_fails_before_any_installation(self):
        self.env['SETUP_PROFILE'] = 'unknown'
        result = self.run_setup()
        self.assertEqual(result.returncode, 2)
        self.assertFalse(self.log.exists())


if __name__ == '__main__':
    unittest.main()
