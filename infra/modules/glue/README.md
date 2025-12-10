# AWS Glue Terraform Module

## 概述

此模块用于管理AWS Glue ETL管道的所有资源，包括Databases、Crawlers、Jobs、Triggers和CloudWatch告警。

## 架构特点

- **JSON驱动配置**: 从`glue_jobs_config.json`读取配置，无需修改Terraform代码
- **完全自动化**: 使用`for_each`循环动态创建所有资源
- **智能依赖管理**: 自动处理资源间的依赖关系
- **最佳实践**: 启用Job Bookmarks、Continuous Logging、CloudWatch Insights

## 资源创建

此模块创建以下资源：

- 1个IAM角色及权限策略
- N个Glue Catalog数据库
- N个Glue Crawlers（带调度）
- N个Glue Jobs（支持依赖关系）
- 2N个Glue Triggers（调度+条件触发）
- N个CloudWatch告警

## 使用方法

### 基本用法

```hcl
module "glue_pipeline" {
  source = "./modules/glue"

  config_file_path = "${path.root}/../glue_scripts/config/glue_jobs_config.json"
  s3_bucket_name   = module.s3_bucket.bucket_id
  s3_bucket_arn    = module.s3_bucket.bucket_arn
  environment      = "dev"
  project_name     = "customer-pipeline"

  tags = {
    Team = "DataEngineering"
  }
}
```

## 输入变量

| 变量名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| `config_file_path` | string | 否 | `../../glue_scripts/config/glue_jobs_config.json` | JSON配置文件路径 |
| `s3_bucket_name` | string | 是 | - | S3桶名称 |
| `s3_bucket_arn` | string | 是 | - | S3桶ARN |
| `environment` | string | 是 | - | 环境名称 |
| `project_name` | string | 是 | - | 项目名称 |
| `glue_role_name` | string | 否 | `GlueCustomerDataRole` | IAM角色名称 |
| `enable_job_bookmarks` | bool | 否 | `true` | 启用Job Bookmarks |
| `enable_continuous_logging` | bool | 否 | `true` | 启用持续日志 |
| `tags` | map(string) | 否 | `{}` | 资源标签 |

## 输出

| 输出名 | 说明 |
|--------|------|
| `glue_role_arn` | IAM角色ARN |
| `database_names` | 所有数据库名称列表 |
| `crawler_names` | 所有Crawler名称列表 |
| `job_names` | 所有Job名称列表 |
| `glue_resources_summary` | 资源统计汇总 |

## JSON配置格式

### Glue Jobs配置

```json
{
  "glue_jobs": [
    {
      "job_name": "customer-data-cleansing",
      "job_type": "glueetl",
      "description": "清洗和标准化客户数据",
      "script_location": "s3://your-bucket/scripts/1_data_cleansing.py",
      "max_capacity": 2,
      "worker_type": "G.1X",
      "glue_version": "4.0",
      "timeout": 30,
      "max_retries": 1,
      "parameters": {
        "--INPUT_DATABASE": "customer_raw_db",
        "--OUTPUT_BUCKET": "s3://your-bucket/cleaned"
      },
      "schedule": "cron(0 2 * * ? *)",
      "dependencies": ["customer-data-crawler"]
    }
  ]
}
```

**关键字段说明**：
- `job_name`: 唯一的Job标识符
- `job_type`: 固定为"glueetl"（Spark ETL）
- `script_location`: S3上的Python脚本路径（使用`s3://your-bucket`占位符）
- `parameters`: Job运行参数，支持`s3://your-bucket`占位符
- `schedule`: 调度表达式（AWS cron格式，UTC时区）
- `dependencies`: 此Job依赖的其他Jobs或Crawlers列表

### Glue Crawlers配置

```json
{
  "crawlers": [
    {
      "crawler_name": "customer-data-crawler",
      "database_name": "customer_raw_db",
      "table_prefix": "raw_",
      "s3_paths": [
        "s3://your-bucket/raw/customer_base/",
        "s3://your-bucket/raw/customer_behavior_assets/"
      ],
      "schedule": "cron(0 0 * * ? *)",
      "exclusions": ["**_temporary_**", "**_metadata_**"]
    }
  ]
}
```

**关键字段说明**：
- `crawler_name`: Crawler唯一标识符
- `database_name`: 目标数据库名称
- `table_prefix`: 创建表时的前缀
- `s3_paths`: 要爬取的S3路径列表
- `schedule`: 爬取调度表达式
- `exclusions`: 排除模式列表

### Glue Databases配置

```json
{
  "databases": [
    {
      "database_name": "customer_raw_db",
      "description": "原始客户数据"
    }
  ]
}
```

## 依赖关系配置

### Job依赖Job

```json
{
  "job_name": "feature-engineering",
  "dependencies": ["data-cleansing"]
}
```

