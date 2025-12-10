# Terraform 快速参考卡片

## 🚀 最快部署（复制粘贴）

```bash
# 第一次使用
aws configure                    # 配置AWS凭证
cd infra
terraform init                   # 初始化（仅需一次）

# 部署
terraform plan                   # 查看计划
terraform apply                  # 部署（输入: yes）
terraform output                 # 查看结果

# 验证
BUCKET=$(terraform output -raw s3_bucket_name)
aws s3 ls s3://$BUCKET/raw/     # 检查CSV文件
```

---

## 📋 常用命令速查

| 命令 | 说明 |
|------|------|
| `terraform init` | 初始化Terraform（下载插件） |
| `terraform plan` | 显示将要创建/修改/删除的资源 |
| `terraform apply` | 应用配置到AWS |
| `terraform destroy` | 删除所有资源 |
| `terraform output` | 显示输出值 |
| `terraform state list` | 列出托管的资源 |
| `terraform show` | 显示完整状态 |
| `terraform fmt -recursive .` | 格式化代码 |
| `terraform validate` | 验证语法 |

---

## 🔧 常见任务

### 更新CSV文件
```bash
# 1. 编辑本地CSV（/project-root/customer_base.csv）
# 2. 检查变化
terraform plan

# 3. 上传新版本
terraform apply
```

### 查看S3 bucket名称
```bash
terraform output s3_bucket_name
# 或
terraform output -raw s3_bucket_name  # 无引号输出
```

### 查看所有输出
```bash
terraform output
```

### 删除特定资源
```bash
# 列出所有资源
terraform state list

# 删除特定资源
terraform state rm aws_s3_object.customer_base_csv

# 然后重新应用
terraform apply
```

### 清理所有资源
```bash
# 先查看将要删除的
terraform plan -destroy

# 执行删除
terraform destroy  # 输入: yes
```

---

## 📊 输出示例

### terraform plan 输出
```
Plan: 15 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + s3_bucket_name = "customer-group-dev-data-123456789"
  + s3_bucket_arn  = "arn:aws:s3:::customer-group-dev-data-123456789"
  + raw_data_location = "s3://customer-group-dev-data-123456789/raw/"
  + customer_base_s3_path = "s3://customer-group-dev-data-123456789/raw/customer_base.csv"
  + s3_directory_structure = {
      "raw" = "s3://customer-group-dev-data-123456789/raw/"
      "cleaned" = "s3://customer-group-dev-data-123456789/cleaned/"
      ...
    }
```

### terraform apply 完成后
```
Apply complete! Resources have been created.

Outputs:
s3_bucket_name = "customer-group-dev-data-123456789"
s3_bucket_arn = "arn:aws:s3:::customer-group-dev-data-123456789"
...
```

---

## ⚠️ 常见错误及解决

| 错误 | 原因 | 解决方案 |
|------|------|---------|
| `file does not exist` | CSV文件路径错误 | 确保在 `infra/` 目录中，CSV在上层目录 |
| `AccessDenied` | AWS权限不足 | 运行 `aws sts get-caller-identity` 检查凭证 |
| `Unsupported block type` | Terraform版本过低 | 升级到 1.14+ |
| `BucketAlreadyOwnedByYou` | bucket名称冲突 | 修改 `terraform.tfvars` 中的 `project_name` |
| `Error: configuration should not have any outputs` | 状态文件冲突 | 删除 `terraform.tfstate` 后重新运行 |

---

## 🔗 文件位置

```
项目根目录/
├── infra/
│   ├── main.tf                 # 主配置（S3+Glue模块）
│   ├── s3_data_upload.tf      # ⭐ CSV上传配置
│   ├── provider.tf            # AWS提供商配置
│   ├── variables.tf           # 变量定义
│   ├── outputs.tf             # 输出定义
│   ├── terraform.tfvars       # 变量值（需自建）
│   ├── terraform.tfstate      # 状态文件（自动生成）
│   └── modules/               # Glue和S3模块
│
├── customer_base.csv          # ⭐ 源数据
├── customer_behavior_assets.csv # ⭐ 源数据
├── README.md                  # 项目说明（已更新）
└── UPDATE_SUMMARY.md          # ⭐ 更新总结
```

---

## 🎯 检查清单

部署前：
- [ ] `terraform version` >= 1.14.0
- [ ] `aws --version` 已安装
- [ ] `aws configure` 已运行
- [ ] CSV文件存在于项目根目录

部署后：
- [ ] `terraform apply` 无错误
- [ ] `terraform output` 显示bucket名称
- [ ] `aws s3 ls s3://bucket/raw/` 显示2个CSV文件
- [ ] 文件大小正确

---

## 💬 获取帮助

详细信息见：[TERRAFORM_DEPLOYMENT_GUIDE.md](../docs/feature-engineering/TERRAFORM_DEPLOYMENT_GUIDE.md)

常见问题见：README.md 的 "常见问题" 部分

---

**更新**: 2025-12-06
