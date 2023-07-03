module "s3-generic" {
  source = "../..//"
  s3_buckets = {
    backups = {
      bucket                    = "my-backups"
      permissions_boundary      = "arn:aws:iam::${get_aws_account_id()}:policy/MyBoundary"
      region                    = "ap-southeast-1"
      acl                       = "private"
      log_bucket_for_s3         = "my-access-logs"
      lifecycle_prevent_destroy = true
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
    }
  }
}
