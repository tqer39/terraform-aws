<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_codedeploy_deployment_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_codedeploy_deployment_group"></a> [aws\_codedeploy\_deployment\_group](#input\_aws\_codedeploy\_deployment\_group) | Provides a CodeDeploy Deployment Group for a CodeDeploy Application. aws\_codedeploy\_deployment\_group, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_group | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the CodeDeploy deployment group. |
| <a name="output_compute_platform"></a> [compute\_platform](#output\_compute\_platform) | The destination platform type for the deployment. |
| <a name="output_deployment_group_id"></a> [deployment\_group\_id](#output\_deployment\_group\_id) | The ID of the CodeDeploy deployment group. |
| <a name="output_id"></a> [id](#output\_id) | Application name and deployment group name. |
<!-- END_TF_DOCS -->