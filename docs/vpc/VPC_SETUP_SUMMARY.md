# VPC Setup Summary for CASE Customer Group Project

## Overview

A dedicated VPC (Virtual Private Cloud) has been created specifically for this project's AWS Glue ETL jobs. This VPC provides a secure, isolated network environment for your data processing pipeline.

## VPC Architecture

### VPC Configuration
- **VPC CIDR Block**: 10.0.0.0/16
- **Region**: us-east-1 (configurable via `var.aws_region`)

### Network Components

#### Public Subnets (Internet-facing)
- **Subnet 1**: 10.0.1.0/24 (in us-east-1a)
- **Subnet 2**: 10.0.2.0/24 (in us-east-1b)
- **Purpose**: Houses NAT Gateway for outbound internet access
- **Internet Gateway**: Provides direct internet connectivity

#### Private Subnets (For Glue Jobs)
- **Subnet 1**: 10.0.11.0/24 (in us-east-1a)
- **Subnet 2**: 10.0.12.0/24 (in us-east-1b)
- **Purpose**: Runs AWS Glue jobs with controlled internet access via NAT Gateway
- **Route Table**: Routes 0.0.0.0/0 through NAT Gateway

#### NAT Gateway
- **Location**: Public subnet 1
- **Purpose**: Enables Glue jobs in private subnets to reach AWS services (S3, Glue API, etc.)
- **Elastic IP**: Automatically allocated and managed

### Security Group

**Security Group**: `case-customer-group-{environment}-glue-sg`

#### Ingress Rules
- Self-to-self communication on all TCP ports (0-65535)
- Spark master/worker communication (ports 7077-7078)
- Spark RPC/BlockManager ports (38600-38700)

#### Egress Rules
- All outbound traffic (0.0.0.0/0) to reach AWS services

## Glue Job Integration

The Glue module has been configured to:

1. **Use Private Subnets**: Glue jobs run in the private subnets for security
2. **Apply Security Group**: Jobs use the dedicated security group for network control
3. **Pass VPC Parameters**: Subnet and security group IDs are passed via job default arguments:
   - `--vpc-subnet-ids`: Comma-separated list of private subnet IDs
   - `--vpc-security-group-ids`: Comma-separated list of security group IDs

## Infrastructure Files Created/Modified

### New Files
- `infra/modules/vpc/main.tf` - VPC, subnets, NAT gateway, security group resources
- `infra/modules/vpc/variables.tf` - VPC module input variables
- `infra/modules/vpc/outputs.tf` - VPC module outputs (IDs, CIDR blocks, etc.)

### Modified Files
- `infra/main.tf` - Added VPC module and connected it to Glue pipeline
- `infra/modules/glue/jobs.tf` - Updated to pass VPC subnet/security group parameters
- `infra/outputs.tf` - Added VPC-related outputs

## Deployment Steps

### 1. Validate Configuration
```bash
cd infra
terraform validate
```

### 2. Review Changes
```bash
terraform plan
```

### 3. Apply Changes
```bash
terraform apply
```

### 4. Verify Deployment
After deployment, check the outputs:
```bash
terraform output vpc_id
terraform output private_subnet_ids
terraform output glue_security_group_id
```

## Network Flow

```
┌─────────────────────────────────────────┐
│         VPC (10.0.0.0/16)               │
│                                         │
│  ┌────────────────────────────────┐   │
│  │  Public Subnets                │   │
│  │  - 10.0.1.0/24 (az: us-east-1a)   │
│  │  - 10.0.2.0/24 (az: us-east-1b)   │
│  │                                │   │
│  │  ┌──────────────┐              │   │
│  │  │ NAT Gateway  │──┐           │   │
│  │  └──────────────┘  │           │   │
│  └────────────────────────────────┘   │
│                       │                │
│                       │ (outbound)     │
│                       ▼                │
│  ┌────────────────────────────────┐   │
│  │  Private Subnets               │   │
│  │  - 10.0.11.0/24 (az: us-east-1a)  │
│  │  - 10.0.12.0/24 (az: us-east-1b)  │
│  │                                │   │
│  │  ┌──────────────────────────┐  │   │
│  │  │  Glue Jobs               │  │   │
│  │  │  (Security Group attached)   │   │
│  │  └──────────────────────────┘  │   │
│  │                                │   │
│  └────────────────────────────────┘   │
│                                         │
│  ┌────────────────────────────────┐   │
│  │  Internet Gateway              │   │
│  │  (Public subnets access)       │   │
│  └────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

## Network Traffic Examples

### Glue Job to S3 (Same Region)
- **Source**: Glue Job in private subnet
- **Route**: Private subnet route table → NAT Gateway → Internet Gateway → AWS S3 API
- **Security**: Managed by security group egress rules

### Glue Job to Glue API
- **Source**: Glue Job in private subnet
- **Route**: AWS internal routing (via VPC endpoints or through NAT)
- **Security**: IAM permissions managed by Glue role

## Customization

### Changing CIDR Blocks
Edit `infra/main.tf` and modify the module call:
```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr              = "10.1.0.0/16"  # Change this
  public_subnet_cidrs   = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs  = ["10.1.11.0/24", "10.1.12.0/24"]
}
```

### Adding More Availability Zones
Extend the subnet CIDR arrays in `infra/main.tf`:
```hcl
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
```

## Outputs Available

After deployment, use `terraform output` to see:
- `vpc_id` - VPC ID
- `vpc_cidr` - VPC CIDR block
- `public_subnet_ids` - Public subnet IDs
- `private_subnet_ids` - Private subnet IDs (used by Glue)
- `glue_security_group_id` - Security group for Glue jobs

## Cleanup

To remove the VPC and all its resources:
```bash
terraform destroy
```

## Next Steps

1. Review the terraform plan output to understand the resources being created
2. Deploy the infrastructure using `terraform apply`
3. Monitor the Glue job runs to ensure they execute properly in the VPC
4. Check CloudWatch logs for any network-related issues

---

**Created**: 2025-12-06
**Project**: CASE Customer Group
**Environment**: Development (customizable)
