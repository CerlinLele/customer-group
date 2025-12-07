# AWS Glue EntityNotFoundException 问题解决方案

## 问题描述

在运行 AWS Glue 作业时，遇到以下错误：

```
py4j.protocol.Py4JJavaError: An error occurred while calling o323.getCatalogSource.
: com.amazonaws.services.glue.model.EntityNotFoundException: Entity Not Found
```

**根本原因**: Glue 作业试图从 Glue Catalog 读取不存在的表。

---

## 问题根源分析

### 为什么会发生这个错误？

1. **数据管道结构**:
   - 原始数据（CSV）存储在 S3
   - 数据清洗作业处理原始数据并输出到 S3（Parquet 格式）
   - 特征工程作业读取清洗后的数据

2. **缺失的环节**:
   - ❌ 没有自动化的 Schema 发现机制
   - ❌ 表没有在 Glue Catalog 中注册
   - ❌ 作业找不到所需的表定义

### 原始架构的问题

```
Raw CSV Data (S3)
         ↓
❌ No Registration
         ↓
Data Cleansing Job (失败！)
        ❌ EntityNotFoundException
```

---

## 解决方案

### 方案概述

使用 **AWS Glue Crawlers** 自动发现 S3 中的数据并在 Glue Catalog 中创建表定义。

### 实现的架构

```
Raw CSV Data (S3)
         ↓
Raw Crawlers (自动扫描 CSV)
         ↓
Glue Catalog: raw_* 表
         ↓
Data Cleansing Job (✓ 成功读取)
         ↓
Cleaned Parquet (S3)
         ↓
Cleaned Crawlers (自动扫描 Parquet)
         ↓
Glue Catalog: cleaned_* 表
         ↓
Feature Engineering Job (✓ 成功读取)
         ↓
Features Parquet (S3)
```

---

## 部署的资源

### Terraform 创建的 4 个 Crawlers

#### 1. 原始数据爬虫

```hcl
# Raw Customer Base Crawler
resource "aws_glue_crawler" "raw_customer_base" {
  name          = "${var.project_name}-${var.environment}-raw-customer-base-crawler"
  database_name = "customer_raw_db"
  s3_target {
    path = "s3://${bucket_name}/raw/customer_base.csv"
  }
  table_prefix = "raw_"
}

# Raw Customer Behavior Crawler
resource "aws_glue_crawler" "raw_customer_behavior" {
  name          = "${var.project_name}-${var.environment}-raw-customer-behavior-crawler"
  database_name = "customer_raw_db"
  s3_target {
    path = "s3://${bucket_name}/raw/customer_behavior_assets.csv"
  }
  table_prefix = "raw_"
}
```

**功能**:
- 自动扫描 CSV 文件
- 推断数据类型和 schema
- 在 `customer_raw_db` 数据库中创建表

#### 2. 清洗后数据爬虫

```hcl
# Cleaned Customer Base Crawler
resource "aws_glue_crawler" "cleaned_customer_base" {
  name          = "${var.project_name}-${var.environment}-cleaned-customer-base-crawler"
  database_name = "customer_cleaned_db"
  s3_target {
    path = "s3://${bucket_name}/cleaned/customer_base/"
  }
  table_prefix = "cleaned_"
}

# Cleaned Customer Behavior Crawler
resource "aws_glue_crawler" "cleaned_customer_behavior" {
  name          = "${var.project_name}-${var.environment}-cleaned-customer-behavior-crawler"
  database_name = "customer_cleaned_db"
  s3_target {
    path = "s3://${bucket_name}/cleaned/customer_behavior/"
  }
  table_prefix = "cleaned_"
}
```

**功能**:
- 扫描清洗作业输出的 Parquet 文件
- 创建表定义
- 在 `customer_cleaned_db` 数据库中注册表

### IAM 权限增强

添加了爬虫执行权限：

```hcl
# Glue Crawler execution permissions
statement {
  sid    = "GlueCrawlerExecution"
  actions = [
    "glue:GetCrawler",
    "glue:GetCrawlers",
    "glue:StartCrawler",
    "glue:StopCrawler"
  ]
}

# Enhanced Glue Catalog access
statement {
  sid    = "GlueCatalogAccess"
  actions = [
    "glue:CreateTable",
    "glue:UpdateTable",
    "glue:DeleteTable",
    "glue:GetTableVersions",
    # ... 其他权限
  ]
}
```

