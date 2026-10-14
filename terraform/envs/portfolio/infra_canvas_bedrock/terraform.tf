terraform {
  required_version = "1.16.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.68.0"
    }
  }
  backend "s3" {
    use_lockfile = true
    bucket       = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
    encrypt      = true
    key          = "terraform-aws/terraform/environments/portfolio/infra_canvas_bedrock.tfstate"
    region       = "ap-northeast-1"
  }
}
