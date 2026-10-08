"""Exercise parsers and math rendering after security dependency overrides."""
# cspell:ignore micromark mathHtml

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
CLI = REPO / 'node_modules/markdownlint-cli/markdownlint.js'


@unittest.skipUnless(shutil.which('node') and CLI.is_file(), 'Run npm ci first')
class DependencyToolsTest(unittest.TestCase):
    def test_markdownlint_parses_yaml_and_toml_and_keeps_reporting_errors(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for extension, content in (('yaml', 'default: true\n'),
                                       ('toml', 'default = true\n')):
                with self.subTest(config=extension):
                    config = root / f'config.{extension}'
                    config.write_text(content)
                    markdown = root / 'example.md'
                    valid = '# Example\n\n$$\nx^2 + y^2 = z^2\n$$\n'
                    # Exercise the renderer that depends on the overridden KaTeX.
                    renderer = (
                        "import {micromark} from 'micromark';"
                        "import {math, mathHtml} from 'micromark-extension-math';"
                        "import {readFileSync} from 'node:fs';"
                        "process.stdout.write(micromark(readFileSync(process.argv[1], 'utf8'),"
                        "{extensions:[math()], htmlExtensions:[mathHtml()]}));")
                    markdown.write_text(valid)
                    rendered = subprocess.run(
                        [shutil.which('node'), '--input-type=module', '-e', renderer, str(markdown)],
                        cwd=REPO, capture_output=True, text=True, timeout=30)
                    self.assertEqual(rendered.returncode, 0, rendered.stderr)
                    self.assertIn('class="katex"', rendered.stdout)
                    self.assertIn('<math', rendered.stdout)
                    for text, accepted in ((valid, True), (valid + '\n### Skipped level\n', False)):
                        markdown.write_text(text)
                        result = subprocess.run(
                            [shutil.which('node'), str(CLI), '--config', str(config), str(markdown)],
                            cwd=root, capture_output=True, text=True, timeout=30)
                        self.assertEqual(result.returncode == 0, accepted,
                                         result.stdout + result.stderr)
                        if not accepted:
                            self.assertIn('MD001', result.stderr)
                        self.assertEqual(markdown.read_text(), text)


if __name__ == '__main__':
    unittest.main()
