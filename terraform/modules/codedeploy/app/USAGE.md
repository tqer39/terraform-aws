<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_codedeploy_app.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_app) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_codedeploy_app"></a> [aws\_codedeploy\_app](#input\_aws\_codedeploy\_app) | Provides a CodeDeploy application to be used as a basis for deployments aws\_codedeploy\_app, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_app | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_id"></a> [application\_id](#output\_application\_id) | The application ID. |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the CodeDeploy application. |
| <a name="output_github_account_name"></a> [github\_account\_name](#output\_github\_account\_name) | The name for a connection to a GitHub account. |
| <a name="output_id"></a> [id](#output\_id) | Amazon's assigned ID for the application. |
| <a name="output_linked_to_github"></a> [linked\_to\_github](#output\_linked\_to\_github) | Whether the user has authenticated with GitHub for the specified application. |
| <a name="output_name"></a> [name](#output\_name) | The application's name. |
<!-- END_TF_DOCS -->