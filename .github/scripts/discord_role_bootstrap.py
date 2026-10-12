"""Permit only initial creation of the four Discord IAM resources."""

import json
import os
import re
import sys

from terraform_plan_summary import summarize

RESOURCES = {f'{kind}.discord["{mode}"]'
             for kind in ('aws_iam_role', 'aws_iam_role_policy')
             for mode in ('plan', 'apply')}


def check_request(env):
    if (env.get('GITHUB_REPOSITORY') != 'tqer39/terraform-aws'
            or env.get('GITHUB_EVENT_NAME') != 'workflow_dispatch'
            or env.get('GITHUB_REF') != 'refs/heads/main'
            or env.get('GITHUB_REPOSITORY_OWNER') != 'tqer39'
            or env.get('GITHUB_ACTOR') != 'tqer39'
            or env.get('GITHUB_TRIGGERING_ACTOR') != 'tqer39'
            or env.get('BOOTSTRAP_APPLY') not in ('true', 'false')):
        raise ValueError('Bootstrap requires an owner request from main')
    if env['BOOTSTRAP_APPLY'] == 'true':
        reviewed = env.get('REVIEWED_COMMIT', '')
        if not re.fullmatch(r'[0-9a-f]{40}', reviewed) or reviewed != env.get('GITHUB_SHA'):
            raise ValueError('Reviewed commit must match the full current SHA')


def check_plan(plan):
    if plan.get('errored') or plan.get('deferred_changes'):
        raise ValueError('Bootstrap requires a successful plan without deferred changes')
    changed = []
    for resource in plan.get('resource_changes', []):
        actions = resource['change']['actions']
        if actions == ['no-op']:
            continue
        if resource['address'] not in RESOURCES or actions != ['create']:
            raise ValueError('Bootstrap plan contains an unrelated change or a non-create action')
        changed.append(resource['address'])
    return changed


def read_plan_events(stream):
    resources = []
    summary = None
    version = False
    addresses = set()
    for line in stream:
        event = json.loads(line)
        kind = event.get('type')
        if event.get('@level') == 'error' or 'defer' in str(kind):
            raise ValueError('Plan stream contains an error or deferred change')
        if kind == 'version':
            if version or resources or summary or not event.get('ui', '').startswith('1.'):
                raise ValueError('Unsupported or misplaced plan stream version')
            version = True
        elif kind == 'planned_change':
            if not version or summary is not None:
                raise ValueError('Plan changes must follow version and precede summary')
            change = event['change']
            address = change['resource']['addr']
            if address in addresses or change.get('importing') or change.get('deferred'):
                raise ValueError('Duplicate, imported or deferred plan change')
            addresses.add(address)
            resources.append({'address': address, 'change': {'actions': [change['action']]}})
        elif kind == 'change_summary':
            if not version or summary is not None:
                raise ValueError('Missing version or repeated plan summary')
            summary = event['changes']
    plan = {'resource_changes': resources}
    changed = check_plan(plan)
    if (not version or summary is None or summary.get('operation') != 'plan'
            or summary.get('add') != len(changed) or summary.get('change') != 0
            or summary.get('remove') != 0):
        raise ValueError('Plan summary is missing or inconsistent with allowed creations')
    return plan


def main():
    check_request(os.environ)
    if sys.argv[1:] == ['--check-request']:
        return
    plan = read_plan_events(sys.stdin)
    changed = check_plan(plan)
    with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as output:
        output.write(summarize(plan, 'Discord role bootstrap (initial creation only)'))
    with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
        output.write('has_changes=' + str(bool(changed)).lower() + '\n')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, TypeError):
        print('::error::Discord bootstrap request or plan failed validation.', file=sys.stderr)
        sys.exit(1)
