<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_codecommit_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codecommit_repository) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_codecommit_approval_rule_template_association"></a> [aws\_codecommit\_approval\_rule\_template\_association](#input\_aws\_codecommit\_approval\_rule\_template\_association) | Associates a CodeCommit Approval Rule Template with a Repository. aws\_codecommit\_approval\_rule\_template\_association, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codecommit_approval_rule_template_association | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the repository |
| <a name="output_clone_url_http"></a> [clone\_url\_http](#output\_clone\_url\_http) | The URL to use for cloning the repository over HTTPS. |
| <a name="output_clone_url_ssh"></a> [clone\_url\_ssh](#output\_clone\_url\_ssh) | The URL to use for cloning the repository over SSH. |
| <a name="output_repository_id"></a> [repository\_id](#output\_repository\_id) | The ID of the repository |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | A map of tags assigned to the resource, including those inherited from the provider default\_tags configuration block. |
<!-- END_TF_DOCS -->