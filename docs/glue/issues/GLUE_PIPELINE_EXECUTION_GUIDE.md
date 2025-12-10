# AWS Glue Pipeline 执行指南

## 问题背景

原始的 Glue 作业在执行时遇到 `EntityNotFoundException` 错误，原因是 Glue Catalog 中不存在所需的表。这是因为原始数据和清洗后的数据都需要先通过 AWS Glue Crawlers 进行注册。

## 解决方案架构

现在已经实现了一个完整的数据管道，包含以下步骤：

```
Raw CSV Data (S3)
         ↓
Raw Crawlers (自动发现)
         ↓
Glue Catalog: raw_* 表
         ↓
Data Cleansing Job (清洗数据)
         ↓
Cleaned Parquet (S3)
         ↓
Cleaned Crawlers (自动发现)
         ↓
Glue Catalog: cleaned_* 表
         ↓
Feature Engineering Job (生成特征)
         ↓
Features Parquet (S3)
```

## Terraform 资源

已经创建了 4 个 Glue Crawlers：

### 原始数据爬虫
1. **raw_customer_base**: `s3://bucket/raw/customer_base.csv`
   - 创建表: `raw_customer_base`
   - 数据库: `customer_raw_db`

2. **raw_customer_behavior**: `s3://bucket/raw/customer_behavior_assets.csv`
   - 创建表: `raw_customer_behavior_assets`
   - 数据库: `customer_raw_db`

### 清洗后数据爬虫
3. **cleaned_customer_base**: `s3://bucket/cleaned/customer_base/`
   - 创建表: `cleaned_customer_base`
   - 数据库: `customer_cleaned_db`

4. **cleaned_customer_behavior**: `s3://bucket/cleaned/customer_behavior/`
   - 创建表: `cleaned_customer_behavior`
   - 数据库: `customer_cleaned_db`

## 第一步：部署 Terraform 基础设施

```bash
cd infra

# 初始化 Terraform
terraform init

# 查看计划（检查将创建的资源）
terraform plan

# 部署资源
terraform apply
```

## 第二步：运行原始数据爬虫

在 Glue 完成部署后，需要手动运行原始数据爬虫来发现 CSV 文件的schema：

### 方法 1：使用 AWS 控制台
1. 进入 AWS Glue 控制台
2. 导航到 Crawlers
3. 选择 `{project}-{env}-raw-customer-base-crawler`
4. 点击 "Run crawler"
5. 等待爬虫完成（通常 1-2 分钟）
6. 重复步骤 3-5 运行 `raw-customer-behavior-crawler`

### 方法 2：使用 AWS CLI
```bash
# 运行 customer_base 爬虫
aws glue start-crawler --name "project-dev-raw-customer-base-crawler"

# 运行 customer_behavior 爬虫
aws glue start-crawler --name "project-dev-raw-customer-behavior-crawler"

# 检查爬虫状态
aws glue get-crawler --name "project-dev-raw-customer-base-crawler"
```

### 方法 3：使用 Terraform（推荐）

可以添加以下 Terraform 代码自动运行爬虫：

```hcl
# 在 triggers.tf 中添加

resource "aws_glue_trigger" "run_raw_crawlers" {
  name = "${var.project_name}-${var.environment}-run-raw-crawlers"
  type = "ON_DEMAND"

  actions {
    job_name = aws_glue_crawler.raw_customer_base.name
  }

  actions {
    job_name = aws_glue_crawler.raw_customer_behavior.name
  }
}
```

## 第三步：验证原始表已创建

运行爬虫后，可以验证表是否成功创建：

```bash
# 列出 customer_raw_db 中的表
aws glue get-tables --database-name customer_raw_db

# 获取具体表的信息
aws glue get-table --database-name customer_raw_db --name raw_customer_base
```

或在 Athena 中查询：
```sql
SELECT * FROM customer_raw_db.raw_customer_base LIMIT 10;
SELECT * FROM customer_raw_db.raw_customer_behavior_assets LIMIT 10;
```

## 第四步：运行数据清洗作业

确认原始表存在后，可以运行第一个 Glue Job：

### 使用 AWS 控制台
1. 进入 AWS Glue 控制台 > Jobs
2. 选择 `customer-data-cleansing` 作业
3. 点击 "Run job"
4. 等待作业完成

### 使用 AWS CLI
```bash
aws glue start-job-run --job-name customer-data-cleansing
```

监控作业状态：
```bash
# 获取最新的作业运行
aws glue get-job-runs --job-name customer-data-cleansing --max-items 1

# 查看详细的作业日志
aws logs tail /aws-glue/jobs/customer-data-cleansing --follow
```

