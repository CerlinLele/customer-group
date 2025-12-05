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
  value       = module.customer_data_bucket.bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for customer data"
  value       = module.customer_data_bucket.bucket_arn
}

# Glue IAM role outputs
output "glue_role_arn" {
  description = "ARN of the Glue IAM role"
  value       = module.glue_pipeline.glue_role_arn
}

output "glue_role_name" {
  description = "Name of the Glue IAM role"
  value       = module.glue_pipeline.glue_role_name
}

# Glue resources outputs
output "glue_databases" {
  description = "List of Glue database names"
  value       = module.glue_pipeline.database_names
}

output "glue_jobs" {
  description = "List of Glue job names"
  value       = module.glue_pipeline.job_names
}

output "glue_job_arns" {
  description = "List of Glue job ARNs"
  value       = module.glue_pipeline.job_arns
}

output "glue_triggers" {
  description = "List of job dependency trigger names"
  value       = module.glue_pipeline.trigger_names
}

# Glue resources summary
output "glue_resources_summary" {
  description = "Summary of Glue resources created"
  value       = module.glue_pipeline.glue_resources_summary
}

