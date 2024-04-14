terraform {
  required_version = "1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.43.0"
    }
  }
  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
    encrypt = true
    key     = "terraform-aws/terraform/environments/portfolio/portfolio-domains.tfstate"
    region  = "ap-northeast-1"
  }
}
