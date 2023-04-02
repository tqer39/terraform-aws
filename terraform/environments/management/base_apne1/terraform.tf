terraform {
  required_version = "1.4.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.61.0"
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
    bucket  = "terraform-tfstate-tqer39-577523824419-ap-northeast-1"
    encrypt = true
    key     = "terraform-aws/terraform/environments/management/management-base_apne1.tfstate"
    region  = "ap-northeast-1"
  }
}
