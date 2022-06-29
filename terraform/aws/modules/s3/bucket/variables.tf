variable "aws_s3_bucket" {
  description = "(Required) Provides a S3 bucket resource. aws_s3_bucket, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket"
  type = object({
    bucket = string
  })
  default = null
}

variable "aws_s3_bucket_acl" {
  description = "(Optional) Provides an S3 bucket ACL resource. aws_s3_bucket_acl, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl"
  type        = any
  default     = null
}

variable "aws_s3_bucket_cors_configuration" {
  description = "(Optional) Provides an S3 bucket CORS configuration resource. aws_s3_bucket_cors_configuration, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration"
  type        = any
  default     = null
}

variable "aws_s3_bucket_inventory" {
  description = "(Optional) Provides a S3 bucket inventory configuration resource. aws_s3_bucket_inventory, see https://registry.terraform.io/providers/hashicorp%20%20/aws/latest/docs/resources/s3_bucket_inventory"
  type        = any
  default     = null
}

variable "aws_s3_bucket_lifecycle_configuration" {
  description = "(Optional) Provides an independent configuration resource for S3 bucket lifecycle configuration. aws_s3_bucket_lifecycle_configuration, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration"
  type        = any
  default     = null
}

variable "aws_s3_bucket_logging" {
  description = "(Optional) Provides an S3 bucket (server access) logging resource. aws_s3_bucket_logging, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging"
  type        = any
  default     = null
}

variable "aws_s3_bucket_public_access_block" {
  description = "(Required) Manages S3 bucket-level Public Access Block configuration. For more information about these settings, see the AWS S3 Block Public Access documentation. aws_s3_bucket_public_access_block, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block"
  type        = any
  default     = null
}

variable "aws_s3_bucket_policy" {
  description = "(Optional) Attaches a policy to an S3 bucket resource. aws_s3_bucket_policy, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy"
  type        = any
  default     = null
}

variable "aws_s3_bucket_replication_configuration" {
  description = "(Optional) Provides an independent configuration resource for S3 bucket replication configuration. aws_s3_bucket_replication_configuration, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration#access_control_translation"
  type        = any
  default     = null
}

variable "aws_s3_bucket_request_payment_configuration" {
  description = "(Optional) Provides an S3 bucket request payment configuration resource. aws_s3_bucket_request_payment_configuration, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_request_payment_configuration"
  type        = any
  default     = null
}

variable "aws_s3_bucket_server_side_encryption_configuration" {
  description = "(Optional) Provides a S3 bucket server-side encryption configuration resource. aws_s3_bucket_server_side_encryption_configuration, see https://registry.terraform.io/providers/hashicorp%20%20/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration"
  type        = any
  default     = null
}

variable "aws_s3_bucket_versioning" {
  description = "(Optional) Provides a resource for controlling versioning on an S3 bucket. Deleting this resource will either suspend versioning on the associated S3 bucket or simply remove the resource from Terraform state if the associated S3 bucket is unversioned. aws_s3_bucket_versioning, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning"
  type        = any
  default     = null
}

variable "aws_s3_bucket_website_configuration" {
  description = "(Optional) Provides an S3 bucket website configuration resource. aws_s3_bucket_website_configuration, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration"
  type        = any
  default     = null
}

variable "aws_s3_bucket_ownership_controls" {
  description = "(Optional) Provides an S3 bucket ownership controls resource. aws_s3_bucket_ownership_controls, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls"
  type        = any
  default     = null
}
