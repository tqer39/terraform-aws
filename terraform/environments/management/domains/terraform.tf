terraform {
  required_version = "1.6.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.25.0"
    }
  }
  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-577523824419-ap-northeast-1"
    encrypt = true
    key     = "terraform-aws/terraform/environments/management/management-domains.tfstate"
    region  = "ap-northeast-1"
  }
}
