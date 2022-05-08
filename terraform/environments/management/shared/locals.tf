locals {
  aws_account_id = "577523824419"
  aws_region     = "ap-northeast-1"
  env_name       = "management"
  organization   = "tqer39"
  platform       = "aws"
  repository     = "private-lab"
  prefix         = "pl"
}

locals {
  common_tags = {
    "${local.prefix}:environment" = local.env_name
    "${local.prefix}:iac"         = "terraform"
    "${local.prefix}:owner"       = "${local.organization}+${local.platform}-${local.env_name}@gmail.com"
    "${local.prefix}:product"     = "private-lab"
    "${local.prefix}:repository"  = "${local.organization}/${local.repository}"
  }

  tfstate_bucket_name = "terraform-tfstate-${local.organization}-${local.aws_account_id}-${local.aws_region}"
}
