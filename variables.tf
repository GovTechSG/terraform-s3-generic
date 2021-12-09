variable "s3_buckets" {
  description = "A map of bucket names to an object describing the S3 bucket settings for the bucket."
  type = map(object({
    bucket                               = string
    permissions_boundary                 = string
    region                               = string
    acl                                  = string
    log_bucket_for_s3                    = string
    server_side_encryption_configuration = any
  }))

  default = {
    main = {
      bucket               = ""
      region               = "ap-southeast-1"
      permissions_boundary = ""
      acl                  = "private"
      log_bucket_for_s3    = ""
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

variable "policies" {
  description = "Custom bucket policies to be merged with default policy from this module."
  type        = list(any)
  default     = []
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
