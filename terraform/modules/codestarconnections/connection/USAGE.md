<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_codestarconnections_connection.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codestarconnections_connection) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_codestarconnections_connection"></a> [aws\_codestarconnections\_connection](#input\_aws\_codestarconnections\_connection) | Provides a CodeStar Connection. aws\_codestarconnections\_connection, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codestarconnections_connection | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The codestar connection ARN. |
| <a name="output_connection_status"></a> [connection\_status](#output\_connection\_status) | The codestar connection status. Possible values are PENDING, AVAILABLE and ERROR. |
| <a name="output_id"></a> [id](#output\_id) | The codestar connection ARN. |
<!-- END_TF_DOCS -->