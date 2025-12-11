# Terraform 部署指南

## 前置条件

- AWS 账户
- AWS CLI 已配置
- Terraform >= 1.0
- 必要的 IAM 权限

## 部署步骤

### 步骤 1: 初始化 Terraform

```bash
cd infra
terraform init
```

预期输出：
```
Terraform has been successfully configured!
```

### 步骤 2: 配置变量

编辑 `terraform.tfvars`：

```hcl
aws_region = "us-east-1"
environment = "prod"

# Glue 配置
glue_max_capacity = 4
glue_worker_type  = "G.2X"
glue_timeout      = 60

# VPC 配置（可选）
vpc_id             = "vpc-xxxxx"
subnet_ids         = ["subnet-xxxxx", "subnet-yyyyy"]
security_group_ids = []

# 标签
tags = {
  Project = "customer-data"
  Owner   = "data-team"
  CostCenter = "engineering"
}
```

### 步骤 3: 验证配置

```bash
terraform validate
```

预期输出：
```
Success! The configuration is valid.
```

### 步骤 4: 查看变更

```bash
terraform plan
```

查看将要创建的资源，确认无误。

### 步骤 5: 应用配置

```bash
terraform apply
```

输入 `yes` 确认应用。

预期输出：
```
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.
```

### 步骤 6: 验证部署

```bash
# 查看输出
terraform output

# 验证 Glue Jobs
aws glue list-jobs

# 验证 S3 bucket
aws s3 ls

# 验证 IAM 角色
aws iam list-roles --query 'Roles[?contains(RoleName, `glue`)]'
```

## 部署配置

### 最小配置

```hcl
# 仅部署基础资源
aws_region = "us-east-1"
environment = "dev"
```

### 完整配置

```hcl
# 部署所有资源，包括 VPC
aws_region = "us-east-1"
environment = "prod"

glue_max_capacity = 4
glue_worker_type  = "G.2X"
glue_timeout      = 60

vpc_id             = "vpc-xxxxx"
subnet_ids         = ["subnet-xxxxx", "subnet-yyyyy"]
security_group_ids = ["sg-xxxxx"]

tags = {
  Project = "customer-data"
  Owner   = "data-team"
  CostCenter = "engineering"
  Environment = "prod"
}
```

## 更新部署

### 更新 Glue 配置

编辑 `terraform.tfvars`，修改相应参数：

```hcl
glue_max_capacity = 8  # 从 4 增加到 8
```

然后应用：

```bash
terraform plan
terraform apply
```

### 添加新的 Glue Job

编辑 `infra/modules/glue/jobs.tf`，添加新的 Job 定义：

```hcl
resource "aws_glue_job" "new_job" {
  name = "new-job"
  # ...
}
```

然后应用：

```bash
terraform apply
```

### 删除资源

编辑 `terraform.tfvars` 或代码，删除相应资源定义，然后：

```bash
terraform plan
terraform apply
```

或直接销毁特定资源：

```bash
terraform destroy -target=aws_glue_job.job_name
```

## 状态管理

### 本地状态

默认情况下，Terraform 将状态保存在本地 `terraform.tfstate` 文件中。

**备份状态**:
```bash
cp terraform.tfstate terraform.tfstate.backup
```

### 远程状态（推荐）

使用 S3 后端存储状态：

```hcl
# infra/backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "customer-data/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

初始化：

```bash
terraform init
```

### 状态锁定

使用 DynamoDB 防止并发修改：

```bash
# 创建 DynamoDB 表
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

## 监控部署

### 查看部署进度

```bash
# 查看 Terraform 日志
TF_LOG=DEBUG terraform apply

# 查看 AWS 资源创建进度
aws cloudformation describe-stacks --stack-name terraform-stack
```

### 验证资源

```bash
# 查看所有资源
terraform state list

# 查看特定资源详情
terraform state show aws_glue_job.customer_data_cleansing

# 查看资源属性
terraform output
```

## 故障排除

### 问题: 部署失败

**检查清单**:
1. 验证 AWS 凭证
2. 检查 IAM 权限
3. 查看错误日志
4. 检查资源配额

**查看详细日志**:
```bash
TF_LOG=DEBUG terraform apply
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
# 检查当前用户
aws sts get-caller-identity

# 检查 IAM 权限
aws iam get-user-policy --user-name username --policy-name policy-name

# 添加必要权限
aws iam attach-user-policy --user-name username --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

## 回滚部署

### 回滚到上一个版本

```bash
# 查看状态历史
terraform state list

# 恢复备份
cp terraform.tfstate.backup terraform.tfstate

# 刷新状态
terraform refresh
```

### 销毁所有资源

```bash
terraform destroy
```

输入 `yes` 确认销毁。

## 成本估算

### 查看预期成本

```bash
# 使用 Terraform Cloud 的成本估算
terraform plan -out=tfplan

# 或使用第三方工具
infracost breakdown --path .
```

### 优化成本

1. **使用预留容量**
   ```hcl
   glue_max_capacity = 2  # 减少容量
   ```

2. **使用 Spot 实例**
   ```hcl
   glue_worker_type = "G.1X"  # 使用更小的 worker
   ```

3. **定期清理资源**
   ```bash
   terraform destroy -target=aws_s3_object.old_data
   ```

## 相关文档

- [Terraform 快速参考](./01_QUICK_REFERENCE.md)
- [迁移指南](./03_MIGRATION_GUIDE.md)
- [Glue 快速开始](../glue/00_QUICK_START.md)

---

**最后更新**: 2025-12-10
