terraform {
  required_version = "=1.2.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=4.23.0"
    }
  }

  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
    encrypt = true
    key     = "private-lab/terraform/aws/environments/portfolio/portfolio-base_apne1.tfstate"
    region  = "ap-northeast-1"
  }
}