Terraform会自动创建条件Trigger，确保`data-cleansing`成功后才执行`feature-engineering`。

### Job依赖Crawler

```json
{
  "job_name": "data-cleansing",
  "dependencies": ["customer-data-crawler"]
}
```

Terraform会创建条件Trigger，等待Crawler完成。

## 添加新Job的步骤

1. 编写Python ETL脚本
2. 上传脚本到S3：
   ```bash
   aws s3 cp glue_scripts/new_script.py s3://your-bucket/scripts/
   ```
3. 在JSON配置中添加Job定义
4. 运行Terraform：
   ```bash
   terraform plan
   terraform apply
   ```

## 修改现有配置

修改JSON配置文件后，运行：

```bash
terraform plan  # 查看变更
terraform apply # 应用变更
```

**注意**: 修改Job配置不会影响正在运行的Job，需要重新启动才能使用新配置。

## 最佳实践

### 1. 脚本管理
- 将Python脚本放在`glue_scripts/`目录
- 在部署前上传到S3
- 使用相对路径引用数据库和表

### 2. 调度配置
- 使用AWS cron表达式（UTC时间）
- 确保Crawler先于Job执行
- Job之间保持适当间隔

### 3. 监控和告警
- 为关键Job配置失败告警
- 监控数据质量指标
- 设置合理的threshold值

### 4. 成本优化
- 使用合适的worker type（G.1X或G.2X）
- 设置合理的timeout和max_retries
- 启用Job Bookmarks避免重复处理

## 故障排查

### Terraform Plan显示很多变更

**原因**: JSON配置中的S3路径不匹配
**解决**: 确保JSON中使用`s3://your-bucket`占位符

### Job运行失败

**检查项**:
1. IAM角色权限是否足够
2. S3脚本路径是否正确（`aws s3 ls s3://bucket/scripts/`）
3. 输入数据库和表是否存在（`aws glue get-database --name xxx`）
4. CloudWatch日志查看详细错误：
   ```bash
   aws logs tail /aws-glue/jobs/output --follow
   ```

### Crawler未按预期触发

**检查项**:
1. 调度表达式是否正确（AWS cron格式，UTC）
2. 依赖的Job/Crawler状态
3. Trigger是否启用：
   ```bash
   aws glue get-trigger --name xxx-trigger
   ```

### 资源冲突

**症状**: 创建资源时报告资源已存在
**解决**:
```bash
terraform import module.glue_pipeline.aws_glue_job.jobs["job-name"] job-name
```

## 文件结构说明

- `main.tf`: JSON配置读取和数据转换
- `variables.tf`: 输入变量定义
- `iam.tf`: IAM角色和策略
- `databases.tf`: Glue数据库
- `crawlers.tf`: Glue Crawlers
- `jobs.tf`: Glue Jobs
- `triggers.tf`: Triggers（调度和条件）
- `cloudwatch.tf`: CloudWatch告警
- `outputs.tf`: 模块输出

## 完整运行流程

### 数据处理管道执行顺序

整个数据处理管道分为4个步骤，必须按顺序执行：

```
1. Raw Data Crawlers (发现原始数据表结构)
   ↓
2. Data Cleansing Job (数据清洗)
   ↓
3. Cleaned Data Crawlers (发现清洗后数据表结构)
   ↓
4. Feature Engineering Job (特征工程)
```

### 步骤1: 运行原始数据 Crawlers

首先运行 crawlers 来发现原始 CSV 文件的表结构并在 Glue Catalog 中创建表。

```bash
# 启动原始数据 crawlers
aws glue start-crawler --name case-customer-group-dev-raw-customer-base-crawler
aws glue start-crawler --name case-customer-group-dev-raw-customer-behavior-crawler

# 等待 crawlers 完成（通常需要 30-60 秒）
# 检查状态（READY 表示完成）
aws glue get-crawler --name case-customer-group-dev-raw-customer-base-crawler --query "Crawler.State" --output text
aws glue get-crawler --name case-customer-group-dev-raw-customer-behavior-crawler --query "Crawler.State" --output text

# 验证表已创建
aws glue get-tables --database-name customer_raw_db --query "TableList[*].[Name, StorageDescriptor.Location]" --output table
```

**预期输出**：
```
raw_customer_base_csv            | s3://bucket/raw/customer_base.csv
raw_customer_behavior_assets_csv | s3://bucket/raw/customer_behavior_assets.csv
```

### 步骤2: 运行数据清洗 Job

原始数据表创建后，运行数据清洗 Job。

