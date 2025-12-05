# Get current AWS account ID
data "aws_caller_identity" "current" {}

# S3 bucket module for storing customer data
module "customer_data_bucket" {
  source = "./modules/s3_bucket"

  bucket_name = "${var.project_name}-${var.environment}-data-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-data-bucket"
    Description = "Bucket for storing customer data files"
  }
}

# Glue ETL pipeline module for customer data processing
module "glue_pipeline" {
  source = "./modules/glue"

  # JSON configuration file path
  config_file_path = "${path.root}/../glue_scripts/config/glue_jobs_config.json"

  # S3 bucket configuration (from S3 module)
  s3_bucket_name = module.customer_data_bucket.bucket_id
  s3_bucket_arn  = module.customer_data_bucket.bucket_arn

  # Environment configuration
  environment  = var.environment
  project_name = var.project_name

  # Glue configuration
  glue_role_name            = "GlueCustomerDataRole"
  enable_job_bookmarks      = true
  enable_continuous_logging = true

  # Tags
  tags = {
    Component = "DataPipeline"
    Team      = "DataEngineering"
  }

  # Dependency: ensure S3 bucket is created first
  depends_on = [module.customer_data_bucket]
}
