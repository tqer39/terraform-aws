module "blog" {
  source = "../../modules/repository"

  name        = "blog"
  description = "blog"
  visibility  = "public"
}
