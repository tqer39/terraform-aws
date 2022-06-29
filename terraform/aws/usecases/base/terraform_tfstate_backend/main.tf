module "s3-bucket" {
  source = "../../../modules/s3/bucket"

  aws_s3_bucket = {
    bucket = var.bucket_name
  }
  aws_s3_bucket_versioning = {
    versioning_configuration = [
      {
        status = "Enabled"
      }
    ]
  }
  aws_s3_bucket_public_access_block = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
}
