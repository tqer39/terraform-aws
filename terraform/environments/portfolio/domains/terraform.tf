terraform {
  required_version = "=1.2.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=4.29.0"
    }
  }

  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
    encrypt = true
    key     = "private-lab/terraform/environments/portfolio/portfolio-domains.tfstate"
    region  = "ap-northeast-1"
  }
}