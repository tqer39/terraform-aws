<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_codedeploy_deployment_config.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_config) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_codedeploy_deployment_config"></a> [aws\_codedeploy\_deployment\_config](#input\_aws\_codedeploy\_deployment\_config) | Provides a CodeDeploy deployment config for an application aws\_codedeploy\_deployment\_config, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_config | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deployment_config_id"></a> [deployment\_config\_id](#output\_deployment\_config\_id) | The AWS Assigned deployment config id |
| <a name="output_id"></a> [id](#output\_id) | The deployment group's config name. |
<!-- END_TF_DOCS -->