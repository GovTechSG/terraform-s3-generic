
output "s3_buckets" {
  description = "The names of the bucket."
  value       = aws_s3_bucket.main
}

output "role" {
  description = "The role which has access to the bucket"
  value       = aws_iam_role.main
}
