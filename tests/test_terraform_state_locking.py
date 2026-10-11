"""Prevent environments from silently losing protection against concurrent writes."""

from pathlib import Path
import re
import unittest


REPO = Path(__file__).resolve().parents[1]


class TerraformStateLockingTest(unittest.TestCase):
    def test_every_s3_backend_enables_state_locking(self):
        configs = sorted((REPO / 'terraform/envs').glob('*/*/terraform.tf'))
        self.assertTrue(configs)
        for config in configs:
            with self.subTest(environment=str(config.parent.relative_to(REPO))):
                backends = re.findall(
                    r'^\s*backend\s+"s3"\s*\{([^}]+)\}',
                    config.read_text(), re.MULTILINE)
                self.assertTrue(backends, 'Environment must declare its S3 backend')
                for backend in backends:
                    settings = re.findall(
                        r'^\s*use_lockfile\s*=\s*(true|false)\s*(?:(?://|#)[^\n]*)?$',
                        backend, re.MULTILINE)
                    self.assertEqual(settings, ['true'],
                                     'S3 state locking must be explicitly enabled')


if __name__ == '__main__':
    unittest.main()
