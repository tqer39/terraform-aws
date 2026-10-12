"""Report resource actions without exposing values from a Terraform plan."""

import html
import json
import os
import sys


def summarize(plan, root):
    lines = [f'### Terraform plan: {html.escape(root)}', '', '| Resource | Actions |', '| --- | --- |']
    changes = [resource for resource in plan.get('resource_changes', [])
               if resource['change']['actions'] != ['no-op']]
    for resource in changes:
        address = html.escape(resource['address']).replace('|', '&#124;').replace('`', '&#96;')
        actions = ', '.join(resource['change']['actions'])
        lines.append(f'| {address} | {html.escape(actions)} |')
    if not changes:
        lines.append('| No resource changes | — |')
    lines.extend(['', 'Resource values and outputs are omitted. Replacement includes delete and create.', ''])
    return '\n'.join(lines)


if __name__ == '__main__':
    plan = json.load(sys.stdin)
    with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as output:
        output.write(summarize(plan, os.path.relpath(os.getcwd(), os.environ['GITHUB_WORKSPACE'])))
