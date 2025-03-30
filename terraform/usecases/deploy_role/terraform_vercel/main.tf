/*
 * # Usage
 *
 * - GitHub Actions から AWS へアクセスするときに使用する OIDC 認証の ID Provider にアクセスする IAM ロールを作成します。
 * - [terraform-vercel](https://github.com/tqer39/terraform-vercel) 用です。
 */

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

data "aws_iam_policy_document" "this" {
  statement {
    sid = ""
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::terraform-tfstate-tqer39-072693953877-ap-northeast-1/terraform-vercel/*"
    ]
  }
}

resource "aws_iam_policy" "this" {
  name   = "${var.aws_env_name}-${var.repository}-deploy"
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role" "this" {
  name               = "${var.aws_env_name}-${var.repository}-deploy"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachments_exclusive" "this" {
  role = aws_iam_role.this.name
  policy_arns = [
    aws_iam_policy.this.arn,
    data.aws_iam_policy.deploy_deny_specifics.arn,
  ]
}
