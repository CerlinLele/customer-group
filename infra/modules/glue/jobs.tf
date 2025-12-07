# Create Glue Jobs
resource "aws_glue_job" "jobs" {
  for_each = local.processed_jobs

  name              = each.value.job_name
  role_arn          = aws_iam_role.glue_role.arn
  description       = lookup(each.value, "description", "")
  glue_version      = each.value.glue_version
  max_retries       = each.value.max_retries
  timeout           = each.value.timeout
  worker_type       = each.value.worker_type
  number_of_workers = lookup(each.value, "max_capacity", 2)

  # Command configuration
  command {
    name            = each.value.job_type
    script_location = each.value.script_location
    python_version  = "3"
  }

  # Default arguments: merge JSON parameters with Terraform standard parameters
  default_arguments = merge(
    each.value.parameters,
    {
      "--job-language"                     = "python"
      "--enable-metrics"                   = "true"
      "--enable-spark-ui"                  = "true"
      "--spark-event-logs-path"            = "s3://${var.s3_bucket_name}/logs/spark-logs/"
      "--enable-job-insights"              = "true"
      "--enable-glue-datacatalog"          = "true"
      "--enable-continuous-cloudwatch-log" = var.enable_continuous_logging ? "true" : "false"
      "--job-bookmark-option"              = var.enable_job_bookmarks ? "job-bookmark-enable" : "job-bookmark-disable"
      "--TempDir"                          = "s3://${var.s3_bucket_name}/temp/"
    },
    length(var.subnet_ids) > 0 ? {
      "--subnet-id"             = join(",", var.subnet_ids)
      "--security-group-id"     = join(",", var.security_group_ids)
      "--availability-zone"     = "auto"
    } : {}
  )

  # Execution property
  execution_property {
    max_concurrent_runs = 1
  }

  # Security configuration for encryption and VPC
  security_configuration = length(var.subnet_ids) > 0 ? aws_glue_security_configuration.vpc_security[0].name : null

  # VPC configuration via execution class - CRITICAL for executor connection issues
  execution_class = length(var.subnet_ids) > 0 ? "FLEX" : "STANDARD"

  tags = merge(
    var.tags,
    {
      Name = each.value.job_name
    }
  )

  depends_on = [
    aws_iam_role_policy.glue_policy,
    aws_iam_role_policy_attachment.glue_service_role,
    aws_glue_catalog_database.databases
  ]
}

# Note: VPC configuration is applied via security configuration and job properties
# See security.tf for security group and vpc_config resource
