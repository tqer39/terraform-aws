"""Keep desktop integration coverage for setup changes and manual runs."""

import json
import os
from pathlib import Path
import subprocess
import sys

from terraform_matrix import changed_files, git

SETUP_FILES = {
    'setup-repository.sh',
    'mise.toml',
    '.terraform-version',
    '.github/workflows/setup-repository-test.yml',
    '.github/scripts/setup_profile.py',
    '.github/scripts/terraform_matrix.py',
    'tests/test_setup_repository.py',
    'tests/test_setup_profile.py',
    'tests/test_mise_tasks.py',
}


def select_profile(event_name, event):
    if event_name == 'workflow_dispatch':
        return 'full'
    if event_name == 'pull_request':
        head = event['pull_request']['head']['sha']
        base = git('merge-base', event['pull_request']['base']['sha'], head)
    elif event_name == 'push':
        base, head = event['before'], event['after']
        if base == '0' * 40:
            return 'full'
    else:
        raise ValueError(f'Unsupported event: {event_name}')
    return 'full' if SETUP_FILES.intersection(changed_files(base, head)) else 'cli'


def main():
    event = json.loads(Path(os.environ['GITHUB_EVENT_PATH']).read_text())
    profile = select_profile(os.environ['GITHUB_EVENT_NAME'], event)
    with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
        output.write(f'profile={profile}\n')


if __name__ == '__main__':
    try:
        main()
    except (KeyError, ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f'Setup profile selection failed: {error}', file=sys.stderr)
        sys.exit(2)