```bash
# 启动数据清洗 Job
aws glue start-job-run --job-name case-customer-group-dev-customer-data-cleansing

# 获取 Job Run ID（从上一条命令的输出中）
JOB_RUN_ID="jr_xxxxx"

# 监控 Job 状态
aws glue get-job-run --job-name case-customer-group-dev-customer-data-cleansing --run-id $JOB_RUN_ID --query "JobRun.JobRunState" --output text

# 查看 Job 日志（如果失败）
aws logs tail /aws-glue/jobs/output --follow --filter-pattern "case-customer-group-dev-customer-data-cleansing"
```

**Job 状态说明**：
- `RUNNING`: 正在运行
- `SUCCEEDED`: 成功完成
- `FAILED`: 失败（查看日志排查）
- `STOPPED`: 被手动停止

**验证输出数据**：
```bash
# 检查清洗后的数据文件
aws s3 ls s3://case-customer-group-dev-data-797606048301/cleaned/customer_base/ --recursive
aws s3 ls s3://case-customer-group-dev-data-797606048301/cleaned/customer_behavior/ --recursive
```

### 步骤3: 运行清洗数据 Crawlers

数据清洗完成后，运行 crawlers 来发现清洗后的 Parquet 文件表结构。

```bash
# 启动清洗数据 crawlers
aws glue start-crawler --name case-customer-group-dev-cleaned-customer-base-crawler
aws glue start-crawler --name case-customer-group-dev-cleaned-customer-behavior-crawler

# 等待 crawlers 完成
aws glue get-crawler --name case-customer-group-dev-cleaned-customer-base-crawler --query "Crawler.State" --output text
aws glue get-crawler --name case-customer-group-dev-cleaned-customer-behavior-crawler --query "Crawler.State" --output text

# 验证表已创建
aws glue get-tables --database-name customer_cleaned_db --query "TableList[*].[Name, StorageDescriptor.Location]" --output table
```

**预期输出**：
```
cleaned_customer_base     | s3://bucket/cleaned/customer_base
cleaned_customer_behavior | s3://bucket/cleaned/customer_behavior
```

### 步骤4: 运行特征工程 Job

清洗数据表创建后，运行特征工程 Job。

```bash
# 启动特征工程 Job
aws glue start-job-run --job-name case-customer-group-dev-customer-feature-engineering

# 获取 Job Run ID
JOB_RUN_ID="jr_xxxxx"

# 监控 Job 状态
aws glue get-job-run --job-name case-customer-group-dev-customer-feature-engineering --run-id $JOB_RUN_ID --query "JobRun.JobRunState" --output text

# 查看 Job 日志
aws logs tail /aws-glue/jobs/output --follow --filter-pattern "case-customer-group-dev-customer-feature-engineering"
```

**验证输出数据**：
```bash
# 检查特征工程输出文件
aws s3 ls s3://case-customer-group-dev-data-797606048301/features/customer_features/ --recursive
```

### 一键运行脚本

创建一个 shell 脚本来自动化整个流程：

```bash
#!/bin/bash
# run_pipeline.sh - 运行完整的数据处理管道

set -e  # 遇到错误立即退出

PROJECT_PREFIX="case-customer-group-dev"

echo "=========================================="
echo "步骤 1/4: 运行原始数据 Crawlers"
echo "=========================================="
aws glue start-crawler --name ${PROJECT_PREFIX}-raw-customer-base-crawler
aws glue start-crawler --name ${PROJECT_PREFIX}-raw-customer-behavior-crawler

echo "等待 crawlers 完成..."
while true; do
    STATE1=$(aws glue get-crawler --name ${PROJECT_PREFIX}-raw-customer-base-crawler --query "Crawler.State" --output text)
    STATE2=$(aws glue get-crawler --name ${PROJECT_PREFIX}-raw-customer-behavior-crawler --query "Crawler.State" --output text)

    if [ "$STATE1" = "READY" ] && [ "$STATE2" = "READY" ]; then
        echo "✓ Crawlers 完成"
        break
    fi
    echo "  状态: $STATE1, $STATE2"
    sleep 10
done

echo ""
echo "=========================================="
echo "步骤 2/4: 运行数据清洗 Job"
echo "=========================================="
JOB_RUN_ID=$(aws glue start-job-run --job-name ${PROJECT_PREFIX}-customer-data-cleansing --query "JobRunId" --output text)
echo "Job Run ID: $JOB_RUN_ID"

echo "等待 Job 完成..."
while true; do
    STATE=$(aws glue get-job-run --job-name ${PROJECT_PREFIX}-customer-data-cleansing --run-id $JOB_RUN_ID --query "JobRun.JobRunState" --output text)

    if [ "$STATE" = "SUCCEEDED" ]; then
        echo "✓ 数据清洗完成"
        break
    elif [ "$STATE" = "FAILED" ] || [ "$STATE" = "STOPPED" ]; then
        echo "✗ Job 失败: $STATE"
        exit 1
    fi
    echo "  状态: $STATE"
    sleep 15
done

echo ""
echo "=========================================="
echo "步骤 3/4: 运行清洗数据 Crawlers"
echo "=========================================="
aws glue start-crawler --name ${PROJECT_PREFIX}-cleaned-customer-base-crawler
aws glue start-crawler --name ${PROJECT_PREFIX}-cleaned-customer-behavior-crawler

echo "等待 crawlers 完成..."
while true; do
    STATE1=$(aws glue get-crawler --name ${PROJECT_PREFIX}-cleaned-customer-base-crawler --query "Crawler.State" --output text)
    STATE2=$(aws glue get-crawler --name ${PROJECT_PREFIX}-cleaned-customer-behavior-crawler --query "Crawler.State" --output text)

    if [ "$STATE1" = "READY" ] && [ "$STATE2" = "READY" ]; then
        echo "✓ Crawlers 完成"
        break
    fi
    echo "  状态: $STATE1, $STATE2"
    sleep 10
done

echo ""
echo "=========================================="
echo "步骤 4/4: 运行特征工程 Job"
echo "=========================================="
JOB_RUN_ID=$(aws glue start-job-run --job-name ${PROJECT_PREFIX}-customer-feature-engineering --query "JobRunId" --output text)
echo "Job Run ID: $JOB_RUN_ID"

echo "等待 Job 完成..."
while true; do
    STATE=$(aws glue get-job-run --job-name ${PROJECT_PREFIX}-customer-feature-engineering --run-id $JOB_RUN_ID --query "JobRun.JobRunState" --output text)

    if [ "$STATE" = "SUCCEEDED" ]; then
        echo "✓ 特征工程完成"
        break
    elif [ "$STATE" = "FAILED" ] || [ "$STATE" = "STOPPED" ]; then
        echo "✗ Job 失败: $STATE"
        exit 1
    fi
    echo "  状态: $STATE"
    sleep 15
done

echo ""
echo "=========================================="
echo "✓ 管道执行完成！"
echo "=========================================="
```