---

## 执行步骤

### 步骤 1: 部署基础设施

```bash
cd infra
terraform apply
```

### 步骤 2: 运行原始数据爬虫

```bash
aws glue start-crawler --name "case-dev-raw-customer-base-crawler"
aws glue start-crawler --name "case-dev-raw-customer-behavior-crawler"
```

✅ **结果**:
- `raw_customer_base` 表创建
- `raw_customer_behavior_assets` 表创建

### 步骤 3: 运行数据清洗作业

```bash
aws glue start-job-run --job-name customer-data-cleansing
```

✅ **结果**:
- CSV 数据被清洗
- Parquet 文件写入 `s3://bucket/cleaned/`

### 步骤 4: 运行清洗后数据爬虫

```bash
aws glue start-crawler --name "case-dev-cleaned-customer-base-crawler"
aws glue start-crawler --name "case-dev-cleaned-customer-behavior-crawler"
```

✅ **结果**:
- `cleaned_customer_base` 表创建
- `cleaned_customer_behavior` 表创建

### 步骤 5: 运行特征工程作业

```bash
aws glue start-job-run --job-name customer-feature-engineering
```

✅ **结果**:
- 特征成功生成，无 EntityNotFoundException 错误

---

## 修改的文件

### 1. [infra/modules/glue/crawlers.tf](infra/modules/glue/crawlers.tf)
- 添加 4 个 Glue Crawler 资源定义
- 配置 S3 目标路径
- 设置表前缀和 schema 更新策略

### 2. [infra/modules/glue/iam.tf](infra/modules/glue/iam.tf)
- 新增 `GlueCatalogAccess` 权限：`CreateTable`, `UpdateTable`, `DeleteTable`
- 新增 `GlueCrawlerExecution` 权限：`StartCrawler`, `StopCrawler`

### 3. [infra/modules/glue/outputs.tf](infra/modules/glue/outputs.tf)
- 添加 `crawler_names` 输出
- 添加 `crawler_arns` 输出
- 更新 `glue_resources_summary` 包含爬虫计数

### 新增文档

- [GLUE_PIPELINE_EXECUTION_GUIDE.md](GLUE_PIPELINE_EXECUTION_GUIDE.md) - 详细的执行指南
- [GLUE_QUICK_START.md](GLUE_QUICK_START.md) - 快速参考和一键脚本

---

## 关键概念

### AWS Glue Crawler

**什么是 Crawler？**
- 自动扫描 S3 或数据库位置
- 推断数据的 schema（数据类型、列名等）
- 在 Glue Catalog 中创建或更新表定义

**工作流程**:
```
CSV/Parquet 文件 (S3)
         ↓
Crawler 运行
         ↓
Schema 推断
         ↓
在 Glue Catalog 创建表
         ↓
可被 Glue Jobs 访问
```

### Glue Catalog

**什么是 Glue Catalog？**
- AWS 的元数据存储库
- 存储数据库、表、分区等定义
- 类似于 Hive Metastore

**作用**:
- Glue Jobs 通过 Catalog 发现数据
- Athena、Redshift 等服务可以查询 Catalog 中的表
- 提供统一的数据治理视图

---

## 比较：Before vs After

### Before（有问题）

```python
# 1_data_cleansing.py 失败
df_customer_base = glueContext.create_dynamic_frame.from_catalog(
    database="customer_raw_db",
    table_name="raw_customer_base"  # ❌ 表不存在！
).toDF()
```

**错误**:
```
EntityNotFoundException: Entity Not Found
```

### After（解决）

```
1. 运行爬虫：raw_customer_base_crawler
   → 创建 raw_customer_base 表 ✓

2. 运行作业：customer-data-cleansing
   → 成功读取 raw_customer_base 表 ✓
   → 输出 cleaned_customer_base Parquet ✓

3. 运行爬虫：cleaned_customer_base_crawler
   → 创建 cleaned_customer_base 表 ✓

4. 运行作业：customer-feature-engineering
   → 成功读取 cleaned_customer_base 表 ✓
   → 生成特征 ✓
```

---

## 性能指标

### 爬虫执行时间

