resource "aws_codecommit_repository" "this" {
  repository_name = lookup(var.aws_codecommit_repository, "repository_name", null)
  description     = lookup(var.aws_codecommit_repository, "description", null)
  default_branch  = lookup(var.aws_codecommit_repository, "default_branch", null)
  tags            = lookup(var.aws_codecommit_repository, "tags", null)
}
