
data "aws_iam_policy_document" "main" {
  for_each = var.s3_buckets

  statement {
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
  for_each = var.s3_buckets

  bucket = each.value.bucket

  target_bucket = each.value.log_bucket_for_s3
  target_prefix = "s3/${each.value.bucket}/"
}

resource "aws_s3_bucket_acl" "main" {
  for_each = var.s3_buckets

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

###################################################################
# IAM Role and Policy
###################################################################

resource "aws_iam_role" "main" {
  for_each = var.s3_buckets

  name = "${each.value.bucket}-role"

  assume_role_policy   = <<POLICY
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "s3.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
POLICY
  permissions_boundary = each.value.permissions_boundary
}

resource "aws_iam_role_policy" "main" {
  for_each = var.s3_buckets

  name = "${each.value.bucket}-policy"
  role = aws_iam_role.main[each.key].name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${each.value.bucket}",
        "arn:aws:s3:::${each.value.bucket}/*"
      ]
    }
  ]
}
POLICY
}