| 爬虫 | 输入 | 执行时间 |
|------|------|--------|
| raw_customer_base | 1 CSV 文件 | ~1-2 分钟 |
| raw_customer_behavior | 1 CSV 文件 | ~1-2 分钟 |
| cleaned_customer_base | Parquet 目录 | ~1-2 分钟 |
| cleaned_customer_behavior | Parquet 目录 | ~1-2 分钟 |

### 作业执行时间

| 作业 | 输入 | 执行时间 |
|------|------|--------|
| Data Cleansing | Raw CSV | 5-15 分钟 |
| Feature Engineering | Cleaned Parquet | 10-20 分钟 |

### 总执行时间

**完整流程**: ~30-50 分钟（包括等待爬虫和作业）

---

## 成本影响

### 新增成本

| 资源 | 费用 | 说明 |
|------|-----|------|
| 爬虫 4 个 | ~$0.44/小时/爬虫 | 每次运行 1-2 分钟，成本低 |
| 额外 IAM 权限 | 免费 | 无额外成本 |
| S3 存储 | ~$0.023/GB/月 | 仅 Parquet 文件，体积小 |

**月度成本估算**: 额外 $5-10（基于每天运行）

---

## 故障排查

### 常见问题和解决方案

#### Q1: 爬虫运行失败

**常见原因**:
1. S3 路径不正确
2. IAM 权限不足
3. 文件格式不匹配

**解决步骤**:
```bash
# 1. 验证文件存在
aws s3 ls s3://bucket/raw/customer_base.csv

# 2. 查看爬虫日志
aws logs tail /aws-glue/crawlers/crawler-name

# 3. 验证 IAM 权限
aws iam get-role-policy --role-name Glue-Role --policy-name GluePolicy
```

#### Q2: 作业仍显示 EntityNotFoundException

**常见原因**:
1. 爬虫还未完成
2. 表名拼写错误
3. 数据库名不匹配

**解决步骤**:
```bash
# 1. 验证表存在
aws glue get-table --database-name customer_raw_db --name raw_customer_base

# 2. 列出所有表
aws glue get-tables --database-name customer_raw_db

# 3. 检查爬虫状态
aws glue get-crawler --name raw-customer-base-crawler
```

#### Q3: 爬虫创建了错误的数据类型

**解决方案**:
- 在 AWS Glue 控制台手动编辑表 schema
- 或删除表让爬虫重新创建

```bash
# 删除表
aws glue delete-table --database-name customer_raw_db --name raw_customer_base

# 重新运行爬虫
aws glue start-crawler --name raw-customer-base-crawler
```

---

## 最佳实践

### ✅ Do's

1. ✅ 在 CSV 文件中包含列名（Header Row）
2. ✅ 使用一致的数据格式
3. ✅ 定期运行爬虫保持 Catalog 最新
4. ✅ 使用有意义的表名称和前缀
5. ✅ 监控爬虫和作业执行状态

### ❌ Don'ts

1. ❌ 不要手动编辑 Glue Catalog（应通过爬虫或代码）
2. ❌ 不要在作业中硬编码 S3 路径
3. ❌ 不要忽视 IAM 权限检查
4. ❌ 不要在生产环境跳过测试

---

## 相关资源

- 📖 [AWS Glue Crawlers 文档](https://docs.aws.amazon.com/glue/latest/dg/add-crawler.html)
- 📖 [AWS Glue Data Catalog 文档](https://docs.aws.amazon.com/glue/latest/dg/catalog-and-crawler.html)
- 🔗 [快速开始指南](GLUE_QUICK_START.md)
- 🔗 [完整执行指南](GLUE_PIPELINE_EXECUTION_GUIDE.md)

---

## 总结

通过添加 Glue Crawlers，我们解决了 `EntityNotFoundException` 问题：

| 方面 | 改进 |
|------|------|
| 自动化 | 🔴 手动表创建 → 🟢 自动 Schema 发现 |
| 可维护性 | 🔴 易出错 → 🟢 自助服务 |
| 灵活性 | 🔴 固定 Schema → 🟢 动态适应 |
| 成本 | 🔴 额外手工工作 → 🟢 最小化操作成本 |

现在你的 Glue Pipeline 已经完全就绪，可以可靠地处理客户数据！ 🎉

