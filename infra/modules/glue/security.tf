# Note: Security group for Glue jobs is now created by the VPC module
# This avoids duplication and ensures proper VPC integration.
# The VPC module creates: aws_security_group.glue (with proper rules)

# Glue Security Configuration for VPC
resource "aws_glue_security_configuration" "vpc_security" {
  count = length(var.subnet_ids) > 0 ? 1 : 0

  name = "${var.project_name}-${var.environment}-vpc-security"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    s3_encryption {
      s3_encryption_mode = "DISABLED"
    }
  }
}

# Update IAM role policy to include VPC-related permissions
data "aws_iam_policy_document" "glue_vpc_policy" {
  count = length(var.subnet_ids) > 0 ? 1 : 0

  statement {
    sid    = "GlueVPCAccess"
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:CreateSecurityGroup",
      "ec2:DescribeVpcs",
      "ec2:DescribeInstanceTypes"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "GlueVPCTagging"
    effect = "Allow"

    actions = [
      "ec2:CreateTags"
    ]

    resources = [
      "arn:aws:ec2:*:*:network-interface/*",
      "arn:aws:ec2:*:*:security-group/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"

      values = [
        "CreateNetworkInterface",
        "CreateSecurityGroup"
      ]
    }
  }
}

# Create inline policy for VPC access if configured
resource "aws_iam_role_policy" "glue_vpc_policy" {
  count = length(var.subnet_ids) > 0 ? 1 : 0

  name   = "GlueVPCExecutionPolicy"
  role   = aws_iam_role.glue_role.id
  policy = data.aws_iam_policy_document.glue_vpc_policy[0].json
}
