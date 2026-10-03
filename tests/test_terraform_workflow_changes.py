"""Check which workflow changes require Terraform execution."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / ".github/scripts/check_for_changes_in_terraform_files.sh"


class WorkflowChangesTest(unittest.TestCase):
    def check_change(self, changed_file, expected):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory)
            pipeline = fixture / "pipeline"
            pipeline.mkdir()
            # Only stub Git discovery; run the actual change-detection script.
            git = fixture / "git"
            git.write_text('#!/bin/sh\nif [ "$1" = diff ]; then printf "%s\\n" "$CHANGED_FILE"; fi\n')
            git.chmod(0o755)
            env = dict(os.environ, CHANGED_FILE=changed_file)
            env["PATH"] = str(fixture) + os.pathsep + env["PATH"]
            result = subprocess.run(
                ["bash", str(SCRIPT), str(pipeline), "main", "feature"],
                cwd=fixture, env=env, capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, expected, result.stdout + result.stderr)

    def test_unrelated_workflows_do_not_run_terraform(self):
        for name in ("generate-pr-description", "setup-repository-test", "tmp-tag-push-test", "pre-commit"):
            with self.subTest(name=name):
                self.check_change(f".github/workflows/{name}.yml", 1)

    def test_terraform_workflows_run_terraform(self):
        for path in (
            ".github/workflows/_terraform-aws-sandbox.yml",
            ".github/workflows/terraform-aws-management-diff-check.yml",
            ".github/actions/setup-terraform/action.yml",
            ".github/workflows/deploy_pipeline/portfolio",
        ):
            with self.subTest(path=path):
                self.check_change(path, 0)

    def test_documentation_does_not_run_terraform(self):
        self.check_change("docs/plans/README.md", 1)


if __name__ == "__main__":
    unittest.main()
