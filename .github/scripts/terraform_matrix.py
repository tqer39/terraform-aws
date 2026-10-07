"""Select Terraform roots from immutable event commits without changing checkout."""

import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys


def git(*args):
    return subprocess.check_output(['git', *args], text=True).strip()


def changed_files(base, head):
    # Resolve before diff; invalid or unavailable history must fail the job.
    base = git('rev-parse', '--verify', f'{base}^{{commit}}')
    head = git('rev-parse', '--verify', f'{head}^{{commit}}')
    return subprocess.check_output(
        ['git', 'diff', '--name-only', '--no-renames', '-z', base, head, '--']
    ).decode().rstrip('\0').split('\0')


def affects_root(path, root):
    if not path or path.endswith('.md'):
        return False
    # Shared code can have transitive consumers. Select all configured roots
    # instead of attempting to parse HCL or silently missing a dependency.
    return (
        path.startswith(root.rstrip('/') + '/')
        or path.startswith(('terraform/modules/', 'terraform/usecases/', '.github/actions/'))
        or path in ('.github/scripts/terraform_matrix.py',
                    '.github/scripts/check_for_changes_in_terraform_files.sh')
        or path.startswith('.github/workflows/deploy_pipeline/')
        or re.fullmatch(r'\.github/workflows/(?:_terraform-aws-.*|terraform-aws-.*-diff-check)\.yml', path)
        is not None
    )


def select_matrix(environment, event_name, event):
    if environment not in ('management', 'portfolio', 'sandbox'):
        raise ValueError('Unknown AWS environment')
    pipelines = Path(f'.github/workflows/deploy_pipeline/{environment}').read_text().split()
    if not pipelines or any(
        not re.fullmatch(r'[A-Za-z0-9_-]+', name) for name in pipelines
    ) or len(pipelines) != len(set(pipelines)):
        raise ValueError('Invalid or empty deployment pipeline list')

    if event_name == 'pull_request':
        base = event['pull_request']['base']['sha']
        head = event['pull_request']['head']['sha']
        base = git('merge-base', base, head)
        changed = changed_files(base, head)
    elif event_name == 'push':
        base, head = event['before'], event['after']
        if base == '0' * 40:
            # A new branch has no previous tree to compare. Plan all roots.
            git('rev-parse', '--verify', f'{head}^{{commit}}')
            return pipelines
        changed = changed_files(base, head)
    elif event_name in ('workflow_dispatch', 'schedule'):
        return pipelines
    else:
        raise ValueError(f'Unsupported event: {event_name}')
    selected = [name for name in pipelines if any(
        affects_root(path, f'terraform/envs/{environment}/{name}')
        for path in changed
    )]
    return selected or ['_empty']


def main():
    if len(sys.argv) == 5 and sys.argv[1] == '--check':
        root = str(PurePosixPath(sys.argv[2]))
        if root.startswith('/') or '..' in PurePosixPath(root).parts:
            raise ValueError('Root must be a repository-relative path')
        return 0 if any(affects_root(p, root) for p in changed_files(*sys.argv[3:])) else 1
    event = json.loads(Path(os.environ['GITHUB_EVENT_PATH']).read_text())
    matrix = select_matrix(os.environ['AWS_ENV_NAME'], os.environ['GITHUB_EVENT_NAME'], event)
    with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
        output.write('matrix=' + json.dumps(matrix, separators=(',', ':')) + '\n')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (KeyError, ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f'Terraform matrix failed: {error}', file=sys.stderr)
        sys.exit(2)
