terraform {
  required_version = "1.6.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.34.0"
    }
  }
  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-577523824419-ap-northeast-1"
    encrypt = true
    key     = "terraform-aws/terraform/environments/management/management-single_sign_on.tfstate"
    region  = "ap-northeast-1"
  }
}
