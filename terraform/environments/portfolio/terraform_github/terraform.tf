terraform {
  required_version = "1.4.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.64.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.0.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.1"
    }
  }
  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
    encrypt = true
    key     = "terraform-aws/terraform/environments/portfolio/portfolio-terraform_github.tfstate"
    region  = "ap-northeast-1"
  }
}
