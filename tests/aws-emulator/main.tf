terraform {
  required_version = "1.17.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.72.0"
    }
  }
}

variable "endpoint" {
  type = string
  validation {
    condition     = can(regex("^https://127\\.0\\.0\\.1:[0-9]+$", var.endpoint))
    error_message = "AWS Emulator のループバック HTTPS endpoint だけを指定してください。"
  }
}

variable "credentials_file" {
  type = string
}

variable "ca_bundle" {
  type = string
}

provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = [var.credentials_file]
  shared_config_files      = []
  custom_ca_bundle         = var.ca_bundle
  skip_metadata_api_check  = true
  max_retries              = 1
  allowed_account_ids      = ["000000000000"]
  endpoints {
    dynamodb = var.endpoint
    sqs      = var.endpoint
    sts      = var.endpoint
  }
}

data "aws_caller_identity" "emulator" {}

resource "aws_dynamodb_table" "research" {
  name         = "terraform-aws-emulator-research"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
}

data "aws_dynamodb_table" "readback" {
  name = aws_dynamodb_table.research.name
}

resource "aws_sqs_queue" "research" {
  name = "terraform-aws-emulator-research"
}

data "aws_sqs_queue" "readback" {
  name       = aws_sqs_queue.research.name
  depends_on = [aws_sqs_queue.research]
}
