<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_codecommit_approval_rule_template_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codecommit_approval_rule_template_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_codecommit_approval_rule_template_association"></a> [aws\_codecommit\_approval\_rule\_template\_association](#input\_aws\_codecommit\_approval\_rule\_template\_association) | Associates a CodeCommit Approval Rule Template with a Repository. aws\_codecommit\_approval\_rule\_template\_association, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codecommit_approval_rule_template_association | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The name of the approval rule template and name of the repository, separated by a comma (,). |
<!-- END_TF_DOCS -->