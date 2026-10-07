# /// script
# requires-python = ">=3.10"
# dependencies = ["pre-commit-hooks==4.6.0", "identify==2.5.36"]
# ///
"""Run the existing safety checks directly, with their original file types."""

from contextlib import redirect_stderr, redirect_stdout
import importlib
import io
from pathlib import Path
import sys
import tempfile

HOOKS = {
    'check-added-large-files': ('check_added_large_files', 'file', ['--maxkb=512', '--enforce-all']),
    'check-json': ('check_json', 'json', []),
    'check-yaml': ('check_yaml', 'yaml', []),
    'detect-aws-credentials': ('detect_aws_credentials', 'text', ['--allow-missing-credentials']),
    'detect-private-key': ('detect_private_key', 'text', []),
    'end-of-file-fixer': ('end_of_file_fixer', 'text', []),
    'mixed-line-ending': ('mixed_line_ending', 'text', ['--fix=lf']),
    'trailing-whitespace': ('trailing_whitespace_fixer', 'text', []),
}


def main(argv):
    from identify.identify import tags_from_path

    module, file_type, options = HOOKS[argv[0]]
    check_only = '--check' in argv[1:]
    files = [name for name in argv[1:] if name != '--check'
             if Path(name).is_file() and not Path(name).is_symlink()
             and file_type in tags_from_path(name)]
    if not files:
        return 0
    hook = importlib.import_module(f'pre_commit_hooks.{module}').main
    if not check_only:
        return hook(options + files)
    # Detect formatting errors without modifying the developer's worktree.
    with tempfile.TemporaryDirectory() as directory:
        copies = []
        for index, name in enumerate(files):
            copy = Path(directory) / str(index) / Path(name).name
            copy.parent.mkdir()
            copy.write_bytes(Path(name).read_bytes())
            copies.append(str(copy))
        output = io.StringIO()
        with redirect_stdout(output), redirect_stderr(output):
            result = hook(options + copies)
        message = output.getvalue()
        for copy, name in zip(copies, files):
            message = message.replace(copy, name)
        print(message, end='')
        return result


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
