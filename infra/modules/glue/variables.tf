variable "config_file_path" {
  description = "Path to the Glue configuration JSON file"
  type        = string
  default     = "../../glue_scripts/config/glue_jobs_config.json"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for Glue scripts and data"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for IAM policies"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "glue_role_name" {
  description = "Name for the Glue IAM role"
  type        = string
  default     = "GlueCustomerDataRole"
}

variable "enable_job_bookmarks" {
  description = "Enable Glue job bookmarks for incremental processing"
  type        = bool
  default     = true
}

variable "enable_continuous_logging" {
  description = "Enable continuous logging for Glue jobs"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
