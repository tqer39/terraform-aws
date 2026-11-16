mock_provider "aws" {}

run "private_bucket_defaults" {
  command = plan

  module {
    source = "../../terraform/modules/s3/bucket"
  }

  variables {
    aws_s3_bucket = { bucket = "offline-research-fixture" }
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.this.block_public_acls &&
      aws_s3_bucket_public_access_block.this.block_public_policy &&
      aws_s3_bucket_public_access_block.this.ignore_public_acls &&
      aws_s3_bucket_public_access_block.this.restrict_public_buckets
    )
    error_message = "既定のバケットは公開アクセスをすべて遮断する必要があります。"
  }

  assert {
    condition     = !aws_s3_bucket.this.force_destroy && !aws_s3_bucket.this.object_lock_enabled
    error_message = "既定ではオブジェクトを強制削除せず、Object Lock を有効化しません。"
  }
}