## 第五步：运行清洗后数据爬虫

数据清洗作业完成后，运行爬虫来注册清洗后的表：

```bash
# 运行 cleaned_customer_base 爬虫
aws glue start-crawler --name "project-dev-cleaned-customer-base-crawler"

# 运行 cleaned_customer_behavior 爬虫
aws glue start-crawler --name "project-dev-cleaned-customer-behavior-crawler"
```

## 第六步：验证清洗表已创建

```bash
# 列出 customer_cleaned_db 中的表
aws glue get-tables --database-name customer_cleaned_db

# 在 Athena 中查询
SELECT * FROM customer_cleaned_db.cleaned_customer_base LIMIT 10;
SELECT * FROM customer_cleaned_db.cleaned_customer_behavior LIMIT 10;
```

## 第七步：运行特征工程作业

现在可以安全地运行第二个 Glue Job：

```bash
aws glue start-job-run --job-name customer-feature-engineering
```

## 完整自动化流程（使用 AWS Lambda 或 Step Functions）

为了完全自动化整个流程，可以创建一个 AWS Step Functions 状态机：

```json
{
  "Comment": "Customer Data Pipeline",
  "StartAt": "RawDataCrawlers",
  "States": {
    "RawDataCrawlers": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startCrawler.sync",
      "Parameters": {
        "Name": "project-dev-raw-customer-base-crawler"
      },
      "Next": "DataCleansingJob"
    },
    "DataCleansingJob": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "customer-data-cleansing"
      },
      "Next": "CleanedDataCrawlers"
    },
    "CleanedDataCrawlers": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startCrawler.sync",
      "Parameters": {
        "Name": "project-dev-cleaned-customer-base-crawler"
      },
      "Next": "FeatureEngineeringJob"
    },
    "FeatureEngineeringJob": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "customer-feature-engineering"
      },
      "End": true
    }
  }
}
```

## 故障排查

### 问题 1: 爬虫仍然失败或不创建表

**原因**:
- S3 文件路径不正确
- IAM 权限不足

**解决**:
```bash
# 验证 S3 文件是否存在
aws s3 ls s3://bucket/raw/

# 查看爬虫日志
aws logs tail /aws-glue/crawlers/project-dev-raw-customer-base-crawler
```

### 问题 2: Glue Job 仍然显示 EntityNotFoundException

**原因**:
- 爬虫尚未完成运行
- 表还未创建成功
- 表名或数据库名不匹配

**解决**:
```bash
# 等待爬虫完成
aws glue get-crawler --name "project-dev-raw-customer-base-crawler"
# 检查 State: 应该是 READY（不是 RUNNING）

# 验证表是否存在
aws glue get-table --database-name customer_raw_db --name raw_customer_base
```

### 问题 3: CSV 数据类型推断错误

如果爬虫推断的数据类型不正确，可以手动编辑表schema：

```bash
# 获取表定义
aws glue get-table --database-name customer_raw_db --name raw_customer_base

# 更新表定义（可在 AWS 控制台手动编辑）
```

## 性能最佳实践

1. **爬虫配置**:
   - 使用 `table_prefix` 避免名称冲突
   - 设置 `update_behavior = "UPDATE_IN_DATABASE"` 自动更新schema

2. **Glue Job 优化**:
   - 使用 Job Bookmarks 进行增量处理
   - 合理配置 Worker 数量和类型
   - 使用 Partition Projection 优化查询性能

3. **成本优化**:
   - 使用 `S3 Intelligent-Tiering` 管理存储成本
   - 定期清理临时文件
   - 使用 Glue Job 的 `--TempDir` 参数管理中间数据

## 监控和告警

建议添加 CloudWatch 告警来监控：

1. **爬虫运行状态**:
   - 爬虫是否失败
   - 爬虫运行时间是否过长

2. **Glue Job 执行**:
   - Job 是否失败
   - Job 执行时间
   - 处理的记录数量

3. **表数据质量**:
   - 记录数量变化
   - 空值比例

```bash
# 创建 CloudWatch 告警
aws cloudwatch put-metric-alarm \
  --alarm-name glue-crawler-failure \
  --alarm-description "Alert when Glue crawler fails" \
  --metric-name CrawlerFailures \
  --namespace AWS/Glue \
  --statistic Sum \
  --period 3600 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold
```

## 总结

现在你的 Glue Pipeline 已经完整配置：

✅ 4 个 Crawlers 用于自动发现和注册表
✅ 2 个 Glue Jobs 用于数据处理
✅ 完整的数据流从原始数据到特征
✅ Terraform 基础设施即代码管理

只需按照上述步骤运行爬虫和作业，就可以成功处理客户数据了！
