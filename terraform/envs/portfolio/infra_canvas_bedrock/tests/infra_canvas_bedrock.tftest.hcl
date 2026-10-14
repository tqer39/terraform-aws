mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_data "aws_iam_policy" {
    defaults = { arn = "arn:aws:iam::123456789012:policy/example" }
  }
}

run "bedrock_access_is_scoped" {
  command = plan

  assert {
    condition = alltrue([
      for statement in jsondecode(aws_iam_role_policy.infra_canvas_bedrock.policy).Statement :
      statement.Effect == "Allow" && statement.Action == ["bedrock:InvokeModel"]
    ])
    error_message = "推論以外の操作・ストリーミング・管理権限を許可してはいけません。"
  }
  assert {
    condition = toset(flatten([
      for statement in jsondecode(aws_iam_role_policy.infra_canvas_bedrock.policy).Statement : statement.Resource
      ])) == toset([
      "arn:aws:bedrock:ap-northeast-1:072693953877:inference-profile/global.openai.gpt-5.6-luna",
      "arn:aws:bedrock:ap-northeast-1:072693953877:project/default",
      "arn:aws:bedrock:ap-northeast-1::foundation-model/openai.gpt-5.6-luna",
      "arn:aws:bedrock:::foundation-model/openai.gpt-5.6-luna",
    ])
    error_message = "対象は東京の Luna プロファイル・default project と Luna モデルだけです。"
  }
  assert {
    condition = alltrue([
      for statement in jsondecode(aws_iam_role_policy.infra_canvas_bedrock.policy).Statement :
      !strcontains(statement.Resource[0], "foundation-model/") ||
      try(statement.Condition.StringEquals["bedrock:InferenceProfileArn"], "") == "arn:aws:bedrock:ap-northeast-1:072693953877:inference-profile/global.openai.gpt-5.6-luna"
    ])
    error_message = "モデルを直接呼ばせず、指定プロファイル経由に限定してください。"
  }
  assert {
    condition = alltrue([
      for statement in jsondecode(aws_iam_role_policy.infra_canvas_bedrock.policy).Statement :
      statement.Condition.StringEquals["aws:RequestedRegion"] ==
      (startswith(statement.Resource[0], "arn:aws:bedrock:::foundation-model/") ? "unspecified" : "ap-northeast-1")
    ])
    error_message = "接続先は東京、global の内部処理だけを unspecified に限定してください。"
  }
  assert {
    condition = (length(jsondecode(aws_iam_role.infra_canvas_bedrock.assume_role_policy).Statement) == 1 &&
      jsondecode(aws_iam_role.infra_canvas_bedrock.assume_role_policy).Statement[0].Action == "sts:AssumeRole" &&
      jsondecode(aws_iam_role.infra_canvas_bedrock.assume_role_policy).Statement[0].Principal.AWS == "arn:aws:iam::072693953877:root" &&
    jsondecode(aws_iam_role.infra_canvas_bedrock.assume_role_policy).Statement[0].Condition.ArnLike["aws:PrincipalArn"] == "arn:aws:iam::072693953877:role/aws-reserved/sso.amazonaws.com/ap-northeast-1/AWSReservedSSO_AdministratorAccess_*")
    error_message = "引受元は Portfolio の既存 SSO 管理者ロールだけです。"
  }
}
