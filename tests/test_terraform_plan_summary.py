"""Check review output and exclusion of sensitive plan content."""

import importlib.util
from pathlib import Path
import unittest

SPEC = importlib.util.spec_from_file_location(
    'plan_summary', Path(__file__).resolve().parents[1] / '.github/scripts/terraform_plan_summary.py')
SUMMARY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SUMMARY)


class PlanSummaryTest(unittest.TestCase):
    def test_reports_replacement_and_excludes_values_and_outputs(self):
        plan = {'resource_changes': [
            {'address': 'aws_iam_role.discord["plan"]',
             'change': {'actions': ['create'], 'after': {'secret': 'private-value'}}},
            {'address': 'aws_iam_role.existing', 'change': {'actions': ['delete', 'create']}},
            {'address': 'aws_iam_role.unchanged', 'change': {'actions': ['no-op']}},
        ], 'output_changes': {'credential': {'after': 'private-output'}}}
        result = SUMMARY.summarize(plan, 'terraform_github')
        self.assertIn('aws_iam_role.discord', result)
        self.assertIn('delete, create', result)
        for hidden in ('private-value', 'private-output', 'aws_iam_role.unchanged'):
            self.assertNotIn(hidden, result)

    def test_no_changes_and_safe_table_cells(self):
        self.assertIn('No resource changes', SUMMARY.summarize({}, 'root'))
        result = SUMMARY.summarize({'resource_changes': [
            {'address': '<tag>|`value`', 'change': {'actions': ['create']}}
        ]}, 'root')
        self.assertIn('&lt;tag&gt;&#124;&#96;value&#96;', result)
