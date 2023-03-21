provider "aws" {
  region = local.region.apne1

  default_tags {
    tags = merge(local.common_tags, {
      "${local.prefix}:source_path" = "https://github.com/tqer39/private-lab/tree/main/terraform/environments/${local.aws_env_name}/test-statement"
    })
  }
}
