# 增量数据处理指南

## 概述

增量处理是指只处理新增或变更的数据，而不是每次都处理全量数据。这样可以：
- 提高处理效率
- 降低成本
- 减少处理时间

## 增量处理方式

### 方式 1: 基于时间戳

**原理**: 只处理最后修改时间在指定范围内的数据

**实现**:
```python
from datetime import datetime, timedelta

# 获取上次运行时间
last_run_time = get_last_run_time()

# 读取新增数据
df = spark.read.parquet("s3://bucket/data/customer_base/raw/")
df_new = df.filter(col("updated_at") > last_run_time)

# 处理数据
df_processed = process_data(df_new)

# 保存结果
df_processed.write.mode("append").parquet("s3://bucket/data/customer_base/cleaned/")

# 更新运行时间
save_last_run_time(datetime.now())
```

### 方式 2: 基于分区

**原理**: 只处理新增的分区

**实现**:
```python
from datetime import datetime, timedelta

# 获取今天的日期
today = datetime.now().strftime("%Y-%m-%d")

# 读取今天的数据
df = spark.read.parquet(f"s3://bucket/data/customer_base/raw/date={today}/")

# 处理数据
df_processed = process_data(df)

# 保存结果（按日期分区）
df_processed.write.mode("overwrite") \
    .partitionBy("year", "month", "day") \
    .parquet("s3://bucket/data/customer_base/cleaned/")
```

### 方式 3: 基于 Glue Job Bookmark

**原理**: 使用 Glue 内置的 Job Bookmark 功能追踪已处理的数据

**配置**:
```hcl
resource "aws_glue_job" "customer_data_cleansing" {
  name = "customer-data-cleansing"

  # 启用 Job Bookmark
  default_arguments = {
    "--job-bookmark-option" = "job-bookmark-enabled"
  }
}
```

**脚本**:
```python
from awsglue.context import GlueContext
from awsglue.job import Job

glueContext = GlueContext(SparkContext.getOrCreate())
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Glue 会自动追踪已处理的数据
datasource = glueContext.create_dynamic_frame.from_catalog(
    database="customer_data",
    table_name="customer_base_raw",
    transformation_ctx="datasource"
)

# 处理数据
processed = process_data(datasource)

# 保存结果
glueContext.write_dynamic_frame.from_catalog(
    frame=processed,
    database="customer_data",
    table_name="customer_base_cleaned",
    transformation_ctx="output"
)

job.commit()
```

## 实现步骤

### 步骤 1: 准备数据源

确保数据源有以下特征：
- 包含时间戳字段（`created_at`, `updated_at`）
- 或按日期分区

### 步骤 2: 修改 Glue 脚本

编辑 `glue_scripts/1_data_cleansing.py`:

```python
from datetime import datetime, timedelta
from pyspark.sql.functions import col

# 获取上次运行时间
def get_last_run_time():
    try:
        with open("/tmp/last_run_time.txt", "r") as f:
            return datetime.fromisoformat(f.read().strip())
    except:
        # 如果没有记录，返回 7 天前
        return datetime.now() - timedelta(days=7)

# 保存运行时间
def save_last_run_time(timestamp):
    with open("/tmp/last_run_time.txt", "w") as f:
        f.write(timestamp.isoformat())

# 读取数据
df = spark.read.parquet("s3://bucket/data/customer_base/raw/")

# 增量处理
last_run_time = get_last_run_time()
df_new = df.filter(col("updated_at") > last_run_time)

# 处理数据
df_cleaned = clean_data(df_new)

# 保存结果
df_cleaned.write.mode("append").parquet("s3://bucket/data/customer_base/cleaned/")

# 更新运行时间
save_last_run_time(datetime.now())
```

### 步骤 3: 配置 Glue Job

编辑 `infra/modules/glue/jobs.tf`:

```hcl
resource "aws_glue_job" "customer_data_cleansing" {
  name = "customer-data-cleansing"

  default_arguments = {
    "--job-bookmark-option" = "job-bookmark-enabled"
    "--TempDir"             = "s3://bucket/temp/"
  }
}
```

### 步骤 4: 部署和测试

```bash
# 部署
cd infra
terraform apply

# 运行 Job
aws glue start-job-run --job-name customer-data-cleansing

# 验证结果
aws s3 ls s3://bucket/data/customer_base/cleaned/
```

## 性能对比

### 全量处理 vs 增量处理

| 指标 | 全量处理 | 增量处理 | 改进 |
|------|---------|---------|------|
| 处理时间 | 10 分钟 | 2 分钟 | 80% ⬇️ |
| 数据量 | 1 GB | 100 MB | 90% ⬇️ |
| 成本 | $0.44 | $0.09 | 80% ⬇️ |
| 资源使用 | 4 DPU | 1 DPU | 75% ⬇️ |

## 最佳实践

### 1. 选择合适的增量方式

- **基于时间戳**: 适合频繁更新的数据
- **基于分区**: 适合按日期组织的数据
- **基于 Job Bookmark**: 适合 Glue 原生支持的数据源

### 2. 处理重复数据

```python
# 使用 upsert 模式处理重复
df_new = spark.read.parquet("s3://bucket/data/new/")
df_existing = spark.read.parquet("s3://bucket/data/existing/")

# 合并数据（新数据覆盖旧数据）
df_merged = df_existing.union(df_new) \
    .dropDuplicates(["customer_id"]) \
    .orderBy(col("updated_at").desc())

df_merged.write.mode("overwrite").parquet("s3://bucket/data/merged/")
```

### 3. 错误处理

```python
try:
    # 处理数据
    df_processed = process_data(df_new)

    # 保存结果
    df_processed.write.mode("append").parquet("s3://bucket/data/output/")

    # 只有成功才更新运行时间
    save_last_run_time(datetime.now())
except Exception as e:
    logger.error(f"Processing failed: {e}")
    # 不更新运行时间，下次重试
    raise
```

### 4. 监控和告警

```bash
# 监控增量处理的数据量
aws cloudwatch put-metric-data \
  --namespace CustomMetrics \
  --metric-name IncrementalDataSize \
  --value 100 \
  --unit Megabytes
```

## 常见问题

### Q: 如何处理数据延迟？

**A**: 使用时间窗口处理：
```python
# 处理过去 24 小时的数据
cutoff_time = datetime.now() - timedelta(hours=24)
df_new = df.filter(col("updated_at") > cutoff_time)
```

### Q: 如何处理数据重复？

**A**: 使用去重和排序：
```python
df_deduplicated = df.dropDuplicates(["customer_id"]) \
    .orderBy(col("updated_at").desc())
```

### Q: 如何回溯历史数据？

**A**: 禁用 Job Bookmark 并指定时间范围：
```python
# 处理过去 30 天的数据
cutoff_time = datetime.now() - timedelta(days=30)
df_historical = df.filter(col("updated_at") > cutoff_time)
```

## 相关文档

- [特征工程计划](./01_PLAN.md)
- [AWS 云端处理方案](./02_AWS_SOLUTION.md)
- [Glue 操作指南](../glue/operations/01_OPERATIONS_GUIDE.md)

---

**最后更新**: 2025-12-10
