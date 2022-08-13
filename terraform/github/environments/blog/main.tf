module "blog" {
  source = "../../modules/repository"

  github_repository = {
    name        = "blog"
    description = "blog"
    visibility  = "public"
  }
}
