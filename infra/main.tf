# Get current AWS account ID
data "aws_caller_identity" "current" {}

# VPC module for Glue jobs
module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment

  # VPC CIDR configuration
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

  tags = {
    Component = "NetworkInfrastructure"
    Team      = "DataEngineering"
  }
}

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

  # VPC Configuration (using the new dedicated VPC)
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.vpc.glue_security_group_id]

  # Tags
  tags = {
    Component = "DataPipeline"
    Team      = "DataEngineering"
  }

  # Dependency: ensure S3 bucket and VPC are created first
  depends_on = [module.customer_data_bucket, module.vpc]
}
