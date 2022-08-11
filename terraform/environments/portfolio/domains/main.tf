module "root_domain" {
  source = "../../../usecases/root_domain"

  domain_name = "portfolio.tqer39.com"
}

module "certificate" {
  source = "../../../usecases/certificate"

  domain_name = "portfolio.tqer39.com"
}
