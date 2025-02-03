data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "main" {
  for_each = var.s3_buckets

  statement {
    sid = "DenyInsecureTransportProtocol"

    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${each.value.bucket}",
      "arn:aws:s3:::${each.value.bucket}/*"
    ]
    effect = "Deny"

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  override_policy_documents = tolist(each.value.policies)
}

resource "aws_s3_bucket" "main" {
  for_each = var.s3_buckets

  bucket = each.value.bucket

  object_lock_enabled = var.object_lock_enabled

  tags = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  for_each = var.s3_buckets

  bucket = each.value.bucket

  dynamic "rule" {
    for_each = length(keys(lookup(each.value.server_side_encryption_configuration, "rule", {}))) == 0 ? [] : [lookup(each.value.server_side_encryption_configuration, "rule", {})]

    content {
      bucket_key_enabled = lookup(rule.value, "bucket_key_enabled", null)

      dynamic "apply_server_side_encryption_by_default" {
        for_each = length(keys(lookup(rule.value, "apply_server_side_encryption_by_default", {}))) == 0 ? [] : [
        lookup(rule.value, "apply_server_side_encryption_by_default", {})]

        content {
          sse_algorithm     = apply_server_side_encryption_by_default.value.sse_algorithm
          kms_master_key_id = lookup(apply_server_side_encryption_by_default.value, "kms_master_key_id", null)
        }
      }
    }
  }
}

resource "aws_s3_bucket_logging" "main" {
  for_each = { for key, value in var.s3_buckets : key => value if value.log_bucket_for_s3 != "" }

  bucket = each.value.bucket

  target_bucket = each.value.log_bucket_for_s3
  target_prefix = "s3/${each.value.bucket}/"
}

resource "aws_s3_bucket_ownership_controls" "main" {
  # Enforce bucket ownership for For buckets that don't have ACL enabled
  for_each = { for key, value in var.s3_buckets : key => value if value.acl == null }

  bucket = each.value.bucket
  depends_on = [
    aws_s3_bucket.main
  ]

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_acl" "main" {
  for_each = { for key, value in var.s3_buckets : key => value if value.acl != null }

  bucket = each.value.bucket
  acl    = each.value.acl
}

resource "aws_s3_bucket_versioning" "main" {

  for_each = var.s3_buckets

  bucket = each.value.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "main" {
  depends_on = [
    aws_s3_bucket.main
  ]

  for_each = var.s3_buckets

  bucket = aws_s3_bucket.main[each.key].id
  policy = data.aws_iam_policy_document.main[each.key].json
}

resource "aws_s3_bucket_public_access_block" "main" {
  depends_on = [
    aws_s3_bucket.main
  ]

  for_each = var.s3_buckets

  bucket                  = each.value.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "example-entire-bucket" {
  depends_on = [
    aws_s3_bucket.main
  ]

  for_each = var.s3_buckets
  name     = "${each.value.bucket}-intelligent-tiering"
  bucket   = each.value.bucket

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 125
  }
}

resource "aws_s3_bucket_cors_configuration" "main" {
  depends_on = [
    aws_s3_bucket.main
  ]
  for_each = { for key, value in var.s3_buckets : key => value if value.cors_configuration != null }
  bucket   = each.value.bucket

  dynamic "cors_rule" {
    for_each = each.value.cors_configuration
    content {
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      allowed_headers = try(cors_rule.value.allowed_headers, null)
      expose_headers  = try(cors_rule.value.expose_headers, null)
      max_age_seconds = try(cors_rule.value.max_age_seconds, null)
      id              = try(cors_rule.value.id, null)
    }
  }
}

###################################################################
# IAM Role and Policy
###################################################################

resource "aws_iam_role" "main" {
  for_each = var.s3_buckets

  name = "${each.value.bucket}-role"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "s3.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
  })
  permissions_boundary = each.value.permissions_boundary
}

resource "aws_iam_role_policy" "main" {
  for_each = var.s3_buckets

  name = "${each.value.bucket}-policy"
  role = aws_iam_role.main[each.key].name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "S3",
        "Action" : [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::${each.value.bucket}",
          "arn:aws:s3:::${each.value.bucket}/*"
        ]
      }
    ]
  })
}

