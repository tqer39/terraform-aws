run "service_lifecycle" {
  command = apply

  assert {
    condition     = data.aws_caller_identity.emulator.account_id == "000000000000"
    error_message = "接続先は AWS Emulator のアカウントである必要があります。"
  }

  assert {
    condition     = data.aws_dynamodb_table.readback.arn == aws_dynamodb_table.research.arn
    error_message = "作成した DynamoDB テーブルを API 経由で読み戻せませんでした。"
  }

  assert {
    condition     = data.aws_sqs_queue.readback.arn == aws_sqs_queue.research.arn
    error_message = "作成した SQS キューを API 経由で読み戻せませんでした。"
  }
}
