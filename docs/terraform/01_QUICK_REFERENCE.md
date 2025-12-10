# Terraform 快速参考

## 常用命令

### 初始化

```bash
# 初始化 Terraform 工作目录
terraform init

# 初始化并指定后端
terraform init -backend-config="bucket=my-bucket" -backend-config="key=terraform.tfstate"
```

### 验证和规划

```bash
# 验证配置语法
terraform validate

# 查看将要应用的变更
terraform plan

# 保存计划到文件
terraform plan -out=tfplan

# 查看详细的变更
terraform plan -detailed-exitcode
```

### 应用和销毁

```bash
# 应用配置
terraform apply

# 应用保存的计划
terraform apply tfplan

# 自动确认（不提示）
terraform apply -auto-approve

# 销毁资源
terraform destroy

# 销毁特定资源
terraform destroy -target=aws_glue_job.customer_data_cleansing
```

### 查看状态

```bash
# 查看当前状态
terraform show

# 列出资源
terraform state list

# 查看特定资源
terraform state show aws_glue_job.customer_data_cleansing

# 导出状态
terraform state pull > terraform.tfstate.backup
```

### 导入资源

```bash
# 导入现有资源
terraform import aws_glue_job.customer_data_cleansing customer-data-cleansing

# 导入 S3 bucket
terraform import aws_s3_bucket.data my-bucket
```

### 刷新状态

```bash
# 刷新状态（同步远程资源）
terraform refresh

# 查看刷新后的状态
terraform show
```

## 项目结构

```
infra/
├── main.tf                 # 主配置
├── variables.tf            # 变量定义
├── outputs.tf              # 输出定义
├── terraform.tfvars        # 变量值
├── modules/
│   ├── glue/              # Glue 模块
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── jobs.tf
│   │   ├── security.tf
│   │   └── iam.tf
│   ├── s3/                # S3 模块
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── vpc/               # VPC 模块
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── .terraform/            # Terraform 缓存
```

## 常见配置

### 变量定义

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project = "customer-data"
    Owner   = "data-team"
  }
}
```

### 输出定义

```hcl
output "glue_job_name" {
  description = "Glue job name"
  value       = aws_glue_job.customer_data_cleansing.name
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.data.id
}
```

### 条件创建

```hcl
# 根据条件创建资源
resource "aws_glue_security_configuration" "vpc_security" {
  count = var.enable_vpc ? 1 : 0

  name = "glue-vpc-security"
  # ...
}

# 引用条件创建的资源
security_configuration = var.enable_vpc ? aws_glue_security_configuration.vpc_security[0].name : null
```

### 循环创建

```hcl
# 创建多个资源
resource "aws_glue_job" "jobs" {
  for_each = var.jobs

  name = each.value.name
  # ...
}

# 引用循环创建的资源
output "job_names" {
  value = [for job in aws_glue_job.jobs : job.name]
}
```

## 最佳实践

### 1. 使用模块组织代码

```hcl
module "glue" {
  source = "./modules/glue"

  aws_region = var.aws_region
  environment = var.environment
  tags        = var.tags
}
```

### 2. 使用变量避免硬编码

```hcl
# ❌ 不好
resource "aws_glue_job" "job" {
  max_capacity = 4
}

# ✅ 好
variable "glue_max_capacity" {
  default = 4
}

resource "aws_glue_job" "job" {
  max_capacity = var.glue_max_capacity
}
```

### 3. 使用本地值简化配置

```hcl
locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_glue_job" "job" {
  tags = local.common_tags
}
```

### 4. 使用数据源查询现有资源

```hcl
# 查询现有 VPC
data "aws_vpc" "default" {
  default = true
}

# 查询现有子网
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
```

### 5. 使用 depends_on 管理依赖

```hcl
resource "aws_glue_job" "job" {
  # ...
  depends_on = [aws_iam_role.glue_role]
}
```

## 故障排除

### 问题: 状态冲突

**解决方案**:
```bash
# 刷新状态
terraform refresh

# 查看冲突
terraform plan

# 手动解决冲突后重新应用
terraform apply
```

### 问题: 资源已存在

**解决方案**:
```bash
# 导入现有资源
terraform import aws_glue_job.job job-name

# 或删除并重新创建
terraform destroy -target=aws_glue_job.job
terraform apply
```

### 问题: 权限不足

**解决方案**:
```bash
# 检查 AWS 凭证
aws sts get-caller-identity

# 检查 IAM 权限
aws iam get-user-policy --user-name username --policy-name policy-name
```

## 相关文档

- [部署指南](./02_DEPLOYMENT_GUIDE.md)
- [迁移指南](./03_MIGRATION_GUIDE.md)
- [Glue 快速开始](../glue/00_QUICK_START.md)

---

**最后更新**: 2025-12-10
