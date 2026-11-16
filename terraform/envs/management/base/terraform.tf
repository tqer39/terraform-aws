terraform {
  required_version = "1.17.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.72.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.6.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.4.2"
    }
  }
  backend "s3" {
    use_lockfile = true
    bucket       = "terraform-tfstate-tqer39-577523824419-ap-northeast-1"
    encrypt      = true
    key          = "management/management-base.tfstate"
    region       = "ap-northeast-1"
  }
}
