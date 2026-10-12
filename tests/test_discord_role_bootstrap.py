"""Exercise bootstrap scope and manual approval boundaries."""

import importlib.util
import io
import json
from pathlib import Path
import sys
import subprocess
import tempfile
from unittest.mock import patch
import unittest

SCRIPTS = Path(__file__).resolve().parents[1] / '.github/scripts'
sys.path.insert(0, str(SCRIPTS))
SPEC = importlib.util.spec_from_file_location('bootstrap', SCRIPTS / 'discord_role_bootstrap.py')
BOOTSTRAP = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BOOTSTRAP)


def request():
    return {'GITHUB_REPOSITORY': 'tqer39/terraform-aws', 'GITHUB_EVENT_NAME': 'workflow_dispatch',
            'GITHUB_REF': 'refs/heads/main', 'GITHUB_REPOSITORY_OWNER': 'tqer39',
            'GITHUB_ACTOR': 'tqer39', 'GITHUB_TRIGGERING_ACTOR': 'tqer39',
            'BOOTSTRAP_APPLY': 'false', 'GITHUB_SHA': 'a' * 40}


class DiscordBootstrapTest(unittest.TestCase):
    def test_plan_and_apply_request_boundaries(self):
        env = request()
        BOOTSTRAP.check_request(env)
        BOOTSTRAP.check_request(dict(env, BOOTSTRAP_APPLY='true', REVIEWED_COMMIT='a' * 40))
        for key, value in [('GITHUB_REF', 'refs/heads/feature'), ('GITHUB_EVENT_NAME', 'push'),
                           ('GITHUB_ACTOR', 'another'), ('GITHUB_TRIGGERING_ACTOR', 'another'),
                           ('GITHUB_REPOSITORY', 'tqer39/other'), ('BOOTSTRAP_APPLY', 'yes')]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                BOOTSTRAP.check_request(dict(env, **{key: value}))
        for reviewed in ('', 'a' * 7, 'b' * 40):
            with self.subTest(reviewed=reviewed), self.assertRaises(ValueError):
                BOOTSTRAP.check_request(dict(env, BOOTSTRAP_APPLY='true', REVIEWED_COMMIT=reviewed))

    def test_only_initial_discord_creations_are_allowed(self):
        resources = [{'address': address, 'change': {'actions': ['create']}}
                     for address in BOOTSTRAP.RESOURCES]
        self.assertEqual(len(BOOTSTRAP.check_plan({'resource_changes': resources})), 4)
        self.assertEqual(BOOTSTRAP.check_plan({'resource_changes': []}), [])
        for address, actions in [('module.deploy_role.aws_iam_role.this', ['update']),
                                 ('module.deploy_role.attachment', ['create']),
                                 ('aws_iam_role.discord["plan"]', ['update']),
                                 ('aws_iam_role.discord["apply"]', ['delete', 'create'])]:
            with self.subTest(address=address, actions=actions), self.assertRaises(ValueError):
                BOOTSTRAP.check_plan({'resource_changes': resources + [
                    {'address': address, 'change': {'actions': actions}}]})
        for flag in ({'deferred_changes': [{'reason': 'unknown'}]}, {'errored': True}):
            with self.assertRaises(ValueError):
                BOOTSTRAP.check_plan(flag)

    def events(self):
        return ([{'type': 'version', 'ui': '1.2'}]
                + [{'type': 'planned_change', 'change': {
                    'resource': {'addr': address}, 'action': 'create'}}
                   for address in sorted(BOOTSTRAP.RESOURCES)]
                + [{'type': 'change_summary', 'changes': {
                    'add': 4, 'change': 0, 'remove': 0, 'operation': 'plan'}}])

    def parse(self, events):
        return BOOTSTRAP.read_plan_events(io.StringIO(
            '\n'.join(json.dumps(event) for event in events)))

    def test_plan_events_validate_creations_without_prior_state(self):
        plan = self.parse(self.events())
        self.assertEqual(len(BOOTSTRAP.check_plan(plan)), 4)
        self.assertNotIn('prior_state', plan)
        no_changes = [{'type': 'version', 'ui': '1.2'},
                      {'type': 'change_summary', 'changes': {
                          'add': 0, 'change': 0, 'remove': 0, 'operation': 'plan'}}]
        self.assertEqual(BOOTSTRAP.check_plan(self.parse(no_changes)), [])

    def test_truncated_inconsistent_or_error_streams_fail_closed(self):
        for events in ([], self.events()[:-1], self.events()[1:],
                       self.events() + [{'type': 'diagnostic', '@level': 'error'}],
                       self.events() + [{'type': 'deferred_change'}],
                       self.events() + [self.events()[-1]]):
            with self.subTest(events=events), self.assertRaises(ValueError):
                self.parse(events)
        for field, value in [('add', 5), ('change', 1), ('remove', 1), ('operation', 'apply')]:
            events = self.events()
            events[-1]['changes'][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.parse(events)

    def test_event_scope_and_action_remain_restricted(self):
        for address, action in [('module.deploy_role.aws_iam_role.this', 'create'),
                                ('aws_iam_role.discord["plan"]', 'update'),
                                ('aws_iam_role.discord["plan"]', 'replace')]:
            events = self.events()
            events[1]['change'] = {'resource': {'addr': address}, 'action': action}
            with self.subTest(address=address, action=action), self.assertRaises(ValueError):
                self.parse(events)
        events = self.events()
        events[0]['ui'] = '2.0'
        with self.assertRaises(ValueError):
            self.parse(events)

    def test_real_terraform_plan_events_without_aws(self):
        root = SCRIPTS.parent.parent
        binary = subprocess.check_output(['mise', 'which', 'terraform'], cwd=root, text=True).strip()
        with tempfile.TemporaryDirectory() as directory:
            Path(directory, 'main.tf').write_text('resource "terraform_data" "example" { input = "sample" }\n')
            initialized = subprocess.run([binary, 'init', '-backend=false', '-input=false'],
                                         cwd=directory, capture_output=True, text=True)
            self.assertEqual(initialized.returncode, 0, initialized.stderr)
            result = subprocess.run([binary, 'plan', '-json', '-detailed-exitcode',
                                     '-input=false', '-out=review.tfplan'],
                                    cwd=directory, capture_output=True, text=True)
            self.assertEqual(result.returncode, 2, result.stderr)
            with patch.object(BOOTSTRAP, 'RESOURCES', {'terraform_data.example'}):
                plan = BOOTSTRAP.read_plan_events(io.StringIO(result.stdout))
                self.assertEqual(BOOTSTRAP.check_plan(plan), ['terraform_data.example'])
