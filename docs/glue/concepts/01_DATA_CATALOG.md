# AWS Glue 数据目录 (Data Catalog)

## 什么是数据目录？

AWS Glue 数据目录是一个中央元数据存储库，包含所有数据源的信息。它提供：

- **统一的元数据视图**: 所有数据源的结构和位置
- **数据发现**: 快速找到需要的数据
- **数据治理**: 管理数据的访问和使用
- **自动化**: 通过爬虫自动发现数据结构

## 核心概念

### 数据库 (Database)
逻辑容器，组织相关的表。

### 表 (Table)
数据的结构定义，包含列、数据类型、位置等信息。

### 分区 (Partition)
表的子集，通常按时间或其他维度划分。

### 爬虫 (Crawler)
自动扫描数据源，发现数据结构并创建表定义。

## 项目中的数据目录

### 数据库

#### customer_data
包含客户相关的所有表。

**表**:
- `customer_base_raw` - 原始客户基础数据
- `customer_base_cleaned` - 清洗后的客户基础数据
- `customer_features` - 客户特征数据

### 表详情

#### customer_base_raw
**位置**: `s3://bucket/data/customer_base/raw/`
**格式**: Parquet
**分区**: `year`, `month`, `day`
**列**:
- `customer_id` (string) - 客户 ID
- `name` (string) - 客户名称
- `email` (string) - 邮箱
- `phone` (string) - 电话
- `created_at` (timestamp) - 创建时间

#### customer_base_cleaned
**位置**: `s3://bucket/data/customer_base/cleaned/`
**格式**: Parquet
**分区**: `year`, `month`, `day`
**列**:
- `customer_id` (string) - 客户 ID
- `name` (string) - 客户名称
- `email` (string) - 邮箱（已验证）
- `phone` (string) - 电话（已验证）
- `created_at` (timestamp) - 创建时间
- `cleaned_at` (timestamp) - 清洗时间

#### customer_features
**位置**: `s3://bucket/data/customer_features/`
**格式**: Parquet
**分区**: `year`, `month`, `day`
**列**:
- `customer_id` (string) - 客户 ID
- `total_purchases` (int) - 总购买次数
- `total_amount` (double) - 总购买金额
- `avg_order_value` (double) - 平均订单金额
- `customer_tier` (string) - 客户等级
- `is_at_risk` (int) - 是否有流失风险

## 使用数据目录

### 查看数据库

```bash
aws glue get-databases
```

### 查看表

```bash
aws glue get-tables --database-name customer_data
```

### 查看表详情

```bash
aws glue get-table --database-name customer_data --name customer_base_cleaned
```

### 查看分区

```bash
aws glue get-partitions --database-name customer_data --table-name customer_base_cleaned
```

### 创建表

```bash
aws glue create-table \
  --database-name customer_data \
  --table-input '{
    "Name": "my_table",
    "StorageDescriptor": {
      "Columns": [
        {"Name": "id", "Type": "string"},
        {"Name": "name", "Type": "string"}
      ],
      "Location": "s3://bucket/data/my_table/",
      "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
      "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
      "SerdeInfo": {
        "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      }
    }
  }'
```

### 更新表

```bash
aws glue update-table \
  --database-name customer_data \
  --table-input '{...}'
```

### 删除表

```bash
aws glue delete-table --database-name customer_data --name my_table
```

## 爬虫

### 创建爬虫

```bash
aws glue create-crawler \
  --name customer-data-crawler \
  --role arn:aws:iam::ACCOUNT_ID:role/glue-role \
  --database-name customer_data \
  --targets S3Targets='[{Path=s3://bucket/data/customer_base/raw}]'
```

### 运行爬虫

```bash
aws glue start-crawler --name customer-data-crawler
```

### 查看爬虫状态

```bash
aws glue get-crawler --name customer-data-crawler
```

### 查看爬虫执行历史

```bash
aws glue get-crawler-metrics --crawler-name customer-data-crawler
```

## 最佳实践

### 1. 命名规范
- 数据库: `snake_case`，如 `customer_data`
- 表: `snake_case`，如 `customer_base_cleaned`
- 列: `snake_case`，如 `customer_id`

### 2. 分区策略
- 按时间分区（年/月/日）
- 按地域分区
- 按业务维度分区

### 3. 数据格式
- 使用 Parquet 格式（压缩、列式存储）
- 避免 CSV（低效、易出错）
- 考虑 ORC 格式（大数据场景）

### 4. 元数据管理
- 定期运行爬虫更新元数据
- 添加表和列的描述
- 标记敏感数据

### 5. 性能优化
- 使用分区减少扫描数据量
- 使用列式格式提高查询性能
- 定期清理过期数据

## 相关文档

- [Glue 快速开始](../00_QUICK_START.md)
- [数据库和表](./02_DATABASES_AND_TABLES.md)
- [爬虫和连接](./03_CRAWLERS_AND_CONNECTIONS.md)

---

**最后更新**: 2025-12-10
