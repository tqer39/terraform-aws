terraform {
  required_version = "=1.2.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=4.15.1"
    }
  }

  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-107662415716-ap-northeast-1"
    encrypt = true
    key     = "private-lab/terraform/environments/sandbox/sandbox-test-statement.tfstate"
    region  = "ap-northeast-1"
  }
}
