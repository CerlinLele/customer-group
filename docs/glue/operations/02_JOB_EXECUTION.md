# Glue Job 执行指南

完整的 Job 创建、配置和执行指南。

## Job 类型

### Spark ETL Jobs
用于大规模数据处理的 Spark 作业。

**特点**:
- 支持 Python 和 Scala
- 分布式处理
- 支持 Spark SQL

**适用场景**:
- 数据清洗
- 数据转换
- 特征工程

### Python Shell Jobs
轻量级 Python 脚本执行。

**特点**:
- 单机执行
- 快速启动
- 适合小数据量

**适用场景**:
- 数据验证
- 元数据更新
- 简单转换

### Ray Jobs
分布式 Python 处理。

**特点**:
- 支持 Python 3.9+
- 分布式处理
- 灵活的资源配置

**适用场景**:
- 机器学习
- 复杂计算
- 自定义处理

## Job 创建

### 使用 Terraform 创建

```hcl
resource "aws_glue_job" "customer_data_cleansing" {
  name              = "customer-data-cleansing"
  role_arn          = aws_iam_role.glue_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.scripts.id}/1_data_cleansing.py"
    python_version  = "3"
  }

  # 资源配置
  max_capacity      = 4
  worker_type       = "G.2X"
  number_of_workers = null  # 使用 max_capacity 时设为 null
  timeout           = 60

  # 默认参数
  default_arguments = {
    "--job-bookmark-option"      = "job-bookmark-enabled"
    "--TempDir"                  = "s3://${aws_s3_bucket.temp.id}/glue/"
    "--enable-glue-datacatalog"  = "true"
    "--enable-spark-ui"          = "true"
    "--spark-event-logs-path"    = "s3://${aws_s3_bucket.logs.id}/spark-logs/"
  }

  # 标签
  tags = {
    Environment = "prod"
    Owner       = "data-team"
  }
}
```

### 使用 AWS CLI 创建

```bash
aws glue create-job \
  --name customer-data-cleansing \
  --role arn:aws:iam::ACCOUNT_ID:role/glue-role \
  --command Name=glueetl,ScriptLocation=s3://bucket/1_data_cleansing.py,PythonVersion=3 \
  --max-capacity 4 \
  --timeout 60 \
  --default-arguments '{
    "--job-bookmark-option": "job-bookmark-enabled",
    "--TempDir": "s3://bucket/temp/",
    "--enable-glue-datacatalog": "true"
  }'
```

## Job 配置

### 资源配置

#### 按容量配置（推荐）

```hcl
resource "aws_glue_job" "job" {
  max_capacity = 4  # 4 DPU
  # 自动分配 worker
}
```

#### 按 Worker 数量配置

```hcl
resource "aws_glue_job" "job" {
  worker_type       = "G.2X"
  number_of_workers = 2
  # 2 个 G.2X worker = 4 DPU
}
```

### Worker 类型对比

| 类型 | 内存 | vCPU | DPU | 成本/小时 |
|------|------|------|-----|----------|
| G.1X | 4 GB | 1 | 1 | $0.44 |
| G.2X | 16 GB | 4 | 2 | $0.88 |
| G.4X | 64 GB | 16 | 8 | $3.52 |
| Z.2X | 128 GB | 32 | 16 | $7.04 |

### 超时配置

```hcl
resource "aws_glue_job" "job" {
  timeout = 60  # 分钟
}
```

### 参数配置

```hcl
resource "aws_glue_job" "job" {
  default_arguments = {
    # 数据目录
    "--enable-glue-datacatalog" = "true"

    # 临时目录
    "--TempDir" = "s3://bucket/temp/"

    # Job Bookmark
    "--job-bookmark-option" = "job-bookmark-enabled"

    # Spark UI
    "--enable-spark-ui" = "true"
    "--spark-event-logs-path" = "s3://bucket/spark-logs/"

    # 自定义参数
    "--input_path" = "s3://bucket/input/"
    "--output_path" = "s3://bucket/output/"
  }
}
```

## Job 执行

### 运行 Job

```bash
# 基本运行
aws glue start-job-run --job-name customer-data-cleansing

# 带参数运行
aws glue start-job-run \
  --job-name customer-data-cleansing \
  --arguments '{
    "--input_path": "s3://bucket/input/",
    "--output_path": "s3://bucket/output/"
  }'

# 获取 Job Run ID
JOB_RUN_ID=$(aws glue start-job-run \
  --job-name customer-data-cleansing \
  --query 'JobRunId' \
  --output text)
```

