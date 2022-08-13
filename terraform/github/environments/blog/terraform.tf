terraform {
  required_version = "=1.2.7"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "=4.28.0"
    }
  }
  cloud {
    organization = "tqer39"
    workspaces {
      name = "github_environments_blog"
    }
  }
}
