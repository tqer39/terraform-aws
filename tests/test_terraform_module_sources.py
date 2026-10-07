"""Check local module dependencies without backend or provider access."""

from pathlib import Path
import re
import unittest


REPO = Path(__file__).resolve().parents[1]


class TerraformModuleSourcesTest(unittest.TestCase):
    def test_local_module_sources_resolve_to_terraform_modules(self):
        modules = REPO / 'terraform/modules'
        sources = 0
        for directory in ('envs', 'modules'):
            module_tree = REPO / 'terraform' / directory
            self.assertTrue(module_tree.is_dir(), str(module_tree))
            for path in sorted(module_tree.rglob('*.tf')):
                # Only active source attributes, excluding commented examples.
                for source in re.findall(r'^\s*source\s*=\s*"(\.{1,2}/[^"]+)"',
                                         path.read_text(), re.MULTILINE):
                    sources += 1
                    with self.subTest(path=str(path.relative_to(REPO)), source=source):
                        target = (path.parent / source).resolve()
                        self.assertTrue(target.is_relative_to(modules), str(target))
                        self.assertTrue(any(target.glob('*.tf')),
                                        f'Missing Terraform module: {target}')
        self.assertGreater(sources, 0)


if __name__ == '__main__':
    unittest.main()
