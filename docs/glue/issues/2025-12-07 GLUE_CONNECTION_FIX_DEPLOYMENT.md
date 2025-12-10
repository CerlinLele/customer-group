# AWS Glue Connection Fix - Deployment Summary

**Date**: 2025-12-07
**Issue**: AWS Glue Spark executor connection failures (`Connection refused: /172.38.23.198:34089`)

## Root Cause Analysis

The Glue jobs were **missing the critical `vpc_config` block** in the Terraform resource definition. While VPC configuration parameters were being passed as job arguments (`--vpc-subnet-ids`, `--vpc-security-group-ids`), AWS Glue does not accept these as command-line parameters. They must be configured directly in the job resource using the `vpc_config` block.

Without proper VPC configuration:
- Spark executors cannot establish network connections with the driver
- All RPC communication fails with "Connection refused" errors
- Jobs timeout and crash

## Solution Implemented

### Fixed File: `infra/modules/glue/jobs.tf`

Changed from passing VPC parameters as job arguments to using the proper Terraform `vpc_config` block:

**Before:**
```terraform
default_arguments = merge(
  each.value.parameters,
  {
    # ... other args ...
  },
  # Incorrect: VPC parameters passed as job arguments (ineffective)
  length(var.subnet_ids) > 0 ? {
    "--vpc-subnet-ids"         = join(",", var.subnet_ids)
    "--vpc-security-group-ids" = join(",", var.security_group_ids)
  } : {}
)
```

**After:**
```terraform
dynamic "vpc_config" {
  for_each = length(var.subnet_ids) > 0 ? [1] : []

  content {
    subnet_ids             = var.subnet_ids
    security_group_ids     = var.security_group_ids
    availability_zone      = null  # AWS will auto-select from provided subnets
  }
}
```

## What This Fix Does

1. **Enables proper VPC integration**: Glue jobs now run within the specified subnets
2. **Applies security group rules**: Network traffic is controlled by the configured security group
3. **Allows executor-driver communication**: Spark executors can establish RPC connections with the driver on any port within the security group rules
4. **Automatic ENI management**: AWS automatically creates and manages Elastic Network Interfaces for the Glue job

## Deployment Steps

### Step 1: Verify Infrastructure (Already In Place)

The VPC and security group configurations are already correctly set up:
- **VPC**: 10.0.0.0/16 with public and private subnets
- **Security Group**: Allows self-communication on all TCP ports (crucial for Spark)
- **Subnet IDs**: Passed from `infra/main.tf` to the Glue module

### Step 2: Apply Terraform Changes

```bash
cd infra

# Review the changes
terraform plan

# Apply the fix
terraform apply
```

Expected output:
- `aws_glue_job.jobs` resources will be updated with the new vpc_config block

### Step 3: Redeploy/Restart Glue Jobs

After Terraform apply:

```bash
# Trigger the data cleansing job
aws glue start-job-run --job-name customer-data-cleansing

# Monitor logs
aws logs tail /aws-glue/jobs/customer-data-cleansing --follow
```

## Configuration Reference

### Current VPC Setup (in `infra/main.tf`)

```terraform
module "glue_pipeline" {
  source = "./modules/glue"

  # VPC Configuration - These are now properly used in vpc_config block
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.vpc.glue_security_group_id]

  # ... other configuration ...
}
```

### Security Group Rules (in `infra/modules/vpc/main.tf`)

```terraform
# Allow self communication on all ports (CRITICAL for Spark)
ingress {
  from_port = 0
  to_port   = 65535
  protocol  = "tcp"
  self      = true
}

# Allow outbound to all (for S3, etc.)
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```

## Verification Checklist

After deployment, verify:

- [ ] Terraform apply completes successfully
- [ ] No errors in Terraform output
- [ ] Glue job configuration shows `vpc_config` in AWS Console
- [ ] Job runs without "Connection refused" errors
- [ ] CloudWatch logs show successful data processing
- [ ] No executor failures or RPC timeouts

## Monitoring

Check CloudWatch logs for:
```
✓ Job succeeded (no connection errors)
✓ Executor heartbeats successful
✓ Data processing completed
✓ Output written to S3
```

## Additional Resources

- **VPC Configuration**: [infra/modules/vpc/main.tf](infra/modules/vpc/main.tf)
- **Security Configuration**: [infra/modules/glue/security.tf](infra/modules/glue/security.tf)
- **Job Configuration**: [infra/modules/glue/jobs.tf](infra/modules/glue/jobs.tf)
- **Documentation**: [docs/feature-engineering/1.3 GLUE_CONNECTION_FIX.md](docs/feature-engineering/1.3%20GLUE_CONNECTION_FIX.md)

## Related Issues

This fix addresses:
- `java.net.ConnectException: Connection refused: /172.38.23.198:34089`
- `Failed to connect to executor RPC address`
- `Spark executor communication failures`
- `Glue job timeout on private VPC`

## Notes

- The Spark configuration in `glue_scripts/1_data_cleansing.py` and `glue_scripts/2_feature_engineering.py` already has network timeout optimization (600s) in place - this complements the VPC configuration fix
- The fix is backward compatible: if no subnets are provided, the job runs without VPC configuration as before
- No code changes needed in Glue scripts themselves
