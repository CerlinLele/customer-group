# S3 objects for uploading source data files
# This configuration uploads CSV files to the raw data layer after S3 bucket is created
# Compatible with AWS provider >= 5.45

# Create raw data directory structure (folder placeholder)
resource "aws_s3_object" "raw_folder" {
  bucket       = module.customer_data_bucket.bucket_id
  key          = "raw/"
  content_type = "application/x-directory"

  tags = {
    Name        = "Raw data directory"
    Description = "Directory for raw customer data files"
  }

  depends_on = [module.customer_data_bucket]
}

# Upload customer_base.csv to S3
resource "aws_s3_object" "customer_base_csv" {
  bucket = module.customer_data_bucket.bucket_id
  key    = "raw/customer_base.csv"
  source = "${path.root}/../customer_base.csv"

  # Use etag to detect file changes
  etag = filemd5("${path.root}/../customer_base.csv")

  # Set content type
  content_type = "text/csv"

  # Storage class for cost optimization
  storage_class = "STANDARD"

  tags = {
    Name        = "Customer Base Data"
    Description = "Source data: customer basic information"
  }

  depends_on = [aws_s3_object.raw_folder]
}

# Upload customer_behavior_assets.csv to S3
resource "aws_s3_object" "customer_behavior_assets_csv" {
  bucket = module.customer_data_bucket.bucket_id
  key    = "raw/customer_behavior_assets.csv"
  source = "${path.root}/../customer_behavior_assets.csv"

  # Use etag to detect file changes
  etag = filemd5("${path.root}/../customer_behavior_assets.csv")

  # Set content type
  content_type = "text/csv"

  # Storage class for cost optimization
  storage_class = "STANDARD"

  tags = {
    Name        = "Customer Behavior Assets Data"
    Description = "Source data: customer behavior and asset information"
  }

  depends_on = [aws_s3_object.raw_folder]
}

# Create cleaned data directory structure (for Glue output)
resource "aws_s3_object" "cleaned_folder" {
  bucket       = module.customer_data_bucket.bucket_id
  key          = "cleaned/"
  content_type = "application/x-directory"

  tags = {
    Name        = "Cleaned data directory"
    Description = "Directory for cleaned customer data (Glue output)"
  }

  depends_on = [module.customer_data_bucket]
}

# Create features data directory structure (for Glue output)
resource "aws_s3_object" "features_folder" {
  bucket       = module.customer_data_bucket.bucket_id
  key          = "features/"
  content_type = "application/x-directory"

  tags = {
    Name        = "Features data directory"
    Description = "Directory for engineered customer features (Glue output)"
  }

  depends_on = [module.customer_data_bucket]
}

# Create temp directory for Glue temporary files
resource "aws_s3_object" "temp_folder" {
  bucket       = module.customer_data_bucket.bucket_id
  key          = "temp/"
  content_type = "application/x-directory"

  tags = {
    Name        = "Temporary directory"
    Description = "Directory for Glue temporary files"
  }

  depends_on = [module.customer_data_bucket]
}

# Create scripts directory for Glue job scripts
resource "aws_s3_object" "scripts_folder" {
  bucket       = module.customer_data_bucket.bucket_id
  key          = "scripts/"
  content_type = "application/x-directory"

  tags = {
    Name        = "Scripts directory"
    Description = "Directory for Glue job scripts"
  }

  depends_on = [module.customer_data_bucket]
}

# Output information about uploaded files
output "raw_data_location" {
  description = "S3 location of raw customer data files"
  value       = "s3://${module.customer_data_bucket.bucket_id}/raw/"
}

output "customer_base_s3_path" {
  description = "S3 path for customer_base.csv"
  value       = "s3://${module.customer_data_bucket.bucket_id}/${aws_s3_object.customer_base_csv.key}"
}

output "customer_behavior_assets_s3_path" {
  description = "S3 path for customer_behavior_assets.csv"
  value       = "s3://${module.customer_data_bucket.bucket_id}/${aws_s3_object.customer_behavior_assets_csv.key}"
}

output "s3_directory_structure" {
  description = "S3 bucket directory structure created by Terraform"
  value = {
    raw      = "s3://${module.customer_data_bucket.bucket_id}/raw/"
    cleaned  = "s3://${module.customer_data_bucket.bucket_id}/cleaned/"
    features = "s3://${module.customer_data_bucket.bucket_id}/features/"
    scripts  = "s3://${module.customer_data_bucket.bucket_id}/scripts/"
    temp     = "s3://${module.customer_data_bucket.bucket_id}/temp/"
  }
}
