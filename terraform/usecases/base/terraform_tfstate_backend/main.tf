module "s3-bucket" {
  source = "../../../modules/s3/bucket"

  aws_s3_bucket = {
    bucket = var.bucket_name
  }
  aws_s3_bucket_acl = {
    acl = "private"
  }
  aws_s3_bucket_versioning = {
    versioning_configuration = [
      {
        status = "Enabled"
      }
    ]
  }
}
