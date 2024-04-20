/*
 * # Usage
 *
 * - デプロイ用のロールにアタッチする許可しないポリシーを作成します。
 */

data "aws_iam_policy_document" "this" {
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

resource "aws_iam_policy" "this" {
  name   = "deploy-deny-specifics"
  policy = data.aws_iam_policy_document.this.json
}