###################################################################
# Lifecycle Config 
###################################################################

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  # Only create lifecycle rules for buckets that have them defined
  for_each = {
    for key, value in var.s3_buckets : key => value
    if try(length(value.lifecycle_rules), 0) > 0
  }

  bucket                = each.value.bucket
  expected_bucket_owner = data.aws_caller_identity.current.account_id

  dynamic "rule" {
    for_each = each.value.lifecycle_rules

    content {
      id = coalesce(try(rule.value.id, null), "rule-${rule.key}")
      status = coalesce(
        try(rule.value.enabled ? "Enabled" : "Disabled", null),
        try(tobool(rule.value.status) ? "Enabled" : "Disabled", null),
        try(title(lower(rule.value.status)), null),
        "Enabled"
      )

      # Abort incomplete multipart uploads
      dynamic "abort_incomplete_multipart_upload" {
        for_each = try(rule.value.abort_incomplete_multipart_upload_days != null ? [rule.value.abort_incomplete_multipart_upload_days] : [], [])

        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }

      # Object expiration rules
      dynamic "expiration" {
        for_each = try(rule.value.expiration != null ? [rule.value.expiration] : [], [])

        content {
          date                         = try(expiration.value.date, null)
          days                         = try(expiration.value.days, null)
          expired_object_delete_marker = try(expiration.value.expired_object_delete_marker, null)
        }
      }

      # Object transition rules
      dynamic "transition" {
        for_each = try(rule.value.transition != null ? rule.value.transition : [], [])

        content {
          date          = try(transition.value.date, null)
          days          = try(transition.value.days, null)
          storage_class = transition.value.storage_class
        }
      }

      # Non-current version expiration
      dynamic "noncurrent_version_expiration" {
        for_each = try(rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : [], [])

        content {
          newer_noncurrent_versions = try(noncurrent_version_expiration.value.newer_noncurrent_versions, null)
          noncurrent_days = coalesce(
            try(noncurrent_version_expiration.value.days, null),
            try(noncurrent_version_expiration.value.noncurrent_days, null)
          )
        }
      }

      # Non-current version transition
      dynamic "noncurrent_version_transition" {
        for_each = try(rule.value.noncurrent_version_transition != null ? rule.value.noncurrent_version_transition : [], [])

        content {
          newer_noncurrent_versions = try(noncurrent_version_transition.value.newer_noncurrent_versions, null)
          noncurrent_days = coalesce(
            try(noncurrent_version_transition.value.days, null),
            try(noncurrent_version_transition.value.noncurrent_days, null)
          )
          storage_class = noncurrent_version_transition.value.storage_class
        }
      }

      # Empty filter 
      dynamic "filter" {
        for_each = length(try(flatten([rule.value.filter]), [])) == 0 ? [true] : []

        content {
        }
      }

      # Single condition filter (no "and" block needed)
      dynamic "filter" {
        for_each = [for v in try(flatten([rule.value.filter]), []) : v if(
          length(compact([
            try(v.prefix, null),
            try(v.object_size_greater_than, null),
            try(v.object_size_less_than, null)
          ])) <= 1 &&
          length(try(flatten([v.tags, v.tag]), [])) <= 1
        )]

        content {
          object_size_greater_than = try(filter.value.object_size_greater_than, null)
          object_size_less_than    = try(filter.value.object_size_less_than, null)
          prefix                   = try(filter.value.prefix, null)

          dynamic "tag" {
            for_each = try(flatten([filter.value.tags, filter.value.tag]), [])
            content {
              key   = try(tag.value.key, null)
              value = try(tag.value.value, null)
            }
          }
        }
      }

      # Multiple conditions filter (requires "and" block)
      dynamic "filter" {
        for_each = [for v in try(flatten([rule.value.filter]), []) : v if(
          length(compact([
            try(v.prefix, null),
            try(v.object_size_greater_than, null),
            try(v.object_size_less_than, null)
          ])) > 1 ||
          length(try(flatten([v.tags, v.tag]), [])) > 1
        )]

        content {
          and {
            object_size_greater_than = try(filter.value.object_size_greater_than, null)
            object_size_less_than    = try(filter.value.object_size_less_than, null)
            prefix                   = try(filter.value.prefix, null)
            tags                     = try(filter.value.tags, filter.value.tag, null)
          }
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]

  lifecycle {
    precondition {
      condition     = can(aws_s3_bucket_versioning.main[each.key].versioning_configuration[0].status == "Enabled")
      error_message = "S3 bucket versioning must be enabled to use lifecycle rules with version-specific actions."
    }
  }
}