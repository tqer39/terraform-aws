module "root_domain" {
  source = "../../../usecases/root_domain"

  domain_name = "tqer39.com"
}

# locals {
#   aws_account_id = {
#     "portfolio" = "072693953877"
#   }
# }

resource "aws_route53_record" "portfolio" {
  zone_id = module.root_domain.zone_id
  name    = "portfolio.tqer39.com"
  type    = "NS"
  ttl     = "30"
  records = data.terraform_remote_state.portfolio-domains.outputs.name_servers
}
