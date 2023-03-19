module "tfstate_s3_bucket" {
  source = "../../../usecases/terraform_tfstate_bucket"

  bucket_name = local.tfstate_bucket_name.apne1
}

module "deploy_role" {
  source = "../../../usecases/deploy_role/terraform_aws"

  aws_account_id = local.aws_account_id
  env_name       = local.env_name
  organization   = local.organization
  repository     = local.repository
  sso_role_arns  = ["arn:aws:iam::${local.aws_account_id}:role/SSO-AdministratorAccess-APNE1"]
  depends_on = [
    aws_iam_policy.deploy_allow_specifics,
    aws_iam_policy.deploy_deny_specifics,
  ]
}

module "oidc_github_actions_id_provider" {
  source = "../../../usecases/id_provider"
}

data "aws_iam_policy_document" "deploy_allow_specifics" {
  statement {
    sid = "AllowSpecifics"
    actions = [
      "lambda:*",
      "apigateway:*",
      "ec2:*",
      "rds:*",
      "s3:*",
      "sns:*",
      "states:*",
      "ssm:*",
      "sqs:*",
      "iam:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "cloudfront:*",
      "route53:*",
      "ecr:*",
      "logs:*",
      "ecs:*",
      "application-autoscaling:*",
      "events:*",
      "elasticache:*",
      "es:*",
      "kms:*",
      "dynamodb:*",
      "kinesis:*",
      "firehose:*",
      "elasticbeanstalk:*",
      "cloudformation:*",
      "acm:*",
      "organizations:*",
      "sso:*",
      "identitystore:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "deploy_allow_specifics" {
  name   = "deploy-allow-specifics"
  policy = data.aws_iam_policy_document.deploy_allow_specifics.json
}

data "aws_iam_policy_document" "deploy_deny_specifics" {
  statement {
    actions = [
      "iam:*Login*",
      "iam:*Group*",
      "aws-portal:*",
      "budgets:*",
      "config:*",
      "directconnect:*",
      "aws-marketplace:*",
      "aws-marketplace-management:*",
      "ec2:*ReservedInstances*"
    ]
    effect    = "Deny"
    resources = ["*"]
    sid       = "DenySpecifics"
  }
}

resource "aws_iam_policy" "deploy_deny_specifics" {
  name   = "deploy-deny-specifics"
  policy = data.aws_iam_policy_document.deploy_deny_specifics.json
}
