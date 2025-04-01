<!-- BEGIN_TF_DOCS -->
# Usage

- AWS Organizations を作成します。

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_organizations_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) | resource |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organization) | resource |
| [aws_organizations_organizational_unit.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_accounts"></a> [accounts](#input\_accounts) | (Require) List of accounts to create. | `any` | `null` | no |
| <a name="input_organizational_units"></a> [organizational\_units](#input\_organizational\_units) | (Require) List of organizational units to create. | <pre>list(object({<br/>    name = string<br/>  }))</pre> | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | (Require) Owner of the accounts. | `string` | n/a | yes |
<!-- END_TF_DOCS -->