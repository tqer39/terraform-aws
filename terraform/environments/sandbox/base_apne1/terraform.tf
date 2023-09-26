terraform {
  required_version = "1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.18.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
  }
  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-107662415716-ap-northeast-1"
    encrypt = true
    key     = "terraform-aws/terraform/environments/sandbox/sandbox-base_apne1.tfstate"
    region  = "ap-northeast-1"
  }
}
