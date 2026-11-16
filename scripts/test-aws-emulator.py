#!/usr/bin/env python3
"""専用の一時環境で AWS Emulator と provider の API 互換性を検証する。"""

import hashlib
import fcntl
import http.client
import json
import os
from pathlib import Path
import shutil
import socket
import ssl
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
import uuid

REPO = Path(__file__).resolve().parents[1]
FIXTURE = REPO / 'tests/aws-emulator'


def terraform_environment(directory, port, inherited):
    """AWS の実認証・endpoint と Terraform の暗黙引数を引き継がない。"""
    env = {key: value for key, value in inherited.items()
           if not key.startswith(('AWS_', 'TF_'))}
    credentials = directory / 'home/.aws/emulator' / str(port)
    config = directory / 'terraform.rc'
    config.write_text('disable_checkpoint = true\n')
    empty_config = directory / 'aws-config'
    empty_config.write_text('')
    env.update({
        'AWS_CONFIG_FILE': str(empty_config),
        'AWS_SHARED_CREDENTIALS_FILE': str(credentials / 'emulator_credentials'),
        'AWS_EC2_METADATA_DISABLED': 'true',
        'AWS_REGION': 'us-east-1',
        'AWS_DEFAULT_REGION': 'us-east-1',
        'TF_CLI_CONFIG_FILE': str(config),
        'TF_IN_AUTOMATION': 'true',
        'TF_INPUT': 'false',
        'TF_VAR_endpoint': f'https://127.0.0.1:{port}',
        'TF_VAR_credentials_file': str(credentials / 'emulator_credentials'),
        'TF_VAR_ca_bundle': str(credentials / 'ca.pem'),
        'CHECKPOINT_DISABLE': '1',
        'NO_PROXY': '127.0.0.1,localhost',
        'no_proxy': '127.0.0.1,localhost',
    })
    return env


def run(command, **kwargs):
    return subprocess.run(command, check=kwargs.pop('check', True), **kwargs)


def wait_ready(directory, port, container, timeout=60):
    cert = directory / 'home/.aws/emulator' / str(port) / 'ca.pem'
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        state = run(['docker', 'inspect', '--format', '{{.State.Running}}', container],
                    capture_output=True, text=True).stdout.strip()
        if state != 'true':
            raise RuntimeError('AWS Emulator が起動中に終了しました。')
        if cert.exists():
            try:
                context = ssl.create_default_context(cafile=str(cert))
                opener = urllib.request.build_opener(
                    urllib.request.ProxyHandler({}),
                    urllib.request.HTTPSHandler(context=context))
                with opener.open(f'https://127.0.0.1:{port}/__admin/health', timeout=2) as response:
                    if response.status == 200 and response.read().strip() == b'ok':
                        return
            except (OSError, urllib.error.URLError, http.client.HTTPException):
                pass
        time.sleep(1)
    raise RuntimeError('AWS Emulator の準備が60秒以内に完了しませんでした。')


def main():
    for executable in ('docker', 'terraform'):
        if shutil.which(executable) is None:
            raise RuntimeError(f'{executable} をインストールしてから実行してください。')
    architecture = run(['docker', 'info', '--format', '{{.Architecture}}'],
                       capture_output=True, text=True).stdout.strip()
    architectures = {'aarch64': 'aarch64', 'arm64': 'aarch64',
                     'x86_64': 'x86_64', 'amd64': 'x86_64'}
    if architecture not in architectures:
        raise RuntimeError(f'未対応の Docker アーキテクチャです: {architecture}')
    package_arch = architectures[architecture]
    package = json.loads((FIXTURE / 'packages.json').read_text())
    digest = hashlib.sha256((FIXTURE / 'Dockerfile').read_bytes()
                            + (FIXTURE / 'packages.json').read_bytes()).hexdigest()[:16]
    image = f'terraform-aws-emulator:{digest}-{package_arch}'
    if subprocess.run(['docker', 'image', 'inspect', image],
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
        run(['docker', 'build', '--build-arg', f'EMULATOR_VERSION={package["version"]}',
             '--build-arg', f'PACKAGE_ARCH={package_arch}', '--build-arg',
             f'PACKAGE_SHA256={package["sha256"][package_arch]}',
             '-t', image, str(FIXTURE)])
    cache = REPO / '.standards/cache/aws-emulator'
    cache.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='run-', dir=cache) as temp:
        directory = Path(temp)
        home = directory / 'home'
        home.mkdir()
        # 同じポートを内外で使用し、生成ファイルのパスとの不一致を避ける。
        with socket.socket() as listener:
            listener.bind(('127.0.0.1', 0))
            port = listener.getsockname()[1]
        container = f'terraform-aws-emulator-{uuid.uuid4().hex}'
        try:
            run(['docker', 'run', '--detach', '--name', container,
                 '--memory=2g', '--memory-swap=2g',
                 '--user', f'{os.getuid()}:{os.getgid()}',
                 '-p', f'127.0.0.1:{port}:{port}',
                 '--mount', f'type=bind,source={home},target=/home/emulator',
                 image, '-p', str(port)])
            wait_ready(directory, port, container)
            target = directory / 'tests/aws-emulator'
            target.mkdir(parents=True)
            for name in ('main.tf', 'services.tftest.hcl', '.terraform.lock.hcl'):
                shutil.copyfile(FIXTURE / name, target / name)
            env = terraform_environment(directory, port, os.environ)
            plugins = cache / 'plugins'
            plugins.mkdir(exist_ok=True)
            env['TF_PLUGIN_CACHE_DIR'] = str(plugins)
            # provider の共有キャッシュは並行 init に対応しないため直列化する。
            with (cache / 'init.lock').open('w') as lock:
                fcntl.flock(lock, fcntl.LOCK_EX)
                run(['terraform', f'-chdir={target}', 'init', '-backend=false',
                     '-input=false', '-lockfile=readonly'], env=env, timeout=300)
            for arguments in (['validate', '-no-color'], ['test', '-no-color']):
                run(['terraform', f'-chdir={target}', *arguments], env=env, timeout=300)
        except BaseException:
            subprocess.run(['docker', 'logs', '--tail', '40', container], check=False)
            raise
        finally:
            # Terraform が途中で失敗しても、この実行だけのメモリ内リソースを破棄する。
            cleanup = run(['docker', 'rm', '--force', container],
                          stdout=subprocess.DEVNULL, check=False)
            if cleanup.returncode:
                if sys.exc_info()[0] is None:
                    raise RuntimeError(f'検証用コンテナを削除できませんでした: {container}')
                print(f'検証用コンテナの削除にも失敗しました: {container}', file=sys.stderr)


if __name__ == '__main__':
    main()
