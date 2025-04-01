terraform {
  required_version = "1.8.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.46.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }
  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-577523824419-ap-northeast-1"
    encrypt = true
    key     = "management/management-base.tfstate"
    region  = "ap-northeast-1"
  }
}
