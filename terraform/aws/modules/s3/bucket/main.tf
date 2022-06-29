resource "aws_s3_bucket" "this" {
  bucket              = lookup(var.aws_s3_bucket, "bucket", "")
  force_destroy       = lookup(var.aws_s3_bucket, "force_destroy", false)
  object_lock_enabled = lookup(var.aws_s3_bucket, "object_lock_enabled", false)
  tags                = lookup(var.aws_s3_bucket, "tags", {})
}

resource "aws_s3_bucket_acl" "this" {
  count                 = var.aws_s3_bucket_acl == null ? 0 : 1
  bucket                = aws_s3_bucket.this.id
  acl                   = lookup(var.aws_s3_bucket_acl, "acl", null)
  expected_bucket_owner = lookup(var.aws_s3_bucket_acl, "expected_bucket_owner", null)
  dynamic "access_control_policy" {
    for_each = lookup(var.aws_s3_bucket_acl, "access_control_policy", [])
    content {
      dynamic "grant" {
        for_each = lookup(access_control_policy.value, "grant", [])
        content {
          dynamic "grantee" {
            for_each = lookup(grant.value, "grantee", [])
            content {
              email_address = lookup(grantee.value, "email_address", null)
              id            = lookup(grantee.value, "id", null)
              type          = lookup(grantee.value, "type", null)
              uri           = lookup(grantee.value, "uri", null)
            }
          }
          permission = lookup(grant.value, "permission", null)
        }
      }
      dynamic "owner" {
        for_each = lookup(access_control_policy.value, "owner", [])
        content {
          display_name = lookup(owner.value, "display_name", null)
          id           = lookup(owner.value, "id", null)
        }
      }
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "this" {
  count                 = var.aws_s3_bucket_cors_configuration == null ? 0 : 1
  bucket                = aws_s3_bucket.this.id
  expected_bucket_owner = lookup(var.aws_s3_bucket_cors_configuration, "expected_bucket_owner", null)
  dynamic "cors_rule" {
    for_each = lookup(var.aws_s3_bucket_cors_configuration, "cors_rule", [])
    content {
      allowed_headers = lookup(cors_rule.value, "allowed_headers", null)
      allowed_methods = lookup(cors_rule.value, "allowed_methods", null)
      allowed_origins = lookup(cors_rule.value, "allowed_origins", null)
      expose_headers  = lookup(cors_rule.value, "expose_headers", null)
      id              = lookup(cors_rule.value, "id", null)
      max_age_seconds = lookup(cors_rule.value, "max_age_seconds", null)
    }
  }
}

resource "aws_s3_bucket_inventory" "this" {
  count                    = var.aws_s3_bucket_inventory == null ? 0 : 1
  bucket                   = aws_s3_bucket.this.id
  name                     = lookup(var.aws_s3_bucket_inventory, "name", null)
  enabled                  = lookup(var.aws_s3_bucket_inventory, "enabled", null)
  included_object_versions = lookup(var.aws_s3_bucket_inventory, "included_object_versions", null)
  optional_fields          = lookup(var.aws_s3_bucket_inventory, "optional_fields", null)
  dynamic "schedule" {
    for_each = lookup(var.aws_s3_bucket_inventory, "schedule", [])
    content {
      frequency = lookup(schedule.value, "frequency", null)
    }
  }
  dynamic "filter" {
    for_each = lookup(var.aws_s3_bucket_inventory, "filter", [])
    content {
      prefix = lookup(filter.value, "prefix", null)
    }
  }
  dynamic "destination" {
    for_each = lookup(var.aws_s3_bucket_inventory, "destination", [])
    content {
      dynamic "bucket" {
        for_each = lookup(destination.value, "bucket", [])
        content {
          account_id = lookup(bucket.value, "account_id", null)
          bucket_arn = lookup(bucket.value, "bucket_arn", null)
          format     = lookup(bucket.value, "format", null)
          prefix     = lookup(bucket.value, "prefix", null)
          dynamic "encryption" {
            for_each = lookup(bucket.value, "encryption", [])
            content {

              dynamic "sse_s3" {
                for_each = lookup(encryption.value, "sse_s3", [])
                content {
                }
              }
              dynamic "sse_kms" {
                for_each = lookup(encryption.value, "sse_kms", [])
                content {
                  key_id = lookup(sse_kms.value, "key_id", null)
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count                 = var.aws_s3_bucket_lifecycle_configuration == null ? 0 : 1
  bucket                = aws_s3_bucket.this.bucket
  expected_bucket_owner = lookup(var.aws_s3_bucket_lifecycle_configuration, "expected_bucket_owner", null)
  dynamic "rule" {
    for_each = lookup(var.aws_s3_bucket_lifecycle_configuration, "rule", [])
    content {
      dynamic "abort_incomplete_multipart_upload" {
        for_each = lookup(rule.value, "abort_incomplete_multipart_upload", [])
        content {
          days_after_initiation = lookup(abort_incomplete_multipart_upload.value, "days_after_initiation", null)
        }
      }
      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration", [])
        content {
          date                         = lookup(expiration.value, "date", null)
          days                         = lookup(expiration.value, "days", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }
      dynamic "filter" {
        for_each = lookup(rule.value, "filter", [])
        content {
          dynamic "and" {
            for_each = lookup(filter.value, "and", [])
            content {
              object_size_greater_than = lookup(and.value, "object_size_greater_than", null)
              object_size_less_than    = lookup(and.value, "object_size_less_than", null)
              prefix                   = lookup(and.value, "prefix", null)
              tags                     = lookup(and.value, "tags", null)
            }
          }
          object_size_greater_than = lookup(filter.value, "object_size_greater_than", null)
          object_size_less_than    = lookup(filter.value, "object_size_less_than", null)
          prefix                   = lookup(filter.value, "prefix", null)
          dynamic "tag" {
            for_each = lookup(filter.value, "tag", [])
            content {
              key   = lookup(tag.value, "key", null)
              value = lookup(tag.value, "value", null)
            }
          }
        }
      }
      id = lookup(rule.value, "id")
      dynamic "noncurrent_version_expiration" {
        for_each = lookup(rule.value, "noncurrent_version_expiration", [])
        content {
          newer_noncurrent_versions = lookup(noncurrent_version_expiration.value, "newer_noncurrent_versions", null)
          noncurrent_days           = lookup(noncurrent_version_expiration.value, "noncurrent_days", null)
        }
      }
      dynamic "noncurrent_version_transition" {
        for_each = lookup(rule.value, "noncurrent_version_transition", [])
        content {
          newer_noncurrent_versions = lookup(noncurrent_version_transition.value, "newer_noncurrent_versions", null)
          noncurrent_days           = lookup(noncurrent_version_transition.value, "noncurrent_days", null)
          storage_class             = lookup(noncurrent_version_transition.value, "storage_class", null)
        }
      }
      prefix = lookup(rule.value, "prefix", null)
      status = lookup(rule.value, "status", null)
      dynamic "transition" {
        for_each = lookup(rule.value, "transition", [])
        content {
          date          = lookup(transition.value, "date", null)
          days          = lookup(transition.value, "days", null)
          storage_class = lookup(transition.value, "storage_class", null)
        }
      }
    }
  }
}

resource "aws_s3_bucket_logging" "this" {
  count                 = var.aws_s3_bucket_logging == null ? 0 : 1
  bucket                = aws_s3_bucket.this.id
  expected_bucket_owner = lookup(var.aws_s3_bucket_logging, "expected_bucket_owner", null)
  target_bucket         = lookup(var.aws_s3_bucket_logging, "target_bucket", null)
  target_prefix         = lookup(var.aws_s3_bucket_logging, "target_prefix", null)
  dynamic "target_grant" {
    for_each = lookup(var.aws_s3_bucket_logging, "target_grant", [])
    content {
      dynamic "grantee" {
        for_each = lookup(target_grant.value, "grantee", [])
        content {
          email_address = lookup(grantee.value, "email_address", null)
          id            = lookup(grantee.value, "id", null)
          type          = lookup(grantee.value, "type", null)
          uri           = lookup(grantee.value, "uri", null)
        }
      }
      permission = lookup(target_grant.value, "permission", null)
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count                   = var.aws_s3_bucket_public_access_block == null ? 0 : 1
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = lookup(var.aws_s3_bucket_public_access_block, "block_public_acls", true)
  block_public_policy     = lookup(var.aws_s3_bucket_public_access_block, "block_public_policy", true)
  ignore_public_acls      = lookup(var.aws_s3_bucket_public_access_block, "ignore_public_acls", true)
  restrict_public_buckets = lookup(var.aws_s3_bucket_public_access_block, "restrict_public_buckets", true)
}

resource "aws_s3_bucket_policy" "this" {
  count  = var.aws_s3_bucket_policy == null ? 0 : 1
  bucket = aws_s3_bucket.this.id
  policy = lookup(var.aws_s3_bucket_policy, "policy", null)
}

resource "aws_s3_bucket_replication_configuration" "this" {
  count  = var.aws_s3_bucket_replication_configuration == null ? 0 : 1
  bucket = aws_s3_bucket.this.id
  role   = lookup(var.aws_s3_bucket_replication_configuration, "role", null)
  dynamic "rule" {
    for_each = lookup(var.aws_s3_bucket_replication_configuration, "rule", [])
    content {
      dynamic "delete_marker_replication" {
        for_each = lookup(rule.value, "delete_marker_replication", [])
        content {
          status = lookup(delete_marker_replication.value, "status", null)
        }
      }
      dynamic "destination" {
        for_each = lookup(rule.value, "destination", [])
        content {
          dynamic "access_control_translation" {
            for_each = lookup(destination.value, "access_control_translation", [])
            content {
              owner = lookup(access_control_translation.value, "owner", null)
            }
          }
          account = lookup(destination.value, "account", null)
          bucket  = lookup(destination.value, "bucket", null)
          dynamic "encryption_configuration" {
            for_each = lookup(destination.value, "encryption_configuration", [])
            content {
              replica_kms_key_id = lookup(encryption_configuration.value, "replica_kms_key_id", null)
            }
          }
          dynamic "metrics" {
            for_each = lookup(destination.value, "metrics", [])
            content {
              dynamic "event_threshold" {
                for_each = lookup(metrics.value, "event_threshold", [])
                content {
                  minutes = lookup(event_threshold.value, "minutes", null)
                }
              }
              status = lookup(metrics.value, "status", null)
            }
          }
          dynamic "replication_time" {
            for_each = lookup(destination.value, "replication_time", [])
            content {
              status = lookup(replication_time.value, "status", null)
              dynamic "time" {
                for_each = lookup(replication_time.value, "time", [])
                content {
                  minutes = lookup(time.value, "minutes", null)
                }
              }
            }
          }
          storage_class = lookup(destination.value, "storage_class", null)
        }
      }
      dynamic "existing_object_replication" {
        for_each = lookup(rule.value, "existing_object_replication", [])
        content {
          status = lookup(existing_object_replication.value, "status", null)
        }
      }
      dynamic "filter" {
        for_each = lookup(rule.value, "filter", [])
        content {
          dynamic "and" {
            for_each = lookup(filter.value, "and", [])
            content {
              prefix = lookup(and.value, "prefix", null)
              tags   = lookup(and.value, "tags", null)
            }
          }
          prefix = lookup(filter.value, "prefix", null)
          dynamic "tag" {
            for_each = lookup(filter.value, "tag", [])
            content {
              key   = lookup(tag.value, "key", null)
              value = lookup(tag.value, "value", null)
            }
          }
        }
      }
      id       = lookup(rule.value, "id", null)
      prefix   = lookup(rule.value, "prefix", null)
      priority = lookup(rule.value, "priority", null)
      dynamic "source_selection_criteria" {
        for_each = lookup(rule.value, "source_selection_criteria", [])
        content {
          dynamic "replica_modifications" {
            for_each = lookup(source_selection_criteria.value, "replica_modifications", null)
            content {
              status = lookup(replica_modifications.value, "status", null)
            }
          }
          dynamic "sse_kms_encrypted_objects" {
            for_each = lookup(source_selection_criteria.value, "sse_kms_encrypted_objects", null)
            content {
              status = lookup(sse_kms_encrypted_objects.value, "status", null)
            }
          }
        }
      }
      status = lookup(rule.value, "status", null)
    }
  }
  depends_on = [
    aws_s3_bucket_versioning.this
  ]
}

resource "aws_s3_bucket_request_payment_configuration" "this" {
  count                 = var.aws_s3_bucket_request_payment_configuration == null ? 0 : 1
  bucket                = aws_s3_bucket.this.id
  payer                 = lookup(var.aws_s3_bucket_request_payment_configuration, "payer", null)
  expected_bucket_owner = lookup(var.aws_s3_bucket_request_payment_configuration, "expected_bucket_owner", null)
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.aws_s3_bucket_server_side_encryption_configuration == null ? 0 : 1
  bucket = aws_s3_bucket.this.id
  dynamic "rule" {
    for_each = lookup(var.aws_s3_bucket_server_side_encryption_configuration, "rule", [])
    content {
      dynamic "apply_server_side_encryption_by_default" {
        for_each = lookup(rule.value, "apply_server_side_encryption_by_default", [])
        content {
          sse_algorithm     = lookup(apply_server_side_encryption_by_default.value, "sse_algorithm", null)
          kms_master_key_id = lookup(apply_server_side_encryption_by_default.value, "kms_master_key_id", null)
        }
      }
      bucket_key_enabled = lookup(rule.value, "bucket_key_enabled", null)
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.aws_s3_bucket_versioning == null ? 0 : 1
  bucket = aws_s3_bucket.this.id
  dynamic "versioning_configuration" {
    for_each = lookup(var.aws_s3_bucket_versioning, "versioning_configuration", [])
    content {
      status     = lookup(versioning_configuration.value, "status", null)
      mfa_delete = lookup(versioning_configuration.value, "mfa_delete", null)
    }
  }
}

resource "aws_s3_bucket_website_configuration" "this" {
  count                 = var.aws_s3_bucket_website_configuration == null ? 0 : 1
  bucket                = aws_s3_bucket.this.id
  expected_bucket_owner = lookup(var.aws_s3_bucket_website_configuration, "expected_bucket_owner", null)
  dynamic "index_document" {
    for_each = lookup(var.aws_s3_bucket_website_configuration, "index_document", [])
    content {
      suffix = lookup(index_document.value, "suffix", null)
    }
  }
  dynamic "error_document" {
    for_each = lookup(var.aws_s3_bucket_website_configuration, "error_document", [])
    content {
      key = lookup(error_document.value, "key", null)
    }
  }
  dynamic "routing_rule" {
    for_each = lookup(var.aws_s3_bucket_website_configuration, "routing_rule", [])
    content {
      dynamic "condition" {

        for_each = lookup(routing_rule.value, "condition", )
        content {
          key_prefix_equals = lookup(condition.value, "key_prefix_equals", null)
        }
      }
      dynamic "redirect" {

        for_each = lookup(routing_rule.value, "redirect", [])
        content {
          replace_key_prefix_with = lookup(redirect.value, "replace_key_prefix_with", null)
        }
      }
    }
  }
  dynamic "redirect_all_requests_to" {
    for_each = lookup(var.aws_s3_bucket_website_configuration, "redirect_all_requests_to", [])
    content {
      host_name = lookup(redirect_all_requests_to.value, "host_name", null)
      protocol  = lookup(redirect_all_requests_to.value, "protocol", null)
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count  = var.aws_s3_bucket_ownership_controls == null ? 0 : 1
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = lookup(var.aws_s3_bucket_ownership_controls, "rule", [])
    content {
      object_ownership = lookup(rule.value, "object_ownership", null)
    }
  }
}
