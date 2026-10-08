module "root_domain" {
  source = "../../../modules/domain"

  domain_name = "tqer39.dev"
}

module "root_certificate" {
  source = "../../../modules/certificate"

  domain_name = "tqer39.dev"
}
