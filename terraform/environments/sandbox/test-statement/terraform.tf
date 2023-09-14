terraform {
  required_version = "1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.17.0"
    }
  }
  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-107662415716-ap-northeast-1"
    encrypt = true
    key     = "terraform-aws/terraform/environments/sandbox/sandbox-test-statement.tfstate"
    region  = "ap-northeast-1"
  }
}
