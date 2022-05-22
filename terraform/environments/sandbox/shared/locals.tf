locals {
  aws_account_id = "107662415716"
  env_name       = "sandbox"
  organization   = "tqer39"
  platform       = "aws"
  prefix         = "pl"
  region = {
    apne1 = "ap-northeast-1"
    use1  = "us-east-1"
  }
  repository = "private-lab"
}

locals {
  common_tags = {
    "${local.prefix}:environment" = local.env_name
    "${local.prefix}:iac"         = "terraform"
    "${local.prefix}:owner"       = "${local.organization}+${local.platform}-${local.env_name}@gmail.com"
    "${local.prefix}:product"     = "private-lab"
    "${local.prefix}:repository"  = "${local.organization}/${local.repository}"
  }

  tfstate_bucket_name = {
    apne1 = "terraform-tfstate-${local.organization}-${local.aws_account_id}-${local.region.apne1}"
    use1  = "terraform-tfstate-${local.organization}-${local.aws_account_id}-${local.region.use1}"
  }
}
