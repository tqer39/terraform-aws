<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_codestarconnections_host.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codestarconnections_host) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_codestarconnections_host"></a> [aws\_codestarconnections\_host](#input\_aws\_codestarconnections\_host) | Provides a CodeStar Host. aws\_codestarconnections\_host, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codestarconnections_host | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The CodeStar Host ARN. |
| <a name="output_id"></a> [id](#output\_id) | The CodeStar Host ARN. |
| <a name="output_status"></a> [status](#output\_status) | The CodeStar Host status. Possible values are PENDING, AVAILABLE, VPC\_CONFIG\_DELETING, VPC\_CONFIG\_INITIALIZING, and VPC\_CONFIG\_FAILED\_INITIALIZATION. |
<!-- END_TF_DOCS -->