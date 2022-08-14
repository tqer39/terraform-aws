resource "github_repository" "this" {
  allow_auto_merge       = lookup(var.github_repository, "allow_auto_merge", false)
  allow_merge_commit     = lookup(var.github_repository, "allow_merge_commit", true)
  allow_rebase_merge     = lookup(var.github_repository, "allow_rebase_merge", true)
  allow_squash_merge     = lookup(var.github_repository, "allow_squash_merge", true)
  archived               = lookup(var.github_repository, "archived", false)
  delete_branch_on_merge = lookup(var.github_repository, "delete_branch_on_merge", false)
  description            = lookup(var.github_repository, "description", null)
  name                   = lookup(var.github_repository, "name", null)
  visibility             = lookup(var.github_repository, "visibility", null)
}

resource "github_branch" "this" {
  repository = github_repository.this.name
  branch     = lookup(var.github_branch, "branch", null)
}

resource "github_branch_default" "this" {
  repository = github_repository.this.name
  branch     = github_branch.this.branch
}
