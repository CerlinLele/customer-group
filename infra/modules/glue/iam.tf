# Trust policy for Glue service
data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM role for Glue service
resource "aws_iam_role" "glue_role" {
  name               = "${var.project_name}-${var.environment}-${var.glue_role_name}"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-glue-role"
    }
  )
}

# Custom permissions policy for Glue
data "aws_iam_policy_document" "glue_policy" {
  # S3 access permissions
  statement {
    sid    = "S3Access"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]

    resources = [
      var.s3_bucket_arn,
      "${var.s3_bucket_arn}/*"
    ]
  }

  # Glue Catalog access permissions
  statement {
    sid    = "GlueCatalogAccess"
    effect = "Allow"

    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetPartitions",
      "glue:CreatePartition",
      "glue:BatchCreatePartition",
      "glue:UpdatePartition",
      "glue:BatchUpdatePartition",
      "glue:DeletePartition",
      "glue:BatchDeletePartition",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:GetTableVersions"
    ]

    resources = ["*"]
  }

  # Glue Crawler execution permissions
  statement {
    sid    = "GlueCrawlerExecution"
    effect = "Allow"

    actions = [
      "glue:GetCrawler",
      "glue:GetCrawlers",
      "glue:StartCrawler",
      "glue:StopCrawler"
    ]

    resources = ["*"]
  }

  # Glue Job execution permissions
  statement {
    sid    = "GlueJobExecution"
    effect = "Allow"

    actions = [
      "glue:StartJobRun",
      "glue:GetJobRun",
      "glue:GetJobRuns"
    ]

    resources = ["arn:aws:glue:*:*:job/*"]
  }

  # CloudWatch Logs permissions
  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }

  # CloudWatch Metrics permissions
  statement {
    sid    = "CloudWatchMetrics"
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData"
    ]

    resources = ["*"]
  }

  # SNS publish permissions
  statement {
    sid    = "SNSPublish"
    effect = "Allow"

    actions = [
      "sns:Publish"
    ]

    resources = ["arn:aws:sns:*:*:*"]
  }
}

# Create inline policy for the role
resource "aws_iam_role_policy" "glue_policy" {
  name   = "GlueExecutionPolicy"
  role   = aws_iam_role.glue_role.id
  policy = data.aws_iam_policy_document.glue_policy.json
}

# Attach AWS managed Glue service role policy
resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}
