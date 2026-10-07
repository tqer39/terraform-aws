/*
 * # Usage
 *
 * - GitHub Actions から AWS へアクセスするときに使用する OIDC 認証の ID Provider にアクセスする IAM ロールを作成します。
 * - [terraform-aws](https://github.com/tqer39/terraform-aws) 用です。
 */

data "aws_iam_policy" "deploy_allow_specifics" {
  name = "deploy-allow-specifics"
}

data "aws_iam_policy" "deploy_deny_specifics" {
  name = "deploy-deny-specifics"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com",
      ]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.organization}/${var.repository}:*",
      ]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.aws_env_name}-${var.repository}-deploy"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachments_exclusive" "this" {
  role_name = aws_iam_role.this.name
  policy_arns = [
    data.aws_iam_policy.deploy_allow_specifics.arn,
    data.aws_iam_policy.deploy_deny_specifics.arn,
  ]
}
