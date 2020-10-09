# s3-generic

Creates a s3 bucket with policies to allow using it, for attaching to other roles/users

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| force\_destroy | When destroying this user, destroy even if it has non-Terraform-managed IAM access keys, login profile or MFA devices. Without force\_destroy a user with non-Terraform-managed access keys and login profile will fail to be destroyed. | `bool` | `false` | no |
| path | Desired path for the IAM user | `string` | `"/"` | no |
| s3\_buckets | A map of bucket names to an object describing the S3 bucket settings for the bucket. | <pre>map(object({<br>    bucket               = string<br>    permissions_boundary = string<br>    region               = string<br>    acl                  = string<br>    policy               = string<br>    log_bucket_for_s3    = string<br>  }))</pre> | <pre>{<br>  "main": {<br>    "acl": "private",<br>    "bucket": "",<br>    "log_bucket_for_s3": "",<br>    "permissions_boundary": "",<br>    "policy": "",<br>    "region": "ap-southeast-1"<br>  }<br>}</pre> | no |
| tags | (Optional) A mapping of tags to assign to the bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| role | The role which has access to the bucket |
| s3\_buckets | The names of the bucket. |

