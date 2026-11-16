"""実認証の混入、任意の本番ルート実行、失敗時のコンテナ残留を防ぐ。"""

import importlib.util
import http.client
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('emulator', REPO / 'scripts/test-aws-emulator.py')
emulator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(emulator)


class AwsEmulatorTest(unittest.TestCase):
    def test_real_credentials_endpoints_and_terraform_arguments_are_replaced(self):
        with tempfile.TemporaryDirectory() as temp:
            inherited = dict(os.environ, AWS_ACCESS_KEY_ID='real-key',
                             AWS_PROFILE='production', AWS_ENDPOINT_URL_S3='https://example.com',
                             AWS_WEB_IDENTITY_TOKEN_FILE='/real/token',
                             TF_CLI_ARGS_test='-var-file=/real/inputs', TF_VAR_endpoint='https://example.com',
                             TF_DATA_DIR='/real/state', TF_LOG='TRACE')
            env = emulator.terraform_environment(Path(temp), 9297, inherited)
            for key in ('AWS_ACCESS_KEY_ID', 'AWS_PROFILE', 'AWS_ENDPOINT_URL_S3',
                        'AWS_WEB_IDENTITY_TOKEN_FILE', 'TF_CLI_ARGS_test', 'TF_DATA_DIR', 'TF_LOG'):
                self.assertNotIn(key, env)
            self.assertEqual(env['TF_VAR_endpoint'], 'https://127.0.0.1:9297')
            self.assertEqual(env['AWS_SHARED_CREDENTIALS_FILE'],
                             str(Path(temp) / 'home/.aws/emulator/9297/emulator_credentials'))
            self.assertEqual(Path(env['AWS_CONFIG_FILE']).read_text(), '')
            self.assertEqual(Path(env['TF_CLI_CONFIG_FILE']).read_text(), 'disable_checkpoint = true\n')

    def test_failed_terraform_test_still_removes_only_its_container(self):
        calls = []

        def run(command, **kwargs):
            calls.append((command, kwargs))
            if command[:2] == ['docker', 'info']:
                return subprocess.CompletedProcess(command, 0, stdout='aarch64\n')
            if command[0] == 'terraform' and command[2] == 'test':
                raise subprocess.CalledProcessError(17, command)
            return subprocess.CompletedProcess(command, 0)

        with patch.object(emulator, 'run', side_effect=run), \
                patch.object(emulator.shutil, 'which', return_value='/stub'), \
                patch.object(emulator, 'wait_ready'), \
                patch.object(emulator.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)):
            with self.assertRaises(subprocess.CalledProcessError):
                emulator.main()
        start = next(command for command, _ in calls if command[:2] == ['docker', 'run'])
        name = start[start.index('--name') + 1]
        self.assertTrue(name.startswith('terraform-aws-emulator-'))
        self.assertEqual(calls[-1][0], ['docker', 'rm', '--force', name])
        self.assertIn('127.0.0.1:', start[start.index('-p') + 1])
        commands = [command for command, _ in calls if command[0] == 'terraform']
        self.assertEqual([command[2] for command in commands], ['init', 'validate', 'test'])
        self.assertTrue(all('/.standards/cache/aws-emulator/run-' in command[1] for command in commands))
        self.assertIn('-lockfile=readonly', commands[0])
        self.assertIn('-backend=false', commands[0])

    def test_health_failure_prevents_terraform_and_cleans_up(self):
        with patch.object(emulator, 'run') as run, \
                patch.object(emulator.shutil, 'which', return_value='/stub'), \
                patch.object(emulator, 'wait_ready', side_effect=RuntimeError('not ready')), \
                patch.object(emulator.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)):
            run.return_value.stdout = 'x86_64\n'
            run.return_value.returncode = 0
            with self.assertRaisesRegex(RuntimeError, 'not ready'):
                emulator.main()
        commands = [call.args[0] for call in run.call_args_list]
        self.assertFalse(any(command[0] == 'terraform' for command in commands))
        self.assertEqual(commands[-1][:3], ['docker', 'rm', '--force'])

    def test_package_for_each_architecture_is_selected_before_build(self):
        packages = json.loads((emulator.FIXTURE / 'packages.json').read_text())
        for architecture in ('aarch64', 'x86_64'):
            with self.subTest(architecture=architecture), \
                    patch.object(emulator.shutil, 'which', return_value='/stub'), \
                    patch.object(emulator, 'run') as run, \
                    patch.object(emulator, 'wait_ready', side_effect=RuntimeError('not ready')), \
                    patch.object(emulator.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1)):
                run.return_value.stdout = architecture + '\n'
                run.return_value.returncode = 0
                with self.assertRaisesRegex(RuntimeError, 'not ready'):
                    emulator.main()
                build = next(call.args[0] for call in run.call_args_list
                             if call.args[0][:2] == ['docker', 'build'])
                self.assertIn(f'PACKAGE_ARCH={architecture}', build)
                self.assertIn(f'PACKAGE_SHA256={packages["sha256"][architecture]}', build)

    def test_unsupported_architecture_does_not_start_a_container(self):
        with patch.object(emulator.shutil, 'which', return_value='/stub'), \
                patch.object(emulator, 'run') as run:
            run.return_value.stdout = 'unsupported\n'
            with self.assertRaisesRegex(RuntimeError, '未対応'):
                emulator.main()
        self.assertEqual(run.call_count, 1)

    def test_health_wait_retries_an_incomplete_http_response_then_times_out(self):
        with patch.object(emulator, 'run') as run, \
                patch.object(emulator.Path, 'exists', return_value=True), \
                patch.object(emulator.ssl, 'create_default_context'), \
                patch.object(emulator.urllib.request, 'build_opener') as opener, \
                patch.object(emulator.time, 'monotonic', side_effect=[0, 0, 2]), \
                patch.object(emulator.time, 'sleep') as sleep:
            run.return_value.stdout = 'true\n'
            opener.return_value.open.side_effect = http.client.IncompleteRead(b'')
            with self.assertRaisesRegex(RuntimeError, '準備'):
                emulator.wait_ready(Path('/unused'), 9297, 'fixture', timeout=1)
            sleep.assert_called_once_with(1)

    def test_health_wait_rejects_a_stopped_container(self):
        with patch.object(emulator, 'run') as run:
            run.return_value.stdout = 'false\n'
            with self.assertRaisesRegex(RuntimeError, '終了'):
                emulator.wait_ready(Path('/unused'), 9297, 'fixture')


if __name__ == '__main__':
    unittest.main()
