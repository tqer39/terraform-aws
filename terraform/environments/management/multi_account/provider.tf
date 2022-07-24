provider "aws" {
  region = local.region.apne1

  default_tags {
    tags = merge(local.common_tags, {
      "${local.prefix}:source_path" = "https://github.com/tqer39/private-lab/terraform/environments/${local.env_name}/multi_account"
    })
  }
}
