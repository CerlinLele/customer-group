output "aws_region" {
  description = "AWS region being used"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

# VPC outputs
output "vpc_id" {
  description = "ID of the dedicated VPC for Glue jobs"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of public subnets in the VPC"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets for Glue jobs"
  value       = module.vpc.private_subnet_ids
}

output "glue_security_group_id" {
  description = "ID of the security group for Glue jobs"
  value       = module.vpc.glue_security_group_id
}

# S3 outputs
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

