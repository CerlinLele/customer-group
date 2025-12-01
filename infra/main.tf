# S3 bucket for storing customer data
resource "aws_s3_bucket" "customer_data" {
  bucket = "${var.project_name}-${var.environment}-data-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-data-bucket"
    Description = "Bucket for storing customer data files"
  }
}

# Enable versioning for data protection
resource "aws_s3_bucket_versioning" "customer_data_versioning" {
  bucket = aws_s3_bucket.customer_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "customer_data_pab" {
  bucket = aws_s3_bucket.customer_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "customer_data_encryption" {
  bucket = aws_s3_bucket.customer_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
