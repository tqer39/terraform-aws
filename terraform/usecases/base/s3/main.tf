module "s3-bucket" {
  source = "../../../modules/s3/terraform-backend"

  bucket_name = "terraform-tfstate-${var.organization}-${var.aws_account_id}-${var.aws_region}"
}
