# GitHub Actions の場合
terraform {
  required_version = "=1.2.7"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "=4.30.0"
    }
  }

  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-577523824419-ap-northeast-1"
    encrypt = true
    key     = "private-lab/terraform/github/environments/blog.tfstate"
    region  = "ap-northeast-1"
  }
}

# Terraform Cloud の場合
# terraform {
#   required_version = "=1.2.7"
#   required_providers {
#     github = {
#       source  = "integrations/github"
#       version = "=4.28.0"
#     }
#   }
#   cloud {
#     organization = "tqer39"
#     workspaces {
#       name = "github_environments_blog"
#     }
#   }
# }
