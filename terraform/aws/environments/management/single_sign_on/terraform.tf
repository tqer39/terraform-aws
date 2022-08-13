terraform {
  required_version = "=1.2.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=4.23.0"
    }
  }

  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-577523824419-ap-northeast-1"
    encrypt = true
    key     = "private-lab/terraform/aws/environments/management/management-single_sign_on.tfstate"
    region  = "ap-northeast-1"
  }
}
