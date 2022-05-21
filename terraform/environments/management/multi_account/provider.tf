provider "aws" {
  region = local.aws_region

  default_tags {
    tags = merge(local.common_tags, {
      "${local.prefix}:source_path" = "terraform/environments/${local.env_name}/multi_account"
    })
  }
}