**使用方法**：
```bash
chmod +x run_pipeline.sh
./run_pipeline.sh
```

### 常见问题排查

#### 问题1: Crawler 运行后没有创建表

**原因**：
- S3 路径不存在或为空
- IAM 角色没有 S3 读取权限
- 文件格式不被识别

**排查**：
```bash
# 检查 S3 文件是否存在
aws s3 ls s3://bucket/raw/ --recursive

# 检查 Crawler 配置
aws glue get-crawler --name crawler-name

# 查看 Crawler 日志
aws glue get-crawler-metrics --crawler-name-list crawler-name
```

#### 问题2: Job 找不到表 (EntityNotFoundException)

**原因**：Crawler 还没有运行或运行失败

**解决**：
```bash
# 确认表是否存在
aws glue get-table --database-name customer_raw_db --name raw_customer_base_csv

# 如果不存在，运行 crawler
aws glue start-crawler --name raw-customer-base-crawler
```

#### 问题3: Job 运行失败

**排查步骤**：
```bash
# 1. 查看 Job Run 详情
aws glue get-job-run --job-name job-name --run-id run-id

# 2. 查看 CloudWatch 日志
aws logs tail /aws-glue/jobs/output --follow

# 3. 查看错误日志
aws logs tail /aws-glue/jobs/error --follow

# 4. 检查 IAM 权限
aws iam get-role --role-name GlueCustomerDataRole
```

#### 问题4: 数据输出路径错误

**检查 Job 参数**：
```bash
aws glue get-job --job-name job-name --query "Job.DefaultArguments"
```

确保参数中的 S3 路径正确。

### 监控和日志

#### 查看所有 Crawlers 状态
```bash
aws glue list-crawlers --query "CrawlerNames" --output table | \
  xargs -I {} aws glue get-crawler --name {} --query "Crawler.[Name,State,LastCrawl.Status]" --output table
```

#### 查看所有 Jobs 最近运行状态
```bash
aws glue list-jobs --query "JobNames" --output text | \
  xargs -I {} aws glue get-job-runs --job-name {} --max-results 1 --query "JobRuns[0].[JobName,JobRunState,StartedOn]" --output table
```

#### 实时监控 Job 日志
```bash
# 输出日志
aws logs tail /aws-glue/jobs/output --follow

# 错误日志
aws logs tail /aws-glue/jobs/error --follow

# 过滤特定 Job
aws logs tail /aws-glue/jobs/output --follow --filter-pattern "job-name"
```

## 参考资源

- [AWS Glue文档](https://docs.aws.amazon.com/glue/)
- [Terraform AWS Provider - Glue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_job)
- [AWS Glue Cron表达式](https://docs.aws.amazon.com/glue/latest/dg/monitor-glue.html)
- [Glue Job Parameters](https://docs.aws.amazon.com/glue/latest/dg/aws-glue-programming-etl-glue-arguments.html)
