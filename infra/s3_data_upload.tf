# S3 objects for uploading source data files
# This configuration uploads CSV files to the raw data layer after S3 bucket is created
# Compatible with AWS provider >= 5.45

# Create raw data directory structure (folder placeholder)
resource "aws_s3_object" "raw_folder" {
  bucket       = module.customer_data_bucket.bucket_id
  key          = "raw/"
  content_type = "application/x-directory"

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

  depends_on = [module.customer_data_bucket]
}

# Create features data directory structure (for Glue output)
resource "aws_s3_object" "features_folder" {
  bucket       = module.customer_data_bucket.bucket_id
  key          = "features/"
  content_type = "application/x-directory"

  depends_on = [module.customer_data_bucket]
}

# Create temp directory for Glue temporary files
resource "aws_s3_object" "temp_folder" {
  bucket       = module.customer_data_bucket.bucket_id
  key          = "temp/"
  content_type = "application/x-directory"

  depends_on = [module.customer_data_bucket]
}

# Create scripts directory for Glue job scripts
resource "aws_s3_object" "scripts_folder" {
  bucket       = module.customer_data_bucket.bucket_id
  key          = "scripts/"
  content_type = "application/x-directory"

  depends_on = [module.customer_data_bucket]
}

# Upload data cleansing Glue script
resource "aws_s3_object" "glue_data_cleansing_script" {
  bucket = module.customer_data_bucket.bucket_id
  key    = "scripts/1_data_cleansing.py"
  source = "${path.root}/../glue_scripts/1_data_cleansing.py"

  # Use etag to detect file changes
  etag = filemd5("${path.root}/../glue_scripts/1_data_cleansing.py")

  # Set content type
  content_type = "text/x-python"

  # Storage class for cost optimization
  storage_class = "STANDARD"

  tags = {
    Name        = "Data Cleansing Script"
    Description = "Glue job script: clean raw customer data"
  }

  depends_on = [aws_s3_object.scripts_folder]
}

# Upload feature engineering Glue script
resource "aws_s3_object" "glue_feature_engineering_script" {
  bucket = module.customer_data_bucket.bucket_id
  key    = "scripts/2_feature_engineering.py"
  source = "${path.root}/../glue_scripts/2_feature_engineering.py"

  # Use etag to detect file changes
  etag = filemd5("${path.root}/../glue_scripts/2_feature_engineering.py")

  # Set content type
  content_type = "text/x-python"

  # Storage class for cost optimization
  storage_class = "STANDARD"

  tags = {
    Name        = "Feature Engineering Script"
    Description = "Glue job script: generate ML features from cleaned data"
  }

  depends_on = [aws_s3_object.scripts_folder]
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

output "data_cleansing_script_s3_path" {
  description = "S3 path for data cleansing Glue script"
  value       = "s3://${module.customer_data_bucket.bucket_id}/${aws_s3_object.glue_data_cleansing_script.key}"
}

output "feature_engineering_script_s3_path" {
  description = "S3 path for feature engineering Glue script"
  value       = "s3://${module.customer_data_bucket.bucket_id}/${aws_s3_object.glue_feature_engineering_script.key}"
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
