<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_codecommit_approval_rule_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codecommit_approval_rule_template) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_codecommit_approval_rule_template"></a> [aws\_codecommit\_approval\_rule\_template](#input\_aws\_codecommit\_approval\_rule\_template) | Provides a CodeCommit Approval Rule Template Resource. aws\_codecommit\_approval\_rule\_template, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codecommit_approval_rule_template | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_approval_rule_template_id"></a> [approval\_rule\_template\_id](#output\_approval\_rule\_template\_id) | The ID of the approval rule template |
| <a name="output_creation_date"></a> [creation\_date](#output\_creation\_date) | The date the approval rule template was created, in RFC3339 format. |
| <a name="output_last_modified_date"></a> [last\_modified\_date](#output\_last\_modified\_date) | The date the approval rule template was most recently changed, in RFC3339 format. |
| <a name="output_last_modified_user"></a> [last\_modified\_user](#output\_last\_modified\_user) | The Amazon Resource Name (ARN) of the user who made the most recent changes to the approval rule template. |
| <a name="output_rule_content_sha256"></a> [rule\_content\_sha256](#output\_rule\_content\_sha256) | The SHA-256 hash signature for the content of the approval rule template. |
<!-- END_TF_DOCS -->