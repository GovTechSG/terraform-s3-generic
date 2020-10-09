
resource "aws_s3_bucket" "main" {
  for_each = var.s3_buckets

  bucket = each.value.bucket
  acl    = each.value.acl
  policy = each.value.policy

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = each.value.log_bucket_for_s3
    target_prefix = "s3/${each.value.bucket}/"
  }
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
