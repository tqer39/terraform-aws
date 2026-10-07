"""Regression coverage for file filtering, safety checks and read-only lint."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class LefthookChecksTest(unittest.TestCase):
    def setUp(self):
        self.uv = shutil.which('uv')
        self.assertIsNotNone(self.uv, 'uv is required; run mise install')
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def check(self, hook, *files, check_only=False):
        command = [self.uv, 'run', '--locked', '--script', str(REPO / 'scripts/lint/check.py'), hook]
        if check_only:
            command.append('--check')
        return subprocess.run(command + list(files), cwd=self.root,
                              capture_output=True, text=True, timeout=60)

    def write(self, name, data):
        path = self.root / name
        path.write_bytes(data)
        return str(path)

    def test_json_and_yaml_reject_invalid_input(self):
        for hook, name, data in (('check-json', 'invalid file.json', b'{\n'),
                                 ('check-yaml', 'invalid.yaml', b'key: [\n')):
            with self.subTest(hook=hook):
                result = self.check(hook, self.write(name, data))
                self.assertNotEqual(result.returncode, 0, result.stderr)

    def test_non_json_binary_deleted_files_and_symlinks_are_skipped(self):
        binary = self.write('image.png', b'\x89PNG\x00\xff')
        text = self.write('plain.txt', b'not JSON\n')
        link = self.root / 'link.json'
        link.symlink_to(text)
        result = self.check('check-json', binary, text, str(link), 'missing.json')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        result = self.check('end-of-file-fixer', binary, check_only=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(Path(binary).read_bytes(), b'\x89PNG\x00\xff')

    def test_formatter_checks_report_errors_without_changing_files(self):
        for hook, data in (('end-of-file-fixer', b'missing newline'),
                           ('mixed-line-ending', b'windows\r\n'),
                           ('trailing-whitespace', b'trailing space \n')):
            with self.subTest(hook=hook):
                name = self.write('file with spaces.txt', data)
                result = self.check(hook, name, check_only=True)
                self.assertNotEqual(result.returncode, 0, result.stderr)
                self.assertEqual(Path(name).read_bytes(), data)
                result = self.check(hook, name)
                self.assertNotEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.check(hook, name, check_only=True).returncode, 0)

    def test_large_files_are_checked_even_outside_the_staging_area(self):
        subprocess.run(['git', 'init', '-q', str(self.root)], check=True)
        name = self.write('large.bin', b'x' * (512 * 1024 + 1))
        result = self.check('check-added-large-files', name)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('exceeds', result.stdout + result.stderr)

    def test_lefthook_selects_staged_files_and_preserves_usage_exclusion(self):
        lefthook = subprocess.check_output(['mise', 'which', 'lefthook'],
                                          cwd=REPO, text=True).strip()
        shutil.copyfile(REPO / 'lefthook.yml', self.root / 'lefthook.yml')
        shutil.copyfile(REPO / 'mise.toml', self.root / 'mise.toml')
        scripts = self.root / 'scripts/lint'
        scripts.mkdir(parents=True)
        for name in ('check.py', 'check.py.lock'):
            shutil.copyfile(REPO / 'scripts/lint' / name, scripts / name)
        subprocess.run(['git', 'init', '-q', str(self.root)], check=True)
        self.write('existing.json', b'{invalid JSON}\n')
        subprocess.run(['git', 'add', '.'], cwd=self.root, check=True)
        subprocess.run(['git', '-c', 'user.name=Test', '-c', 'user.email=test@example.com',
                        'commit', '-qm', 'fixture'], cwd=self.root, check=True)
        self.write('staged.json', b'{}\n')
        usage = self.root / 'docs/USAGE.md'
        usage.parent.mkdir()
        usage.write_bytes(b'excluded trailing space ')
        subprocess.run(['git', 'add', 'staged.json', 'docs/USAGE.md'],
                       cwd=self.root, check=True)

        def run(command, *extra):
            return subprocess.run([lefthook, 'run', 'pre-commit', '--no-auto-install',
                                   '--command', command, *extra], cwd=self.root,
                                  capture_output=True, text=True, timeout=60,
                                  env=dict(os.environ, MISE_TRUSTED_CONFIG_PATHS=str(self.root)))

        self.assertEqual(run('check-json').returncode, 0)
        self.assertNotEqual(run('check-json', '--all-files').returncode, 0)
        self.assertEqual(run('trailing-whitespace').returncode, 0)
        self.assertEqual(usage.read_bytes(), b'excluded trailing space ')
        self.write('bad file.json', b'{\n')
        subprocess.run(['git', 'add', 'bad file.json'], cwd=self.root, check=True)
        result = run('check-json')
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('bad file.json', result.stdout + result.stderr)

    def test_private_key_is_rejected(self):
        # Construct the fixture so this test file is not itself a key fixture.
        data = ('-----BEGIN ' + 'RSA PRIVATE KEY-----\n').encode()
        result = self.check('detect-private-key', self.write('key.txt', data))
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
