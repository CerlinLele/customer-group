output "aws_region" {
  description = "AWS region being used"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for customer data"
  value       = aws_s3_bucket.customer_data.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for customer data"
  value       = aws_s3_bucket.customer_data.arn
}

output "s3_bucket_region" {
  description = "Region of the S3 bucket"
  value       = aws_s3_bucket.customer_data.region
}
