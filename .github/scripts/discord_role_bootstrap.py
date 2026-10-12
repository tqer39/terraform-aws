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


def main():
    check_request(os.environ)
    if sys.argv[1:] == ['--check-request']:
        return
    plan = json.load(sys.stdin)
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
