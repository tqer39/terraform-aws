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
      "arn:aws:bedrock:ap-northeast-1::foundation-model/amazon.nova-lite-v1:0",
    ])
    error_message = "対象は東京の Nova Lite モデルだけです。"
  }
  assert {
    condition = alltrue([
      for statement in jsondecode(aws_iam_role_policy.infra_canvas_bedrock.policy).Statement :
      statement.Condition.StringEquals["aws:RequestedRegion"] == "ap-northeast-1"
    ])
    error_message = "東京以外のリージョンでの呼び出しを許可してはいけません。"
  }
  assert {
    condition = (length(jsondecode(aws_iam_role.infra_canvas_bedrock.assume_role_policy).Statement) == 1 &&
      jsondecode(aws_iam_role.infra_canvas_bedrock.assume_role_policy).Statement[0].Action == "sts:AssumeRole" &&
      jsondecode(aws_iam_role.infra_canvas_bedrock.assume_role_policy).Statement[0].Principal.AWS == "arn:aws:iam::072693953877:root" &&
    jsondecode(aws_iam_role.infra_canvas_bedrock.assume_role_policy).Statement[0].Condition.ArnLike["aws:PrincipalArn"] == "arn:aws:iam::072693953877:role/aws-reserved/sso.amazonaws.com/ap-northeast-1/AWSReservedSSO_AdministratorAccess_*")
    error_message = "引受元は Portfolio の既存 SSO 管理者ロールだけです。"
  }
}
