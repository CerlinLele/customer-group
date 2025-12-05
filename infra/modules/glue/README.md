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

## 参考资源

- [AWS Glue文档](https://docs.aws.amazon.com/glue/)
- [Terraform AWS Provider - Glue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_job)
- [AWS Glue Cron表达式](https://docs.aws.amazon.com/glue/latest/dg/monitor-glue.html)
- [Glue Job Parameters](https://docs.aws.amazon.com/glue/latest/dg/aws-glue-programming-etl-glue-arguments.html)
