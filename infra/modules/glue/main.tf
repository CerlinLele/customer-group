# Read and parse JSON configuration file
locals {
  # Read and decode JSON configuration
  glue_config = jsondecode(file(var.config_file_path))

  # Extract configuration sections
  glue_jobs  = local.glue_config.glue_jobs
  databases  = local.glue_config.databases
  iam_policy = local.glue_config.iam_role_policy

  # Convert jobs array to map (for for_each)
  jobs_map = {
    for job in local.glue_jobs :
    job.job_name => job
  }

  # Convert databases array to map
  databases_map = {
    for db in local.databases :
    db.database_name => db
  }

  # Process jobs: replace S3 bucket placeholder with actual bucket name
  processed_jobs = {
    for job_name, job in local.jobs_map :
    job_name => merge(job, {
      script_location = replace(job.script_location, "s3://your-bucket", "s3://${var.s3_bucket_name}")
      parameters = {
        for key, value in job.parameters :
        key => replace(value, "s3://your-bucket", "s3://${var.s3_bucket_name}")
      }
    })
  }

  # Extract job dependencies for trigger configuration
  job_dependencies = {
    for job_name, job in local.jobs_map :
    job_name => lookup(job, "dependencies", [])
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}
