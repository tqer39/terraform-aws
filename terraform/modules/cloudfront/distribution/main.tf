resource "aws_cloudfront_distribution" "this" {
  aliases = lookup(var.aws_cloudfront_distribution, "aliases", null)
  comment = lookup(var.aws_cloudfront_distribution, "comment", null)
  dynamic "default_cache_behavior" {
    for_each = lookup(var.aws_cloudfront_distribution, "default_cache_behavior", [])
    content {
      allowed_methods = lookup(default_cache_behavior.value, "allowed_methods", ["GET", "HEAD"])
      cache_policy_id = lookup(default_cache_behavior.value, "cache_policy_id", null)
      cached_methods  = lookup(default_cache_behavior.value, "cached_methods", ["GET", "HEAD"])
      compress        = lookup(default_cache_behavior.value, "compress", true)
      default_ttl     = lookup(default_cache_behavior.value, "default_ttl", null)
      dynamic "forwarded_values" {
        for_each = lookup(default_cache_behavior.value, "forwarded_values", [])
        content {
          cookies {
            forward = lookup(forwarded_values.value, "cookies.forward", null)
          }
          headers      = lookup(forwarded_values.value, "headers", null)
          query_string = lookup(forwarded_values.value, "query_string", null)
        }
      }
      max_ttl                = lookup(default_cache_behavior.value, "max_ttl", 0)
      min_ttl                = lookup(default_cache_behavior.value, "min_ttl", 0)
      smooth_streaming       = lookup(default_cache_behavior.value, "smooth_streaming", null)
      target_origin_id       = lookup(default_cache_behavior.value, "target_origin_id", null)
      trusted_key_groups     = lookup(default_cache_behavior.value, "trusted_key_groups", null)
      viewer_protocol_policy = lookup(default_cache_behavior.value, "viewer_protocol_policy", null)
    }
  }
  default_root_object = lookup(var.aws_cloudfront_distribution, "default_root_object", "index.html")
  enabled             = lookup(var.aws_cloudfront_distribution, "enabled", true)
  http_version        = lookup(var.aws_cloudfront_distribution, "http_version", "http2")
  is_ipv6_enabled     = lookup(var.aws_cloudfront_distribution, "is_ipv6_enabled", true)
  dynamic "logging_config" {
    for_each = lookup(var.aws_cloudfront_distribution, "logging_config", [])
    content {
      bucket          = lookup(logging_config.value, "bucket", null)
      include_cookies = lookup(logging_config.value, "include_cookies", null)
      prefix          = lookup(logging_config.value, "prefix", null)
    }
  }
  dynamic "origin" {
    for_each = lookup(var.aws_cloudfront_distribution, "origin", [])
    content {
      connection_attempts = lookup(origin.value, "connection_attempts", 3)
      connection_timeout  = lookup(origin.value, "connection_timeout", 10)
      domain_name         = lookup(origin.value, "domain_name", null)
      origin_id           = lookup(origin.value, "origin_id", null)
      dynamic "s3_origin_config" {
        for_each = lookup(origin.value, "s3_origin_config", [])
        content {
          origin_access_identity = lookup(s3_origin_config.value, "origin_access_identity", null)
        }
      }
    }
  }
  dynamic "ordered_cache_behavior" {
    for_each = lookup(var.aws_cloudfront_distribution, "ordered_cache_behavior", [])
    content {
      allowed_methods = lookup(ordered_cache_behavior.value, "allowed_methods", null)
      cache_policy_id = lookup(ordered_cache_behavior.value, "cache_policy_id", null)
      cached_methods  = lookup(ordered_cache_behavior.value, "cached_methods", null)
      compress        = lookup(ordered_cache_behavior.value, "compress", true)
      default_ttl     = lookup(ordered_cache_behavior.value, "default_ttl", 0)
      dynamic "forwarded_values" {
        for_each = lookup(ordered_cache_behavior.value, "forwarded_values", [])
        content {
          cookies {
            forward = lookup(forwarded_values.value, "cookies.forward", null)
          }
          headers      = lookup(forwarded_values.value, "headers", null)
          query_string = lookup(forwarded_values.value, "query_string", null)
        }
      }
      max_ttl                = lookup(ordered_cache_behavior.value, "max_ttl", 0)
      min_ttl                = lookup(ordered_cache_behavior.value, "min_ttl", 0)
      path_pattern           = lookup(ordered_cache_behavior.value, "path_pattern", null)
      smooth_streaming       = lookup(ordered_cache_behavior.value, "smooth_streaming", false)
      target_origin_id       = lookup(ordered_cache_behavior.value, "target_origin_id", null)
      trusted_key_groups     = lookup(ordered_cache_behavior.value, "trusted_key_groups", null)
      viewer_protocol_policy = lookup(ordered_cache_behavior.value, "viewer_protocol_policy", null)
    }
  }
  price_class = lookup(var.aws_cloudfront_distribution, "price_class", null)
  dynamic "restrictions" {
    for_each = lookup(var.aws_cloudfront_distribution, "restrictions", [])
    content {
      dynamic "geo_restriction" {
        for_each = lookup(restrictions.value, "geo_restriction", [])
        content {
          locations        = lookup(geo_restriction.value, "locations", [])
          restriction_type = lookup(geo_restriction.value, "restriction_type", "none")
        }
      }
    }
  }
  retain_on_delete = lookup(var.aws_cloudfront_distribution, "retain_on_delete", null)
  dynamic "viewer_certificate" {
    for_each = lookup(var.aws_cloudfront_distribution, "viewer_certificate", [])
    content {
      acm_certificate_arn            = lookup(viewer_certificate.value, "acm_certificate_arn", null)
      cloudfront_default_certificate = lookup(viewer_certificate.value, "cloudfront_default_certificate", null)
      iam_certificate_id             = lookup(viewer_certificate.value, "iam_certificate_id", null)
      minimum_protocol_version       = lookup(viewer_certificate.value, "minimum_protocol_version", "TLSv1.2_2021")
      ssl_support_method             = lookup(viewer_certificate.value, "ssl_support_method", "sni-only")
    }
  }
}
