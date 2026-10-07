"""Exercise rule and skill generation in an isolated repository."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
CLI = REPO / 'node_modules/rulesync/dist/cli/index.js'
RULE_OUTPUTS = (
    'AGENTS.md', 'CLAUDE.md', '.github/copilot-instructions.md',
    '.cursor/rules/overview.mdc',
)
SKILL_OUTPUTS = tuple(
    f'{directory}/skills/update-gitignore/SKILL.md'
    for directory in ('.agents', '.claude', '.github', '.cursor')
)


@unittest.skipUnless(shutil.which('node') and CLI.is_file(),
                     'Run npm ci to enable rulesync integration tests')
class RulesyncTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        shutil.copyfile(REPO / 'rulesync.jsonc', self.root / 'rulesync.jsonc')
        shutil.copytree(REPO / 'docs/rules', self.root / 'docs/rules')
        shutil.copytree(REPO / '.rulesync/skills', self.root / '.rulesync/skills')

    def generate(self, check=False):
        command = [shutil.which('node'), str(CLI), 'generate']
        if check:
            command.append('--check')
        return subprocess.run(command, cwd=self.root, capture_output=True,
                              text=True, timeout=30)

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_origin_changes_reach_every_tool_and_generation_is_stable(self):
        origin = self.root / 'docs/rules/overview.md'
        marker = 'Regression fixture: use the updated canonical rule.'
        origin.write_text(origin.read_text() + '\n' + marker + '\n')
        self.assert_success(self.generate())
        for relative in RULE_OUTPUTS:
            with self.subTest(output=relative):
                self.assertIn(marker, (self.root / relative).read_text())
        before = {path: (self.root / path).read_bytes()
                  for path in RULE_OUTPUTS + SKILL_OUTPUTS}
        self.assert_success(self.generate(check=True))
        self.assert_success(self.generate())
        self.assertEqual(before, {path: (self.root / path).read_bytes()
                                  for path in before})

    def test_skill_origin_changes_are_embedded_in_every_tool(self):
        origin = self.root / '.rulesync/skills/update-gitignore/SKILL.md'
        marker = 'Regression fixture: updated skill procedure.'
        origin.write_text(origin.read_text() + '\n' + marker + '\n')
        self.assert_success(self.generate())
        body = origin.read_text().split('---', 2)[2].strip()
        for relative in SKILL_OUTPUTS:
            with self.subTest(skill=relative):
                generated = (self.root / relative).read_text()
                self.assertEqual(generated.split('---', 2)[2].strip(), body)
                self.assertNotIn('docs/rules/', generated)
        for relative in RULE_OUTPUTS:
            self.assertNotIn(marker, (self.root / relative).read_text())
        self.assert_success(self.generate(check=True))

    def test_check_detects_origin_and_generated_skill_drift(self):
        self.assert_success(self.generate())
        origin = self.root / 'docs/rules/overview.md'
        origin.write_text(origin.read_text() + '\nChanged canonical rule.\n')
        self.assertNotEqual(self.generate(check=True).returncode, 0)
        self.assert_success(self.generate())
        skill = self.root / SKILL_OUTPUTS[0]
        skill.write_text(skill.read_text() + '\nUnexpected local edit.\n')
        self.assertNotEqual(self.generate(check=True).returncode, 0)
        self.assert_success(self.generate())
        self.assert_success(self.generate(check=True))


if __name__ == '__main__':
    unittest.main()
