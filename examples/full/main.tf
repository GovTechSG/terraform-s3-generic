module "s3-generic" {
  source = "../..//"
  s3_buckets = {
    backups = {
      bucket               = "my-backups"
      permissions_boundary = "arn:aws:iam::${get_aws_account_id()}:policy/MyBoundary"
      region               = "ap-southeast-1"
      acl                  = "private"
      log_bucket_for_s3    = "my-access-logs"
      policies = [jsonencode(
        {
          "Version" : "2012-10-17",
          "Statement" : [
            {
              Action : "s3:GetBucketAcl",
              Effect : "Allow",
              Resource : "arn:aws:s3:::my-backups",
              Principal : { "Service" : "logs.ap-southeast-1.amazonaws.com" }
            },
            {
              Action : "s3:PutObject",
              Effect : "Allow",
              Resource : "arn:aws:s3:::my-backups/**",
              Condition : { "StringEquals" : { "s3:x-amz-acl" : "bucket-owner-full-control" } },
              Principal : { "Service" : "logs.ap-southeast-1.amazonaws.com" }
            }
          ]
        }
      )]
      server_side_encryption_configuration = {
        rule = {
          bucket_key_enabled = true
          apply_server_side_encryption_by_default = {
            sse_algorithm = "aws:kms"
          }
        }
      }
      lifecycle_rules = [
        {
          id      = "backup-lifecycle-rule"
          enabled = true
          filter = {
            object_size_greater_than = 0
          }
          transition = [
            {
              days          = 30
              storage_class = "STANDARD_IA"
            },
            {
              days          = 60
              storage_class = "GLACIER"
            },
            {
              days          = 150
              storage_class = "DEEP_ARCHIVE"
            }
          ]
          noncurrent_version_transition = [
            {
              noncurrent_days = 30
              storage_class   = "STANDARD_IA"
            },
            {
              noncurrent_days = 60
              storage_class   = "GLACIER"
            },
            {
              noncurrent_days = 150
              storage_class   = "DEEP_ARCHIVE"
            }
          ]
          expiration = {
            days = 183
          }
          noncurrent_version_expiration = {
            noncurrent_days = 151
          }
        }
      ]
    }
  }
}
