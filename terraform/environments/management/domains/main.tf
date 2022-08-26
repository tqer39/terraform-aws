module "root_domain" {
  source = "../../../usecases/root_domain"

  domain_name = "tqer39.com"
}

resource "aws_route53_record" "portfolio" {
  zone_id = module.root_domain.zone_id
  name    = "portfolio.tqer39.com"
  type    = "NS"
  ttl     = "30"
  # TODO: portfolio のアカウントから取得できるようになったらハードコーディングをやめる
  # records = data.terraform_remote_state.portfolio-domains.outputs.name_servers
  records = [
    "ns-1761.awsdns-28.co.uk.",
    "ns-958.awsdns-55.net.",
    "ns-500.awsdns-62.com.",
    "ns-1366.awsdns-42.org."
  ]
}
