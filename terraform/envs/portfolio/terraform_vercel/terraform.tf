terraform {
  required_version = "1.16.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.67.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.6.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.4.1"
    }
  }
  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
    encrypt = true
    key     = "terraform-aws/terraform/environments/portfolio/portfolio-terraform_vercel.tfstate"
    region  = "ap-northeast-1"
  }
}
