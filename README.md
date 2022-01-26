# s3-generic

Creates a s3 bucket with policies to allow using it, for attaching to other roles/users
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
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_s3_bucket.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_iam_policy_document.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | When destroying this user, destroy even if it has non-Terraform-managed IAM access keys, login profile or MFA devices. Without force\_destroy a user with non-Terraform-managed access keys and login profile will fail to be destroyed. | `bool` | `false` | no |
| <a name="input_path"></a> [path](#input\_path) | Desired path for the IAM user | `string` | `"/"` | no |
| <a name="input_s3_buckets"></a> [s3\_buckets](#input\_s3\_buckets) | A map of bucket names to an object describing the S3 bucket settings for the bucket. | <pre>map(object({<br>    bucket                               = string<br>    permissions_boundary                 = string<br>    region                               = string<br>    acl                                  = string<br>    log_bucket_for_s3                    = string<br>    policies                             = list(string)<br>    server_side_encryption_configuration = any<br>  }))</pre> | <pre>{<br>  "main": {<br>    "acl": "private",<br>    "bucket": "",<br>    "log_bucket_for_s3": "",<br>    "permissions_boundary": "",<br>    "policies": [],<br>    "region": "ap-southeast-1",<br>    "server_side_encryption_configuration": {<br>      "rule": {<br>        "apply_server_side_encryption_by_default": {<br>          "sse_algorithm": "AES256"<br>        }<br>      }<br>    }<br>  }<br>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role"></a> [role](#output\_role) | The role which has access to the bucket |
| <a name="output_s3_buckets"></a> [s3\_buckets](#output\_s3\_buckets) | The names of the bucket. |


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
| <a name="input_s3_buckets"></a> [s3\_buckets](#input\_s3\_buckets) | A map of bucket names to an object describing the S3 bucket settings for the bucket. | <pre>map(object({<br>    bucket                               = string<br>    permissions_boundary                 = string<br>    region                               = string<br>    acl                                  = string<br>    log_bucket_for_s3                    = string<br>    policies                             = list(string)<br>    server_side_encryption_configuration = any<br>  }))</pre> | <pre>{<br>  "main": {<br>    "acl": "private",<br>    "bucket": "",<br>    "log_bucket_for_s3": "",<br>    "permissions_boundary": "",<br>    "policies": [],<br>    "region": "ap-southeast-1",<br>    "server_side_encryption_configuration": {<br>      "rule": {<br>        "apply_server_side_encryption_by_default": {<br>          "sse_algorithm": "AES256"<br>        }<br>      }<br>    }<br>  }<br>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role"></a> [role](#output\_role) | The role which has access to the bucket |
| <a name="output_s3_buckets"></a> [s3\_buckets](#output\_s3\_buckets) | The names of the bucket. |

