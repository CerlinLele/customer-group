# IAM role outputs
output "glue_role_arn" {
  description = "ARN of the Glue IAM role"
  value       = aws_iam_role.glue_role.arn
}

output "glue_role_name" {
  description = "Name of the Glue IAM role"
  value       = aws_iam_role.glue_role.name
}

# Database outputs
output "database_names" {
  description = "Names of all Glue databases"
  value       = [for db in aws_glue_catalog_database.databases : db.name]
}

# Job outputs
output "job_names" {
  description = "Names of all Glue jobs"
  value       = [for job in aws_glue_job.jobs : job.name]
}

output "job_arns" {
  description = "ARNs of all Glue jobs"
  value       = [for job in aws_glue_job.jobs : job.arn]
}

# Trigger outputs (job-to-job dependencies only)
output "trigger_names" {
  description = "Names of job dependency triggers"
  value       = [for trigger in aws_glue_trigger.job_dependency_triggers : trigger.name]
}

# Crawler outputs
output "crawler_names" {
  description = "Names of all Glue crawlers"
  value = {
    raw_customer_base     = aws_glue_crawler.raw_customer_base.name
    raw_customer_behavior = aws_glue_crawler.raw_customer_behavior.name
  }
}

output "crawler_arns" {
  description = "ARNs of all Glue crawlers"
  value = {
    raw_customer_base     = aws_glue_crawler.raw_customer_base.arn
    raw_customer_behavior = aws_glue_crawler.raw_customer_behavior.arn
  }
}

# Summary output
output "glue_resources_summary" {
  description = "Summary of Glue resources created"
  value = {
    role_arn       = aws_iam_role.glue_role.arn
    database_count = length(aws_glue_catalog_database.databases)
    job_count      = length(aws_glue_job.jobs)
    crawler_count  = 2 # raw_customer_base and raw_customer_behavior
    trigger_count  = length(aws_glue_trigger.job_dependency_triggers)
  }
}
