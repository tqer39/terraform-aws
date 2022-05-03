provider "aws" {
  region = local.aws_region

  default_tags {
    tags = merge(local.common_tags, {
      "kkhs:source_path" = "terraform/environments/${local.env_name}/base"
    })
  }
}
