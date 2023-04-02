<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_codepipeline.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_codepipeline"></a> [aws\_codepipeline](#input\_aws\_codepipeline) | Provides a CodePipeline. aws\_codepipeline, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The codepipeline ARN. |
| <a name="output_id"></a> [id](#output\_id) | The codepipeline ID. |
<!-- END_TF_DOCS -->