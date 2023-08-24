variable "s3_buckets" {
  description = "A map of bucket names to an object describing the S3 bucket settings for the bucket."
  type        = map(object({
    bucket                               = string
    permissions_boundary                 = string
    region                               = string
    acl                                  = optional(string)
    log_bucket_for_s3                    = string
    policies                             = list(string)
    server_side_encryption_configuration = any
    cors_configuration                   = optional(
      list(
        object({
          allowed_methods = list(string)
          allowed_origins = list(string)
          allowed_headers = optional(list(string))
          expose_headers  = optional(list(string))
          max_age_seconds = optional(number)
          id              = optional(string)
        })
      )
    )
  }))

  default = {
    main = {
      bucket                               = ""
      region                               = "ap-southeast-1"
      permissions_boundary                 = ""
      log_bucket_for_s3                    = ""
      policies                             = []
      server_side_encryption_configuration = {
        rule = {
          apply_server_side_encryption_by_default = {
            sse_algorithm = "AES256"
          }
        }
      }
    }
  }
}

variable "force_destroy" {
  description = "When destroying this user, destroy even if it has non-Terraform-managed IAM access keys, login profile or MFA devices. Without force_destroy a user with non-Terraform-managed access keys and login profile will fail to be destroyed."
  type        = bool
  default     = false
}

variable "path" {
  description = "Desired path for the IAM user"
  type        = string
  default     = "/"
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}
