provider "aws" {
  region = local.aws_region

  default_tags {
    tags = merge(local.common_tags, {
      "pl:source_path" = "terraform/environments/${local.env_name}/test-statement"
    })
  }
}
