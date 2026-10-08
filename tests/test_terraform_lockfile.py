"""Exercise CI initialization with an offline provider mirror and no backend."""

import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class TerraformLockfileTest(unittest.TestCase):
    def setUp(self):
        self.terraform = shutil.which('terraform')
        self.assertIsNotNone(self.terraform, 'terraform is required for these tests')
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = {key: value for key, value in os.environ.items()
                    if not key.startswith('TF_')}
        config = self.root / 'terraform.rc'
        config.write_text('disable_checkpoint = true\n')
        self.env['TF_CLI_CONFIG_FILE'] = str(config)
        result = subprocess.run([self.terraform, 'version', '-json'],
                                env=self.env, capture_output=True, text=True, check=True)
        platform = json.loads(result.stdout)['platform']
        self.mirror = self.root / 'mirror'
        for version in ('1.0.0', '2.0.0'):
            package = self.mirror / 'example.com/test/fixture' / version / platform
            package.mkdir(parents=True)
            # Init hashes and installs packages without executing the provider.
            (package / f'terraform-provider-fixture_v{version}').write_text(version)
        self.write_requirement('= 1.0.0')
        result = self.init(['init', '-input=false'])
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.lock = self.root / '.terraform.lock.hcl'
        self.original = self.lock.read_bytes()
        action = (REPO / '.github/actions/setup-terraform/action.yml').read_text()
        command = re.search(r'^\s+run: (terraform init[^\n]*)$', action, re.MULTILINE)
        self.assertIsNotNone(command)
        self.ci_command = command.group(1)
        self.env['TF_BACKEND'] = 'false'

    def write_requirement(self, constraint):
        (self.root / 'main.tf').write_text(
            'terraform {\n  required_providers {\n    fixture = {\n'
            '      source = "example.com/test/fixture"\n'
            f'      version = "{constraint}"\n'
            '    }\n  }\n}\n')

    def init(self, args):
        options = ['-backend=false', '-no-color', f'-plugin-dir={self.mirror}']
        if isinstance(args, str):
            # Execute the real action command so its quoted env inputs are expanded.
            command = ['bash', '-e', '-c',
                       'exec ' + shlex.quote(self.terraform) + args.removeprefix('terraform')
                       + ' ' + shlex.join(options)]
        else:
            command = [self.terraform, *args, *options]
        return subprocess.run(
            command,
            cwd=self.root, env=self.env, capture_output=True, text=True, timeout=30)

    def test_ci_keeps_locked_version_when_newer_version_is_available(self):
        self.write_requirement('>= 1.0.0')
        result = self.init(self.ci_command)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('fixture v1.0.0', result.stdout)
        self.assertEqual(self.lock.read_bytes(), self.original)

    def test_ci_rejects_missing_lockfile_without_creating_one(self):
        self.lock.unlink()
        result = self.init(self.ci_command)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('read-only', result.stderr)
        self.assertFalse(self.lock.exists())

    def test_ci_rejects_incompatible_version_without_updating_lockfile(self):
        self.write_requirement('= 2.0.0')
        result = self.init(self.ci_command)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.lock.read_bytes(), self.original)

    def test_ci_rejects_changed_package_checksums(self):
        package = next(self.mirror.rglob('terraform-provider-fixture_v1.0.0'))
        package.write_text('changed package')
        result = self.init(self.ci_command)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('checksums', result.stderr)
        self.assertEqual(self.lock.read_bytes(), self.original)


class TerraformRootLockfileTest(unittest.TestCase):
    def test_pinned_provider_versions_and_constraints_match_lock_files(self):
        roots = sorted((REPO / 'terraform/envs').glob('*/*/terraform.tf'))
        self.assertTrue(roots)
        for config in roots:
            lockfile = (config.parent / '.terraform.lock.hcl').read_text()
            requirements = re.findall(
                r'source\s*=\s*"([^"]+)"\s+version\s*=\s*"([^"]+)"',
                config.read_text())
            for source, version in requirements:
                if not re.fullmatch(r'\d+\.\d+\.\d+', version):
                    continue
                with self.subTest(root=str(config.parent.relative_to(REPO)),
                                  provider=source):
                    address = source if source.count('/') == 2 else f'registry.terraform.io/{source}'
                    block = re.search(
                        rf'provider "{re.escape(address)}" \{{([^}}]+)\}}',
                        lockfile)
                    self.assertIsNotNone(block)
                    locked = re.search(r'\bversion\s*=\s*"([^"]+)"', block.group(1))
                    self.assertIsNotNone(locked)
                    self.assertEqual(locked.group(1), version)
                    constraints = re.search(
                        r'\bconstraints\s*=\s*"([^"]+)"', block.group(1))
                    self.assertIsNotNone(constraints, 'Pinned provider constraint is missing')
                    self.assertIn(version, [
                        item.strip().removeprefix('= ').strip()
                        for item in constraints.group(1).split(',')
                    ])

    def test_every_environment_has_a_lockfile(self):
        roots = sorted((REPO / 'terraform/envs').glob('*/*/terraform.tf'))
        self.assertTrue(roots)
        for config in roots:
            with self.subTest(root=str(config.parent.relative_to(REPO))):
                self.assertTrue((config.parent / '.terraform.lock.hcl').is_file())


if __name__ == '__main__':
    unittest.main()
