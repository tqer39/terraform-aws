"""Exercise bootstrap scope and manual approval boundaries."""

import importlib.util
from pathlib import Path
import sys
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
