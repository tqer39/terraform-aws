"""正本だけのツール変更を拒否し、計画の適用後に整合することを確認する。"""

import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class StandardsToolUpdateTest(unittest.TestCase):
    def test_canonical_tool_update_requires_generated_files_and_lock(self):
        cli = shutil.which('dev-standards')
        self.assertIsNotNone(cli, 'mise run bootstrap を先に実行してください')
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve() / 'project'
            root.mkdir()
            shutil.copytree(REPO / '.standards', root / '.standards',
                            ignore=shutil.ignore_patterns('cache', 'plans'))
            for name in ('.editorconfig', '.gitattributes', '.gitignore', 'mise.toml',
                         'AGENTS.md', 'package.json', 'package-lock.json',
                         '.rulesync/rules/dev-standards.md', 'docs/decisions/0001-language.md'):
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(REPO / name, target)
            subprocess.run(['git', '-C', str(root), 'init', '--quiet'], check=True)

            def invoke(*args):
                return subprocess.run([cli, *args, '--repo', str(root)],
                                      capture_output=True, text=True, timeout=30)

            self.assertEqual(invoke('check').returncode, 0)
            original = (root / 'mise.toml').read_bytes()
            lock = (root / '.standards/lock.json').read_bytes()
            source = root / '.standards/mise.project.toml'
            content = source.read_text()
            current = re.search(r'^go = "([^"]+)"', content, re.M)[1]
            changed = '1.27.3' if current != '1.27.3' else '1.27.4'
            source.write_text(content.replace(f'go = "{current}"', f'go = "{changed}"', 1))

            rejected = invoke('check')
            self.assertNotEqual(rejected.returncode, 0)
            self.assertIn('implicit updates are forbidden', rejected.stderr)
            plan = Path(temporary) / 'update.json'
            planned = invoke('plan', '--upgrade', '--output', str(plan))
            self.assertEqual(planned.returncode, 1, planned.stdout + planned.stderr)
            self.assertEqual(json.loads(plan.read_text())['conflicts'], [])
            self.assertEqual((root / 'mise.toml').read_bytes(), original)
            self.assertEqual((root / '.standards/lock.json').read_bytes(), lock)

            applied = invoke('apply', '--plan', str(plan))
            self.assertEqual(applied.returncode, 0, applied.stdout + applied.stderr)
            checked = invoke('check')
            self.assertEqual(checked.returncode, 0, checked.stdout + checked.stderr)
            self.assertIn(f'go = "{changed}"', (root / 'mise.toml').read_text())
            self.assertNotEqual((root / '.standards/lock.json').read_bytes(), lock)
            self.assertEqual(invoke('plan').returncode, 0)


if __name__ == '__main__':
    unittest.main()
