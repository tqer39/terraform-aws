<!-- BEGIN_TF_DOCS -->
# Usage

- SSO アクセス

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ssoadmin_account_assignment.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_account_assignment) | resource |
| [aws_ssoadmin_permission_set.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set) | resource |
| [aws_identitystore_group.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/identitystore_group) | data source |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_ssoadmin_instances.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssoadmin_instances) | data source |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sso_instance_arns"></a> [sso\_instance\_arns](#output\_sso\_instance\_arns) | Set of Amazon Resource Names (ARNs) of the SSO Instances. |
| <a name="output_sso_instance_id"></a> [sso\_instance\_id](#output\_sso\_instance\_id) | AWS Region. |
| <a name="output_sso_instance_identity_store_ids"></a> [sso\_instance\_identity\_store\_ids](#output\_sso\_instance\_identity\_store\_ids) | Set of identifiers of the identity stores connected to the SSO Instances. |
<!-- END_TF_DOCS -->