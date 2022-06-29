provider "aws" {
  region = local.region.apne1

  default_tags {
    tags = merge(local.common_tags, {
      "${local.prefix}:source_path" = "terraform/environments/${local.env_name}/base_apne1"
    })
  }
}
