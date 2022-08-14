module "blog" {
  source = "../../modules/repository"

  github_repository = {
    name           = "blog"
    default_branch = "main"
    description    = "blog"
    visibility     = "public"
  }

  github_branch = {
    branch = "main"
  }
}
