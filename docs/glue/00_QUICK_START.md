# AWS Glue 快速开始

5 分钟快速了解和使用 AWS Glue。

## 什么是 AWS Glue？

AWS Glue 是一个完全托管的 ETL（提取、转换、加载）服务，用于：
- 发现和编目数据
- 清洗和转换数据
- 加载数据到数据仓库

## 核心概念

### 数据目录 (Data Catalog)
中央元数据存储库，包含所有数据源的信息。

### 爬虫 (Crawler)
自动扫描数据源，发现数据结构并创建表定义。

### Job
执行 ETL 任务的单位，可以是 Spark 或 Python Shell 脚本。

### 连接 (Connection)
定义如何连接到数据源（数据库、S3 等）。

## 项目中的 Glue Jobs

### 1. customer-data-cleansing
**用途**: 清洗客户基础数据
**输入**: S3 中的原始客户数据
**输出**: 清洗后的客户数据
**脚本**: `glue_scripts/1_data_cleansing.py`

### 2. customer-feature-engineering
**用途**: 特征工程，生成机器学习特征
**输入**: 清洗后的客户数据
**输出**: 特征化的客户数据
**脚本**: `glue_scripts/2_feature_engineering.py`

## 快速操作

### 查看 Job 列表
```bash
aws glue list-jobs
```

### 查看 Job 详情
```bash
aws glue get-job --name customer-data-cleansing
```

### 运行 Job
```bash
aws glue start-job-run --job-name customer-data-cleansing
```

### 查看 Job 执行状态
```bash
# 获取 job run ID
JOB_RUN_ID=$(aws glue start-job-run --job-name customer-data-cleansing --query 'JobRunId' --output text)

# 查看执行状态
aws glue get-job-run --job-name customer-data-cleansing --run-id $JOB_RUN_ID
```

### 查看 Job 日志
```bash
# 查看最近的日志
aws logs tail /aws-glue/jobs/customer-data-cleansing --follow

# 搜索特定错误
aws logs filter-log-events \
  --log-group-name /aws-glue/jobs/customer-data-cleansing \
  --filter-pattern "ERROR"
```

## 常见问题

### Q: Job 运行失败，如何调试？

**A**:
1. 查看 CloudWatch 日志
2. 检查 IAM 权限
3. 验证 S3 路径和数据格式
4. 查看 [问题修复总览](./issues/00_OVERVIEW.md)

### Q: 如何修改 Job 配置？

**A**:
1. 编辑 `infra/modules/glue/jobs.tf`
2. 运行 `terraform apply`
3. 重新运行 Job

### Q: 如何添加新的 Job？

**A**:
1. 创建 Python 脚本 `glue_scripts/your_job.py`
2. 在 `infra/modules/glue/jobs.tf` 中定义 Job
3. 运行 `terraform apply`

## 下一步

- 了解 [数据目录](./concepts/01_DATA_CATALOG.md)
- 查看 [操作指南](./operations/01_OPERATIONS_GUIDE.md)
- 遇到问题？查看 [问题修复总览](./issues/00_OVERVIEW.md)

---

**最后更新**: 2025-12-10
