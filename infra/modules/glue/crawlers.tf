# ============================================================================
# AWS Glue Crawlers for automatic schema discovery and table registration
# ============================================================================
# These crawlers will automatically discover the schema of CSV files in S3
# and create/update corresponding tables in the Glue Catalog

# Crawler for raw customer base data
resource "aws_glue_crawler" "raw_customer_base" {
  name          = "${var.project_name}-${var.environment}-raw-customer-base-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.databases["customer_raw_db"].name

  # Configure S3 target path
  s3_target {
    path = "s3://${var.s3_bucket_name}/raw/customer_base.csv"
  }

  # Schema inference configuration
  schema_change_policy {
    delete_behavior = "LOG"                # Log but don't delete columns that are removed
    update_behavior = "UPDATE_IN_DATABASE" # Update table schema when changes detected
  }

  # Table prefix for naming discovered tables
  table_prefix = "raw_"

  # Crawler configuration
  description = "Automatically discovers schema for raw customer base CSV files"

  # Configuration for CSV parsing and table naming
  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      TableCreation = "Enabled"
      Partitioning = {
        Enabled = false
      }
    }
    Grouping = {
      BehaviorOnUpdate = "UPDATE_IN_DATABASE"
    }
    Connection = {
      ConnectionRequirement = "Optional"
    }
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-raw-customer-base-crawler"
      Type = "DataDiscovery"
    }
  )

  # Ensure database exists before creating crawler
  depends_on = [aws_glue_catalog_database.databases]
}

# Crawler for raw customer behavior and assets data
resource "aws_glue_crawler" "raw_customer_behavior" {
  name          = "${var.project_name}-${var.environment}-raw-customer-behavior-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.databases["customer_raw_db"].name

  # Configure S3 target path
  s3_target {
    path = "s3://${var.s3_bucket_name}/raw/customer_behavior_assets.csv"
  }

  # Schema inference configuration
  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  # Table prefix for naming discovered tables
  table_prefix = "raw_"

  # Crawler configuration
  description = "Automatically discovers schema for raw customer behavior and assets CSV files"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-raw-customer-behavior-crawler"
      Type = "DataDiscovery"
    }
  )

  # Ensure database exists before creating crawler
  depends_on = [aws_glue_catalog_database.databases]
}

# ============================================================================
# Crawlers for cleaned data (output from data cleansing job)
# ============================================================================

# Crawler for cleaned customer base data
resource "aws_glue_crawler" "cleaned_customer_base" {
  name          = "${var.project_name}-${var.environment}-cleaned-customer-base-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.databases["customer_cleaned_db"].name

  # Configure S3 target path for cleaned data output
  s3_target {
    path = "s3://${var.s3_bucket_name}/cleaned/customer_base"
  }

  # Schema inference configuration
  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  # Table prefix for naming discovered tables
  table_prefix = "cleaned_"

  # Crawler configuration
  description = "Automatically discovers schema for cleaned customer base parquet files"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-cleaned-customer-base-crawler"
      Type = "DataDiscovery"
    }
  )

  depends_on = [aws_glue_catalog_database.databases]
}

# Crawler for cleaned customer behavior data
resource "aws_glue_crawler" "cleaned_customer_behavior" {
  name          = "${var.project_name}-${var.environment}-cleaned-customer-behavior-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.databases["customer_cleaned_db"].name

  # Configure S3 target path for cleaned data output
  s3_target {
    path = "s3://${var.s3_bucket_name}/cleaned/customer_behavior"
  }

  # Schema inference configuration
  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  # Table prefix for naming discovered tables
  table_prefix = "cleaned_"

  # Crawler configuration
  description = "Automatically discovers schema for cleaned customer behavior parquet files"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-cleaned-customer-behavior-crawler"
      Type = "DataDiscovery"
    }
  )

  depends_on = [aws_glue_catalog_database.databases]
}
