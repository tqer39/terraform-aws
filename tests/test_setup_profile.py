"""Exercise setup coverage selection against real Git commits."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / '.github/scripts/setup_profile.py'


class SetupProfileTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.git('init', '-q')
        self.git('config', 'user.email', 'test@example.com')
        self.git('config', 'user.name', 'Test')
        self.write('setup-repository.sh', '# setup\n')
        self.base = self.commit()

    def git(self, *args):
        return subprocess.check_output(['git', *args], cwd=self.root, text=True).strip()

    def write(self, name, content='changed\n'):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    def commit(self):
        self.git('add', '.')
        self.git('commit', '-qm', 'fixture')
        return self.git('rev-parse', 'HEAD')

    def select(self, event_name='push', event=None, expected_code=0):
        event = event if event is not None else {
            'before': self.base, 'after': self.git('rev-parse', 'HEAD')}
        event_path = self.root / 'event.json'
        output = self.root / 'output.txt'
        event_path.write_text(json.dumps(event))
        output.write_text('')
        result = subprocess.run(
            [sys.executable, str(SCRIPT)], cwd=self.root, capture_output=True, text=True,
            env=dict(os.environ, GITHUB_EVENT_NAME=event_name,
                     GITHUB_EVENT_PATH=str(event_path), GITHUB_OUTPUT=str(output)),
            timeout=10)
        self.assertEqual(result.returncode, expected_code, result.stderr)
        if expected_code:
            self.assertEqual(output.read_text(), '')
            return None
        return output.read_text().removeprefix('profile=').strip()

    def test_terraform_and_documentation_changes_use_cli(self):
        self.write('terraform/envs/management/base/main.tf')
        self.write('README.md')
        self.commit()
        self.assertEqual(self.select(), 'cli')

    def test_setup_dependencies_use_full(self):
        for name in ('setup-repository.sh', 'mise.toml', 'Makefile', '.terraform-version',
                     '.github/workflows/setup-repository-test.yml',
                     '.github/scripts/setup_profile.py',
                     '.github/scripts/terraform_matrix.py',
                     'tests/test_setup_repository.py', 'tests/test_setup_profile.py',
                     'tests/test_mise_tasks.py'):
            with self.subTest(path=name):
                self.write(name)
                self.commit()
                self.assertEqual(self.select(), 'full')
                self.base = self.git('rev-parse', 'HEAD')

    def test_deleted_setup_file_uses_full(self):
        (self.root / 'setup-repository.sh').unlink()
        self.commit()
        self.assertEqual(self.select(), 'full')

    def test_renamed_setup_file_uses_full(self):
        self.git('mv', 'setup-repository.sh', 'renamed.sh')
        self.commit()
        self.assertEqual(self.select(), 'full')

    def test_pull_request_ignores_setup_changes_only_on_base_branch(self):
        self.git('checkout', '-qb', 'feature')
        self.write('README.md')
        head = self.commit()
        self.git('checkout', '-q', '-')
        self.write('setup-repository.sh')
        base = self.commit()
        self.assertEqual(self.select('pull_request', {
            'pull_request': {'base': {'sha': base}, 'head': {'sha': head}}}), 'cli')

    def test_manual_run_uses_full(self):
        self.assertEqual(self.select('workflow_dispatch', {}), 'full')

    def test_new_branch_uses_full(self):
        self.assertEqual(self.select(event={
            'before': '0' * 40, 'after': self.base}), 'full')

    def test_missing_history_does_not_silently_reduce_coverage(self):
        self.select(event={'before': 'f' * 40, 'after': self.base}, expected_code=2)


if __name__ == '__main__':
    unittest.main()
