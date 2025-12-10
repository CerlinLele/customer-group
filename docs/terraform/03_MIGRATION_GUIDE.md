# Terraform 迁移指南

从其他工具或手动配置迁移到 Terraform 的完整指南。

## 迁移场景

### 场景 1: 从手动 AWS 配置迁移

**现状**: 已在 AWS 中手动创建了 Glue Jobs、S3 buckets 等资源

**目标**: 将所有资源纳入 Terraform 管理

### 场景 2: 从其他 IaC 工具迁移

**现状**: 使用 CloudFormation、Pulumi 等其他工具

**目标**: 迁移到 Terraform

## 迁移步骤

### 步骤 1: 审计现有资源

列出所有需要迁移的资源：

```bash
# 列出 Glue Jobs
aws glue list-jobs

# 列出 S3 buckets
aws s3 ls

# 列出 IAM 角色
aws iam list-roles

# 列出 VPC
aws ec2 describe-vpcs

# 列出安全组
aws ec2 describe-security-groups
```

### 步骤 2: 规划 Terraform 结构

创建模块化的 Terraform 配置：

```
infra/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── modules/
    ├── glue/
    ├── s3/
    ├── iam/
    └── vpc/
```

### 步骤 3: 编写 Terraform 配置

为每个资源编写 Terraform 代码：

```hcl
# infra/modules/glue/jobs.tf
resource "aws_glue_job" "customer_data_cleansing" {
  name              = "customer-data-cleansing"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.scripts.id}/1_data_cleansing.py"
  }
  max_capacity      = 4
  timeout           = 60
}
```

### 步骤 4: 导入现有资源

使用 `terraform import` 导入现有资源：

```bash
# 导入 Glue Job
terraform import aws_glue_job.customer_data_cleansing customer-data-cleansing

# 导入 S3 bucket
terraform import aws_s3_bucket.data my-bucket

# 导入 IAM 角色
terraform import aws_iam_role.glue_role glue-role
```

### 步骤 5: 验证导入

```bash
# 查看导入的资源
terraform state list

# 查看资源详情
terraform state show aws_glue_job.customer_data_cleansing

# 生成计划
terraform plan
```

### 步骤 6: 调整配置

根据 `terraform plan` 的输出，调整 Terraform 配置以匹配现有资源。

### 步骤 7: 应用配置

```bash
# 验证配置
terraform validate

# 查看变更
terraform plan

# 应用配置
terraform apply
```

## 常见迁移场景

### 迁移 Glue Jobs

```bash
# 1. 列出所有 Jobs
aws glue list-jobs --query 'JobNames'

# 2. 为每个 Job 编写 Terraform 配置
# infra/modules/glue/jobs.tf

# 3. 导入 Jobs
for job in $(aws glue list-jobs --query 'JobNames' --output text); do
  terraform import aws_glue_job.$job $job
done

# 4. 验证
terraform plan
```

### 迁移 S3 Buckets

```bash
# 1. 列出所有 buckets
aws s3 ls

# 2. 为每个 bucket 编写 Terraform 配置
# infra/modules/s3/main.tf

# 3. 导入 buckets
for bucket in $(aws s3 ls --query 'Buckets[].Name' --output text); do
  terraform import aws_s3_bucket.data $bucket
done

# 4. 验证
terraform plan
```

### 迁移 IAM 角色

```bash
# 1. 列出所有角色
aws iam list-roles --query 'Roles[].RoleName'

# 2. 为每个角色编写 Terraform 配置
# infra/modules/iam/main.tf

# 3. 导入角色
terraform import aws_iam_role.glue_role glue-role

# 4. 导入角色策略
terraform import aws_iam_role_policy.glue_policy glue-role:glue-policy

# 5. 验证
terraform plan
```

## 迁移检查清单

### 迁移前

- [ ] 备份现有配置
- [ ] 审计所有资源
- [ ] 规划 Terraform 结构
- [ ] 获取必要权限

### 迁移中

- [ ] 编写 Terraform 配置
- [ ] 导入现有资源
- [ ] 验证导入
- [ ] 调整配置
- [ ] 测试部署

### 迁移后

- [ ] 验证所有资源
- [ ] 更新文档
- [ ] 设置 CI/CD
- [ ] 监控部署

## 最佳实践

### 1. 分阶段迁移

不要一次性迁移所有资源，分阶段进行：

```bash
# 第 1 阶段: 迁移 IAM 角色
terraform apply -target=module.iam

# 第 2 阶段: 迁移 S3 buckets
terraform apply -target=module.s3

# 第 3 阶段: 迁移 Glue Jobs
terraform apply -target=module.glue
```

### 2. 使用 terraform state mv

如果需要重组资源：

```bash
# 移动资源
terraform state mv aws_glue_job.old aws_glue_job.new

# 验证
terraform state list
```

### 3. 使用 terraform state rm

如果需要删除资源（不删除实际资源）：

```bash
# 从状态中删除
terraform state rm aws_glue_job.old

# 稍后重新导入
terraform import aws_glue_job.old job-name
```

### 4. 使用 terraform refresh

定期刷新状态以同步远程资源：

```bash
terraform refresh
```

## 故障排除

### 问题: 导入失败

**解决方案**:
```bash
# 检查资源是否存在
aws glue get-job --name job-name

# 检查 Terraform 配置
terraform validate

# 查看详细错误
TF_LOG=DEBUG terraform import aws_glue_job.job job-name
```

### 问题: 导入后 plan 显示变更

**解决方案**:
1. 检查 Terraform 配置是否与实际资源匹配
2. 调整配置以匹配实际资源
3. 使用 `terraform state show` 查看导入的资源

```bash
# 查看导入的资源
terraform state show aws_glue_job.job

# 查看 Terraform 配置
terraform show
```

### 问题: 权限不足

**解决方案**:
```bash
# 检查当前用户权限
aws sts get-caller-identity

# 检查 IAM 策略
aws iam get-user-policy --user-name username --policy-name policy-name

# 添加必要权限
aws iam attach-user-policy --user-name username --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

## 迁移后维护

### 1. 定期验证

```bash
# 定期运行 plan 检查
terraform plan

# 定期刷新状态
terraform refresh
```

### 2. 更新文档

- 更新架构文档
- 记录 Terraform 配置
- 编写操作指南

### 3. 设置 CI/CD

```bash
# 使用 GitHub Actions 自动化部署
name: Terraform

on:
  push:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: hashicorp/setup-terraform@v1
      - run: terraform init
      - run: terraform plan
      - run: terraform apply -auto-approve
```

## 相关文档

- [Terraform 快速参考](./01_QUICK_REFERENCE.md)
- [Terraform 部署指南](./02_DEPLOYMENT_GUIDE.md)

---

**最后更新**: 2025-12-10
