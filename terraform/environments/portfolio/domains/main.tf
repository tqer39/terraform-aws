module "root_domain" {
  source = "../../../usecases/domain"

  domain_name = "tqer39.dev"
}

module "root_certificate" {
  source = "../../../usecases/certificate"

  domain_name = "*.tqer39.dev"
}

module "portfolio_domain" {
  source = "../../../usecases/domain"

  domain_name = "portfolio.tqer39.com"
}
