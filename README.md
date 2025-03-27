# s3-generic

Creates a s3 bucket with policies to allow using it, for attaching to other roles/users
## Example

```hcl
module "s3-generic" {
  source = "../..//"
  object_ownership = "BucketOwnerEnforced" # Optional, defaults to BucketOwnerEnforced
  s3_buckets = {
    backups = {
      bucket               = "my-backups"
      permissions_boundary = "arn:aws:iam::${get_aws_account_id()}:policy/MyBoundary"
      region               = "ap-southeast-1"
      acl                  = "private"
      object_ownership     = "BucketOwnerPreferred" # Optional, overrides the module-level setting
      log_bucket_for_s3    = "my-access-logs"
      malware_protection   = true                   # Optional, enables GuardDuty Malware Protection for this bucket
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

## Features

### GuardDuty Malware Protection

When `malware_protection = true` is set for a bucket, this module will:

1. Create a dedicated IAM role with the appropriate permissions for GuardDuty to scan objects
2. Configure an AWS GuardDuty Malware Protection Plan to monitor the bucket
3. Enable object tagging to mark scanned objects

The IAM role follows the principle of least privilege with permissions based on AWS recommended policies for GuardDuty Malware Protection.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | When destroying this user, destroy even if it has non-Terraform-managed IAM access keys, login profile or MFA devices. Without force\_destroy a user with non-Terraform-managed access keys and login profile will fail to be destroyed. | `bool` | `false` | no |
| <a name="input_path"></a> [path](#input\_path) | Desired path for the IAM user | `string` | `"/"` | no |
| <a name="input_s3_buckets"></a> [s3\_buckets](#input\_s3\_buckets) | A map of bucket names to an object describing the S3 bucket settings for the bucket. | <pre>map(object({ </br>    bucket                               = string </br>    permissions_boundary                 = string </br>    region                               = string </br>    acl                                  = optional(string) </br>    log_bucket_for_s3                    = optional(string) </br>    object_ownership                     = optional(string) </br>    malware_protection                   = optional(bool, false) </br>    policies                             = list(string) </br>    server_side_encryption_configuration = any </br>    cors_configuration = optional( </br>      list( </br>        object({ </br>          allowed_methods = list(string) </br>          allowed_origins = list(string) </br>          allowed_headers = optional(list(string)) </br>          expose_headers  = optional(list(string)) </br>          max_age_seconds = optional(number) </br>          id              = optional(string) </br>        }) </br>      ) </br>    ) </br>    lifecycle_rules = optional(list(object({ </br>      id      = optional(string) </br>      enabled = optional(bool, true) </br>      filter = optional(object({ </br>        prefix                   = optional(string) </br>        object_size_greater_than = optional(number) </br>        object_size_less_than    = optional(number) </br>        tags                     = optional(map(string)) </br>      })) </br>      transition = optional(list(object({ </br>        days          = optional(number) </br>        date          = optional(string) </br>        storage_class = string </br>      }))) </br>    }))) </br>  })) </br></pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the bucket. | `map(string)` | `{}` | no |
| <a name="input_object_ownership"></a> [object\_ownership](#input\_object\_ownership) | (Optional) Default object ownership setting for all buckets. Can be overridden at the bucket level using the `object_ownership` property in the bucket configuration. Valid values: BucketOwnerEnforced, BucketOwnerPreferred or ObjectWriter | `string` | `"BucketOwnerEnforced"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role"></a> [role](#output\_role) | The role which has access to the bucket |
| <a name="output_s3_buckets"></a> [s3_buckets](#output\_s3_buckets) | The names of the bucket. |

<!-- BEGIN_TF_DOCS -->


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
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | When destroying this user, destroy even if it has non-Terraform-managed IAM access keys, login profile or MFA devices. Without force\_destroy a user with non-Terraform-managed access keys and login profile will fail to be destroyed. | `bool` | `false` | no |
| <a name="input_object_lock_enabled"></a> [object\_lock\_enabled](#input\_object\_lock\_enabled) | (Optional) Enable object lock for the S3 bucket | `bool` | `false` | no |
| <a name="input_object_ownership"></a> [object\_ownership](#input\_object\_ownership) | (Optional) Object ownership. Valid values: BucketOwnerEnforced, BucketOwnerPreferred or ObjectWriter | `string` | `"BucketOwnerEnforced"` | no |
| <a name="input_path"></a> [path](#input\_path) | Desired path for the IAM user | `string` | `"/"` | no |
| <a name="input_s3_buckets"></a> [s3\_buckets](#input\_s3\_buckets) | A map of bucket names to an object describing the S3 bucket settings for the bucket. | <pre>map(object({<br/>    bucket                               = string<br/>    permissions_boundary                 = string<br/>    region                               = string<br/>    acl                                  = optional(string)<br/>    log_bucket_for_s3                    = optional(string)<br/>    object_ownership                     = optional(string)<br/>    policies                             = list(string)<br/>    server_side_encryption_configuration = any<br/>    malware_protection                   = optional(bool, false)<br/>    malware_protection_prefix            = optional(list(string))<br/>    cors_configuration = optional(<br/>      list(<br/>        object({<br/>          allowed_methods = list(string)<br/>          allowed_origins = list(string)<br/>          allowed_headers = optional(list(string))<br/>          expose_headers  = optional(list(string))<br/>          max_age_seconds = optional(number)<br/>          id              = optional(string)<br/>        })<br/>      )<br/>    )<br/>    lifecycle_rules = optional(list(object({<br/>      id      = optional(string)<br/>      enabled = optional(bool, true)<br/>      filter = optional(object({<br/>        prefix                   = optional(string)<br/>        object_size_greater_than = optional(number)<br/>        object_size_less_than    = optional(number)<br/>        tags                     = optional(map(string))<br/>      }))<br/>      transition = optional(list(object({<br/>        days          = optional(number)<br/>        date          = optional(string)<br/>        storage_class = string<br/>      })))<br/>      expiration = optional(object({<br/>        date                         = optional(string)<br/>        days                         = optional(number)<br/>        expired_object_delete_marker = optional(bool)<br/>      }))<br/>      noncurrent_version_expiration = optional(object({<br/>        noncurrent_days           = optional(number)<br/>        newer_noncurrent_versions = optional(number)<br/>      }))<br/>      noncurrent_version_transition = optional(list(object({<br/>        noncurrent_days           = optional(number)<br/>        newer_noncurrent_versions = optional(number)<br/>        storage_class             = string<br/>      })))<br/>      abort_incomplete_multipart_upload_days = optional(number)<br/>    })))<br/>  }))</pre> | <pre>{<br/>  "main": {<br/>    "bucket": "",<br/>    "log_bucket_for_s3": "",<br/>    "malware_protection": false,<br/>    "malware_protection_prefix": [],<br/>    "permissions_boundary": "",<br/>    "policies": [],<br/>    "region": "ap-southeast-1",<br/>    "server_side_encryption_configuration": {<br/>      "rule": {<br/>        "apply_server_side_encryption_by_default": {<br/>          "sse_algorithm": "AES256"<br/>        }<br/>      }<br/>    }<br/>  }<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role"></a> [role](#output\_role) | The role which has access to the bucket |
| <a name="output_s3_buckets"></a> [s3\_buckets](#output\_s3\_buckets) | The names of the bucket. |
<!-- END_TF_DOCS -->