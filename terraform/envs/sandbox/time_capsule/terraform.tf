terraform {
  required_version = "1.16.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.68.0"
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
    bucket  = "terraform-tfstate-tqer39-107662415716-ap-northeast-1"
    encrypt = true
    key     = "terraform-aws/terraform/environments/sandbox/sandbox-time_capsule.tfstate"
    region  = "ap-northeast-1"
  }
}
