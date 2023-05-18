<!-- BEGIN_TF_DOCS -->
# Usage

- GitHub Actions から AWS へアクセスするときに使用する OIDC 認証の ID Provider にアクセスする IAM ロールを作成します。
- [terraform-vercel](https://github.com/tqer39/terraform-vercel) 用です。

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_policy.deploy_deny_specifics](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | (Required) AWS account ID | `string` | n/a | yes |
| <a name="input_aws_env_name"></a> [aws\_env\_name](#input\_aws\_env\_name) | (Required) AWS Environment name | `string` | n/a | yes |
| <a name="input_organization"></a> [organization](#input\_organization) | (Required) GitHub organization name | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | (Required) GitHub repository name | `string` | n/a | yes |
<!-- END_TF_DOCS -->