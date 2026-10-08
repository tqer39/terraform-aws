"""Generate a configuration graph in an isolated copy, without AWS or state."""

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

REPO = Path(__file__).resolve().parents[1]


def generate_graph(root, output_directory):
    root = Path(root).resolve()
    relative = root.relative_to(REPO / 'terraform/envs')
    if len(relative.parts) != 2 or not (root / 'terraform.tf').is_file():
        raise ValueError('Expected a Terraform root under terraform/envs/ENV/ROOT')
    if not shutil.which('dot'):
        raise ValueError('Graphviz dot is required')
    output = Path(output_directory).resolve()
    with tempfile.TemporaryDirectory(prefix='terraform-graph-') as directory:
        temporary = Path(directory)
        # Preserve relative module paths, excluding all local state and init data.
        shutil.copytree(REPO / 'terraform', temporary / 'terraform',
                        ignore=shutil.ignore_patterns('.terraform', '*.tfstate*'))
        copied_root = temporary / 'terraform/envs' / relative
        (copied_root / 'graph_backend_override.tf').write_text(
            'terraform {\n  backend "local" {}\n}\n')
        env = dict(os.environ, TF_DATA_DIR=str(temporary / 'data'))
        command = ['terraform', f'-chdir={copied_root}']
        subprocess.run(command + ['init', '-backend=true', '-input=false', '-lockfile=readonly'],
                       env=env, check=True)
        subprocess.run(command + ['validate', '-no-color'], env=env, check=True)
        dot = temporary / 'dependency-graph.dot'
        svg = temporary / 'dependency-graph.svg'
        with dot.open('w') as stream:
            subprocess.run(command + ['graph'], env=env, stdout=stream, check=True)
        subprocess.run(['dot', '-T', 'svg', str(dot), '-o', str(svg)], env=env, check=True)
        output.mkdir(parents=True, exist_ok=True)
        shutil.copy2(dot, output / dot.name)
        shutil.copy2(svg, output / svg.name)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('Usage: python3 scripts/terraform-graph.py ROOT OUTPUT_DIRECTORY', file=sys.stderr)
        sys.exit(2)
    try:
        generate_graph(*sys.argv[1:])
    except subprocess.CalledProcessError as error:
        sys.exit(error.returncode)
    except (OSError, ValueError) as error:
        print(f'Terraform graph failed: {error}', file=sys.stderr)
        sys.exit(2)
