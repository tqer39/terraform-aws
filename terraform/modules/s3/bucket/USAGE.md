<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_cors_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_replication_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_request_payment_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_request_payment_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_s3_bucket"></a> [aws\_s3\_bucket](#input\_aws\_s3\_bucket) | (Required) Provides a S3 bucket resource. aws\_s3\_bucket, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket | <pre>object({<br>    bucket = string<br>  })</pre> | `null` | no |
| <a name="input_aws_s3_bucket_acl"></a> [aws\_s3\_bucket\_acl](#input\_aws\_s3\_bucket\_acl) | (Optional) Provides an S3 bucket ACL resource. aws\_s3\_bucket\_acl, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl | `any` | `null` | no |
| <a name="input_aws_s3_bucket_cors_configuration"></a> [aws\_s3\_bucket\_cors\_configuration](#input\_aws\_s3\_bucket\_cors\_configuration) | (Optional) Provides an S3 bucket CORS configuration resource. aws\_s3\_bucket\_cors\_configuration, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration | `any` | `null` | no |
| <a name="input_aws_s3_bucket_lifecycle_configuration"></a> [aws\_s3\_bucket\_lifecycle\_configuration](#input\_aws\_s3\_bucket\_lifecycle\_configuration) | (Optional) Provides an independent configuration resource for S3 bucket lifecycle configuration. aws\_s3\_bucket\_lifecycle\_configuration, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration | `any` | `null` | no |
| <a name="input_aws_s3_bucket_logging"></a> [aws\_s3\_bucket\_logging](#input\_aws\_s3\_bucket\_logging) | (Optional) Provides an S3 bucket (server access) logging resource. aws\_s3\_bucket\_logging, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging | `any` | `null` | no |
| <a name="input_aws_s3_bucket_policy"></a> [aws\_s3\_bucket\_policy](#input\_aws\_s3\_bucket\_policy) | (Optional) Attaches a policy to an S3 bucket resource. aws\_s3\_bucket\_policy, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy | `any` | `null` | no |
| <a name="input_aws_s3_bucket_public_access_block"></a> [aws\_s3\_bucket\_public\_access\_block](#input\_aws\_s3\_bucket\_public\_access\_block) | (Required) Manages S3 bucket-level Public Access Block configuration. For more information about these settings, see the AWS S3 Block Public Access documentation. aws\_s3\_bucket\_public\_access\_block, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block | <pre>object({<br>    block_public_acls       = bool<br>    block_public_policy     = bool<br>    ignore_public_acls      = bool<br>    restrict_public_buckets = bool<br>  })</pre> | <pre>{<br>  "block_public_acls": true,<br>  "block_public_policy": true,<br>  "ignore_public_acls": true,<br>  "restrict_public_buckets": true<br>}</pre> | no |
| <a name="input_aws_s3_bucket_replication_configuration"></a> [aws\_s3\_bucket\_replication\_configuration](#input\_aws\_s3\_bucket\_replication\_configuration) | (Optional) Provides an independent configuration resource for S3 bucket replication configuration. aws\_s3\_bucket\_replication\_configuration, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration#access_control_translation | `any` | `null` | no |
| <a name="input_aws_s3_bucket_request_payment_configuration"></a> [aws\_s3\_bucket\_request\_payment\_configuration](#input\_aws\_s3\_bucket\_request\_payment\_configuration) | (Optional) Provides an S3 bucket request payment configuration resource. aws\_s3\_bucket\_request\_payment\_configuration, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_request_payment_configuration | `any` | `null` | no |
| <a name="input_aws_s3_bucket_server_side_encryption_configuration"></a> [aws\_s3\_bucket\_server\_side\_encryption\_configuration](#input\_aws\_s3\_bucket\_server\_side\_encryption\_configuration) | (Optional) Provides a S3 bucket server-side encryption configuration resource. aws\_s3\_bucket\_server\_side\_encryption\_configuration, see https://registry.terraform.io/providers/hashicorp%20%20/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration | `any` | `null` | no |
| <a name="input_aws_s3_bucket_versioning"></a> [aws\_s3\_bucket\_versioning](#input\_aws\_s3\_bucket\_versioning) | (Required) Provides a resource for controlling versioning on an S3 bucket. Deleting this resource will either suspend versioning on the associated S3 bucket or simply remove the resource from Terraform state if the associated S3 bucket is unversioned. aws\_s3\_bucket\_versioning, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | n/a |
| <a name="output_id"></a> [id](#output\_id) | n/a |
<!-- END_TF_DOCS -->