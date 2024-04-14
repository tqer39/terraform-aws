/*
 * # Usage
 *
 * - GitHub Actions から AWS へアクセスするときに使用する OIDC 認証の ID Provider にアクセスする IAM ロールを作成します。
 * - [time_capsule](https://github.com/tqer39/time-capsule) 用です。
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

data "aws_iam_policy_document" "deploy_role" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::terraform-tfstate-tqer39-${var.aws_account_id}-ap-northeast-1",
      "arn:aws:s3:::terraform-tfstate-tqer39-${var.aws_account_id}-ap-northeast-1/*",
    ]
    sid = "tfstate"
  }
  statement {
    actions = [
      "amplify:CreateApp",
      "amplify:TagResource",
      "amplify:GetDomainAssociation",
      "amplify:GetBranch",
      "amplify:GetApp",
      "amplify:DeleteDomainAssociation",
      "amplify:DeleteBranch",
      "amplify:DeleteApp",
    ]
    resources = [
      "arn:aws:amplify:ap-northeast-1:${var.aws_account_id}:apps/*",
      "arn:aws:amplify:ap-northeast-1:${var.aws_account_id}:apps/d1uk05b41z81fz/branches/main",
      "arn:aws:amplify:ap-northeast-1:${var.aws_account_id}:apps/d1uk05b41z81fz",
      "arn:aws:amplify:ap-northeast-1:${var.aws_account_id}:apps/d1uk05b41z81fz/domains/time-capsule.tqer39.com",
    ]
    sid = "Amplify"
  }
  statement {
    actions = [
      "route53:CreateHostedZone",
      "route53:GetChange",
      "route53:ListHostedZones",
      "route53:GetHostedZone",
      "route53:ListTagsForResource",
      "route53:DeleteHostedZone",
      "route53:ChangeTagsForResource",
    ]
    resources = [
      "*"
    ]
    sid = "Domain"
  }
}

resource "aws_iam_policy" "deploy_policy" {
  name        = "deploy-policy"
  description = "Policy for deploy role"
  policy      = data.aws_iam_policy_document.deploy_role.json
}

resource "aws_iam_role" "this" {
  name               = "${var.aws_env_name}-${var.repository}-deploy"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [
    aws_iam_policy.deploy_policy.arn,
    data.aws_iam_policy.deploy_deny_specifics.arn,
  ]
}
