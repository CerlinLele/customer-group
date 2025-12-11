# AWS 云端处理方案

## 架构概览

```
S3 (原始数据)
  ↓
AWS Glue (数据清洗)
  ↓
S3 (清洗数据)
  ↓
AWS Glue (特征工程)
  ↓
S3 (特征数据)
  ↓
Athena / Redshift (查询分析)
```

## 核心组件

### 1. Amazon S3
**用途**: 数据存储
**结构**:
```
s3://bucket/
├── data/
│   ├── customer_base/
│   │   ├── raw/          # 原始数据
│   │   └── cleaned/      # 清洗数据
│   └── customer_features/  # 特征数据
├── scripts/              # Glue 脚本
└── logs/                 # 日志
```

### 2. AWS Glue
**用途**: ETL 处理
**Jobs**:
- `customer-data-cleansing` - 数据清洗
- `customer-feature-engineering` - 特征工程

**配置**:
- Worker 类型: G.2X
- 最大容量: 4
- 超时: 60 分钟

### 3. AWS Glue Data Catalog
**用途**: 元数据管理
**数据库**: `customer_data`
**表**:
- `customer_base_raw` - 原始数据
- `customer_base_cleaned` - 清洗数据
- `customer_features` - 特征数据

### 4. Amazon CloudWatch
**用途**: 监控和日志
**日志组**: `/aws-glue/jobs/`
**指标**: Job 执行时间、错误率等

### 5. AWS IAM
**用途**: 访问控制
**角色**: `glue-role`
**权限**:
- S3 读写
- Glue 操作
- CloudWatch 日志
- EC2 VPC 访问（可选）

## 部署步骤

### 前置条件
- AWS 账户
- AWS CLI 已配置
- Terraform 已安装
- 必要的 IAM 权限

### 步骤 1: 准备数据

```bash
# 上传原始数据到 S3
aws s3 cp data/customer_base.csv s3://bucket/data/customer_base/raw/
```

### 步骤 2: 部署基础设施

```bash
# 初始化 Terraform
cd infra
terraform init

# 查看变更
terraform plan

# 应用配置
terraform apply
```

### 步骤 3: 验证部署

```bash
# 查看 Glue Jobs
aws glue list-jobs

# 查看数据目录
aws glue get-databases
aws glue get-tables --database-name customer_data
```

### 步骤 4: 运行 Jobs

```bash
# 运行数据清洗
aws glue start-job-run --job-name customer-data-cleansing

# 等待完成
sleep 300

# 运行特征工程
aws glue start-job-run --job-name customer-feature-engineering
```

### 步骤 5: 验证输出

```bash
# 查看输出数据
aws s3 ls s3://bucket/data/customer_features/

# 查询数据（使用 Athena）
aws athena start-query-execution \
  --query-string "SELECT * FROM customer_data.customer_features LIMIT 10" \
  --query-execution-context Database=customer_data \
  --result-configuration OutputLocation=s3://bucket/athena-results/
```

## 成本估算

### 按需成本

| 服务 | 用量 | 单价 | 月成本 |
|------|------|------|--------|
| Glue | 10 DPU-小时 | $0.44/DPU-小时 | $4.40 |
| S3 | 100 GB | $0.023/GB | $2.30 |
| CloudWatch | 日志 | $0.50/GB | $0.50 |
| **总计** | | | **$7.20** |

### 优化建议

1. **使用 S3 生命周期策略**
   - 30 天后转移到 Glacier
   - 90 天后删除

2. **使用 Glue 预留容量**
   - 可节省 30-40% 成本

3. **优化数据格式**
   - 使用 Parquet 压缩
   - 减少存储成本

## 安全性

### 1. 数据加密

**传输中**:
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

**静止时**:
```hcl
resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### 2. 访问控制

**IAM 策略**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::bucket/data/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "glue:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### 3. 审计日志

```bash
# 启用 S3 访问日志
aws s3api put-bucket-logging \
  --bucket bucket \
  --bucket-logging-status '{
    "LoggingEnabled": {
      "TargetBucket": "log-bucket",
      "TargetPrefix": "s3-logs/"
    }
  }'
```

## 监控和告警

### CloudWatch 指标

```bash
# 查看 Job 执行时间
aws cloudwatch get-metric-statistics \
  --namespace AWS/Glue \
  --metric-name glue.driver.aggregate.numFailedTasks \
  --dimensions Name=JobName,Value=customer-data-cleansing \
  --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

### 告警规则

```bash
# Job 失败告警
aws cloudwatch put-metric-alarm \
  --alarm-name glue-job-failure \
  --alarm-description "Alert when Glue job fails" \
  --metric-name glue.driver.aggregate.numFailedTasks \
  --namespace AWS/Glue \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1
```

## 故障排除

### 问题: Job 运行失败

**检查清单**:
1. 查看 CloudWatch 日志
2. 验证 IAM 权限
3. 检查 S3 路径
4. 验证数据格式

### 问题: 性能缓慢

**解决方案**:
1. 增加 Glue worker 数量
2. 优化 Spark 配置
3. 使用数据分区
4. 优化脚本代码

### 问题: 成本过高

**优化方案**:
1. 使用预留容量
2. 优化数据格式
3. 使用 S3 生命周期策略
4. 定期清理过期数据

## 相关文档

- [特征工程计划](./01_PLAN.md)
- [增量数据处理指南](./03_INCREMENTAL_PROCESSING.md)
- [Glue 快速开始](../glue/00_QUICK_START.md)
- [Terraform 部署指南](../terraform/02_DEPLOYMENT_GUIDE.md)

---

**最后更新**: 2025-12-10
