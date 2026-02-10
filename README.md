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
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_guardduty_malware_protection_plan.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_malware_protection_plan) | resource |
| [aws_iam_policy.guardduty_malware_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.guardduty_malware_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.guardduty_malware_protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_cors_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_intelligent_tiering_configuration.example-entire-bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_intelligent_tiering_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_dedicated_role_creation"></a> [allow\_dedicated\_role\_creation](#input\_allow\_dedicated\_role\_creation) | Allow creation of dedicated IAM role per S3 bucket, this flag is true for all and false for none. | `bool` | `true` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | When destroying this user, destroy even if it has non-Terraform-managed IAM access keys, login profile or MFA devices. Without force\_destroy a user with non-Terraform-managed access keys and login profile will fail to be destroyed. | `bool` | `false` | no |
| <a name="input_object_lock_enabled"></a> [object\_lock\_enabled](#input\_object\_lock\_enabled) | (Optional) Enable object lock for the S3 bucket | `bool` | `false` | no |
| <a name="input_object_ownership"></a> [object\_ownership](#input\_object\_ownership) | (Optional) Object ownership. Valid values: BucketOwnerEnforced, BucketOwnerPreferred or ObjectWriter | `string` | `"BucketOwnerEnforced"` | no |
| <a name="input_path"></a> [path](#input\_path) | Desired path for the IAM user | `string` | `"/"` | no |
| <a name="input_s3_buckets"></a> [s3\_buckets](#input\_s3\_buckets) | A map of bucket names to an object describing the S3 bucket settings for the bucket. | <pre>map(object({<br/>    bucket                               = string<br/>    permissions_boundary                 = string<br/>    region                               = string<br/>    acl                                  = optional(string)<br/>    log_bucket_for_s3                    = optional(string)<br/>    object_ownership                     = optional(string)<br/>    policies                             = list(string)<br/>    server_side_encryption_configuration = any<br/>    malware_protection                   = optional(bool, false)<br/>    malware_protection_prefix            = optional(list(string))<br/>    cors_configuration = optional(<br/>      list(<br/>        object({<br/>          allowed_methods = list(string)<br/>          allowed_origins = list(string)<br/>          allowed_headers = optional(list(string))<br/>          expose_headers  = optional(list(string))<br/>          max_age_seconds = optional(number)<br/>          id              = optional(string)<br/>        })<br/>      )<br/>    )<br/>    lifecycle_rules = optional(list(object({<br/>      id      = optional(string)<br/>      enabled = optional(bool, true)<br/>      filter = optional(object({<br/>        prefix                   = optional(string)<br/>        object_size_greater_than = optional(number)<br/>        object_size_less_than    = optional(number)<br/>        tags                     = optional(map(string), {})<br/>      }))<br/>      transition = optional(list(object({<br/>        days          = optional(number)<br/>        date          = optional(string)<br/>        storage_class = string<br/>      })))<br/>      expiration = optional(object({<br/>        date                         = optional(string)<br/>        days                         = optional(number)<br/>        expired_object_delete_marker = optional(bool)<br/>      }))<br/>      noncurrent_version_expiration = optional(object({<br/>        noncurrent_days           = optional(number)<br/>        newer_noncurrent_versions = optional(number)<br/>      }))<br/>      noncurrent_version_transition = optional(list(object({<br/>        noncurrent_days           = optional(number)<br/>        newer_noncurrent_versions = optional(number)<br/>        storage_class             = string<br/>      })))<br/>      abort_incomplete_multipart_upload_days = optional(number)<br/>    })))<br/>  }))</pre> | <pre>{<br/>  "main": {<br/>    "bucket": "",<br/>    "log_bucket_for_s3": "",<br/>    "malware_protection": false,<br/>    "malware_protection_prefix": [],<br/>    "permissions_boundary": "",<br/>    "policies": [],<br/>    "region": "ap-southeast-1",<br/>    "server_side_encryption_configuration": {<br/>      "rule": {<br/>        "apply_server_side_encryption_by_default": {<br/>          "sse_algorithm": "AES256"<br/>        }<br/>      }<br/>    }<br/>  }<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role"></a> [role](#output\_role) | The role which has access to the bucket |
| <a name="output_s3_buckets"></a> [s3\_buckets](#output\_s3\_buckets) | The names of the bucket. |
<!-- END_TF_DOCS -->