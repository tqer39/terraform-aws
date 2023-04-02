<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_codepipeline_webhook.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline_webhook) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_codepipeline_webhook"></a> [aws\_codepipeline\_webhook](#input\_aws\_codepipeline\_webhook) | Provides a CodePipeline Webhook. aws\_codepipeline\_webhook, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline_webhook | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The CodePipeline webhook's ARN. |
| <a name="output_id"></a> [id](#output\_id) | The CodePipeline webhook's ARN. |
| <a name="output_url"></a> [url](#output\_url) | The CodePipeline webhook's URL. POST events to this endpoint to trigger the target. |
<!-- END_TF_DOCS -->