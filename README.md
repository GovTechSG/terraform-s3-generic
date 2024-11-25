# s3-generic

Creates a s3 bucket with policies to allow using it, for attaching to other roles/users
## Example

```hcl
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
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | When destroying this user, destroy even if it has non-Terraform-managed IAM access keys, login profile or MFA devices. Without force\_destroy a user with non-Terraform-managed access keys and login profile will fail to be destroyed. | `bool` | `false` | no |
| <a name="input_path"></a> [path](#input\_path) | Desired path for the IAM user | `string` | `"/"` | no |
| <a name="input_s3_buckets"></a> [s3\_buckets](#input\_s3\_buckets) | A map of bucket names to an object describing the S3 bucket settings for the bucket. | <pre>map(object({ </br>    bucket                               = string </br>    permissions_boundary                 = string </br>    region                               = string </br>    acl                                  = optional(string) </br>    log_bucket_for_s3                    = optional(string) </br>    policies                             = list(string) </br>    server_side_encryption_configuration = any </br>    cors_configuration = optional( </br>      list( </br>        object({ </br>          allowed_methods = list(string) </br>          allowed_origins = list(string) </br>          allowed_headers = optional(list(string)) </br>          expose_headers  = optional(list(string)) </br>          max_age_seconds = optional(number) </br>          id              = optional(string) </br>        }) </br>      ) </br>    ) </br>    lifecycle_rules = optional(list(object({ </br>      id      = optional(string) </br>      enabled = optional(bool, true) </br>      filter = optional(object({ </br>        prefix                   = optional(string) </br>        object_size_greater_than = optional(number) </br>        object_size_less_than    = optional(number) </br>        tags                     = optional(map(string)) </br>      })) </br>      transition = optional(list(object({ </br>        days          = optional(number) </br>        date          = optional(string) </br>        storage_class = string </br>      }))) </br>    }))) </br>  })) </br></pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role"></a> [role](#output\_role) | The role which has access to the bucket |
| <a name="output_s3_buckets"></a> [s3\_buckets](#output\_s3\_buckets) | The names of the bucket. |
