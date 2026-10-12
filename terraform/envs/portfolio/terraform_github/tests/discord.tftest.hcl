mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_data "aws_iam_policy" {
    defaults = { arn = "arn:aws:iam::123456789012:policy/example" }
  }
}

run "discord_roles_are_scoped" {
  command = plan

  assert {
    condition     = jsondecode(aws_iam_role.discord["apply"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == ["repo:tqer39/kazokubi:ref:refs/heads/main"]
    error_message = "apply は main だけを信頼する必要があります。"
  }
  assert {
    condition     = jsondecode(aws_iam_role.discord["plan"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == ["repo:tqer39/kazokubi:pull_request", "repo:tqer39/kazokubi:ref:refs/heads/main"]
    error_message = "plan は同一リポジトリの PR と main だけを信頼する必要があります。"
  }
  assert {
    condition     = alltrue([for role in aws_iam_role.discord : jsondecode(role.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:aud"] == "sts.amazonaws.com"])
    error_message = "OIDC audience は STS に限定してください。"
  }
  assert {
    condition = alltrue([
      for policy in aws_iam_role_policy.discord :
      toset(jsondecode(policy.policy).Statement[0].Condition.StringEquals["s3:prefix"]) == toset([
        "kazokubi/infra/discord.tfstate",
        "kazokubi/infra/discord-workspaces/",
      ])
    ])
    error_message = "両ロールで Terraform が送る末尾 / 付きの workspace prefix と専用 state だけを許可してください。"
  }
  assert {
    condition     = flatten([for statement in jsondecode(aws_iam_role_policy.discord["plan"].policy).Statement : statement.Action]) == ["s3:ListBucket", "s3:GetObject"]
    error_message = "plan ロールに書き込みを許可してはいけません。"
  }
  assert {
    condition     = jsondecode(aws_iam_role_policy.discord["apply"].policy).Statement[1].Action == ["s3:GetObject", "s3:PutObject"] && endswith(jsondecode(aws_iam_role_policy.discord["apply"].policy).Statement[1].Resource[0], "/kazokubi/infra/discord.tfstate") && endswith(jsondecode(aws_iam_role_policy.discord["apply"].policy).Statement[2].Resource[0], "/kazokubi/infra/discord.tfstate.tflock")
    error_message = "state を削除せず、ロックだけを削除可能にしてください。"
  }
}
