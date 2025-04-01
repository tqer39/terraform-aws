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
    bucket  = "terraform-tfstate-tqer39-107662415716-ap-northeast-1"
    encrypt = true
    key     = "terraform-aws/terraform/environments/sandbox/sandbox-time_capsule.tfstate"
    region  = "ap-northeast-1"
  }
}
