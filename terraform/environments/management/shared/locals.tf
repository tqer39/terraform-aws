locals {
  aws_account_id = "577523824419"
  aws_region     = "ap-northeast-1"
  env_name       = "management"
  organization   = "tqer39"
  platform       = "aws"
  repository     = "private-lab"
}

locals {
  common_tags = {
    "pl:environment" = local.env_name
    "pl:iac"         = "terraform"
    "pl:owner"       = "${local.organization}+${local.platform}-${local.env_name}@gmail.com"
    "pl:product"     = "private-lab"
    "pl:repository"  = "${local.organization}/${local.repository}"
  }

  tfstate_bucket_name = "terraform-tfstate-${local.organization}-${local.aws_account_id}-${local.aws_region}"
}