### 查看执行状态

```bash
# 查看单个 Job Run
aws glue get-job-run \
  --job-name customer-data-cleansing \
  --run-id $JOB_RUN_ID

# 查看所有 Job Runs
aws glue get-job-runs --job-name customer-data-cleansing

# 查看 Job Run 状态
aws glue get-job-run \
  --job-name customer-data-cleansing \
  --run-id $JOB_RUN_ID \
  --query 'JobRun.JobRunState'
```

### 停止 Job 执行

```bash
# 停止单个 Job Run
aws glue batch-stop-job-run \
  --job-name customer-data-cleansing \
  --job-run-ids $JOB_RUN_ID

# 停止所有 Job Runs
aws glue batch-stop-job-run \
  --job-name customer-data-cleansing \
  --job-run-ids $(aws glue get-job-runs \
    --job-name customer-data-cleansing \
    --query 'JobRuns[?JobRunState==`RUNNING`].Id' \
    --output text)
```

## 监控和日志

### 查看日志

```bash
# 查看最近的日志
aws logs tail /aws-glue/jobs/customer-data-cleansing --follow

# 查看特定时间范围的日志
aws logs filter-log-events \
  --log-group-name /aws-glue/jobs/customer-data-cleansing \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --end-time $(date +%s)000

# 搜索错误
aws logs filter-log-events \
  --log-group-name /aws-glue/jobs/customer-data-cleansing \
  --filter-pattern "ERROR"
```

### 查看指标

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

### 设置告警

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
  --evaluation-periods 1 \
  --dimensions Name=JobName,Value=customer-data-cleansing
```

## 脚本开发

### 基础脚本结构

```python
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# 获取参数
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'input_path', 'output_path'])

# 初始化 Spark 和 Glue
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# 读取数据
df = spark.read.parquet(args['input_path'])

# 处理数据
df_processed = df.filter(df.customer_id.isNotNull())

# 写入数据
df_processed.write.mode("overwrite").parquet(args['output_path'])

# 完成 Job
job.commit()
```

### 错误处理

```python
try:
    # 处理数据
    df_processed = process_data(df)

    # 写入数据
    df_processed.write.mode("overwrite").parquet(output_path)

    logger.info("Job completed successfully")
except Exception as e:
    logger.error(f"Job failed: {e}")
    raise
finally:
    job.commit()
```

### 日志记录

```python
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

logger.info(f"Processing {df.count()} rows")
logger.warning("This is a warning")
logger.error("This is an error")
```

## 最佳实践

### 1. 使用参数化配置

```python
# ✅ 好
input_path = args['input_path']
output_path = args['output_path']

# ❌ 不好
input_path = "s3://bucket/input/"
output_path = "s3://bucket/output/"
```

### 2. 添加数据验证

```python
# 验证输入数据
if df.count() == 0:
    raise ValueError("Input data is empty")

# 验证输出数据
if df_processed.count() == 0:
    logger.warning("Output data is empty")
```

### 3. 使用缓存优化性能

```python
# 缓存中间结果
df_cleaned = df.dropDuplicates().persist()

# 使用缓存的数据
count = df_cleaned.count()
df_processed = df_cleaned.filter(...)
```

### 4. 处理大数据

```python
# 使用分区处理
df.repartition(100).write.mode("overwrite") \
    .partitionBy("year", "month", "day") \
    .parquet(output_path)

# 使用 Spark SQL
spark.sql("""
    SELECT * FROM input_table
    WHERE year = 2025 AND month = 12
""").write.mode("overwrite").parquet(output_path)
```

## 故障排除

### 问题: Job 超时

**解决方案**:
1. 增加 `timeout` 参数
2. 优化脚本性能
3. 增加 `max_capacity`

### 问题: 内存不足

**解决方案**:
1. 增加 `max_capacity` 或 `number_of_workers`
2. 使用更大的 `worker_type`
3. 优化脚本内存使用

### 问题: 网络连接失败

**解决方案**:
参考 [Spark 连接失败问题](../issues/01_SPARK_CONNECTION_FAILURE.md)

## 相关文档

- [Glue 操作指南](./01_OPERATIONS_GUIDE.md)
- [Glue 快速开始](../00_QUICK_START.md)
- [Spark 连接失败问题](../issues/01_SPARK_CONNECTION_FAILURE.md)

---

**最后更新**: 2025-12-10
