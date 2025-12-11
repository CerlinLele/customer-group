# AWS Glue 数据库和表

## 数据库

### 什么是数据库？

数据库是表的逻辑容器，用于组织相关的表。

### 创建数据库

```bash
aws glue create-database \
  --database-input '{
    "Name": "customer_data",
    "Description": "Customer data warehouse"
  }'
```

### 查看数据库

```bash
# 列出所有数据库
aws glue get-databases

# 查看特定数据库
aws glue get-database --name customer_data
```

### 更新数据库

```bash
aws glue update-database \
  --name customer_data \
  --database-input '{
    "Name": "customer_data",
    "Description": "Updated description"
  }'
```

### 删除数据库

```bash
aws glue delete-database --name customer_data
```

## 表

### 什么是表？

表定义了数据的结构，包括列、数据类型、存储位置等。

### 表的结构

```
表 (Table)
├── 列 (Columns)
│   ├── 列名
│   ├── 数据类型
│   └── 描述
├── 存储描述符 (StorageDescriptor)
│   ├── 位置 (Location)
│   ├── 输入格式 (InputFormat)
│   ├── 输出格式 (OutputFormat)
│   └── 序列化信息 (SerdeInfo)
├── 分区键 (PartitionKeys)
└── 参数 (Parameters)
```

### 创建表

#### 使用 AWS CLI

```bash
aws glue create-table \
  --database-name customer_data \
  --table-input '{
    "Name": "customer_base",
    "StorageDescriptor": {
      "Columns": [
        {"Name": "customer_id", "Type": "string", "Comment": "Customer ID"},
        {"Name": "name", "Type": "string", "Comment": "Customer name"},
        {"Name": "email", "Type": "string", "Comment": "Email address"},
        {"Name": "created_at", "Type": "timestamp", "Comment": "Creation time"}
      ],
      "Location": "s3://bucket/data/customer_base/",
      "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
      "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
      "SerdeInfo": {
        "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      }
    },
    "PartitionKeys": [
      {"Name": "year", "Type": "string"},
      {"Name": "month", "Type": "string"},
      {"Name": "day", "Type": "string"}
    ]
  }'
```

#### 使用 Glue 爬虫（自动）

```bash
aws glue create-crawler \
  --name customer-crawler \
  --role arn:aws:iam::ACCOUNT_ID:role/glue-role \
  --database-name customer_data \
  --targets S3Targets='[{Path=s3://bucket/data/customer_base}]'

aws glue start-crawler --name customer-crawler
```

### 查看表

```bash
# 列出数据库中的所有表
aws glue get-tables --database-name customer_data

# 查看特定表
aws glue get-table --database-name customer_data --name customer_base
```

### 更新表

```bash
aws glue update-table \
  --database-name customer_data \
  --table-input '{
    "Name": "customer_base",
    "Description": "Updated description",
    "StorageDescriptor": {
      "Columns": [
        {"Name": "customer_id", "Type": "string"},
        {"Name": "name", "Type": "string"},
        {"Name": "email", "Type": "string"},
        {"Name": "phone", "Type": "string"},
        {"Name": "created_at", "Type": "timestamp"}
      ],
      "Location": "s3://bucket/data/customer_base/",
      "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
      "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
      "SerdeInfo": {
        "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      }
    }
  }'
```

### 删除表

```bash
aws glue delete-table --database-name customer_data --name customer_base
```

## 分区

### 什么是分区？

分区是表的子集，通常按时间或其他维度划分，用于提高查询性能。

### 添加分区

```bash
aws glue batch-create-partition \
  --database-name customer_data \
  --table-name customer_base \
  --partition-input-list '[
    {
      "Values": ["2025", "12", "10"],
      "StorageDescriptor": {
        "Columns": [
          {"Name": "customer_id", "Type": "string"},
          {"Name": "name", "Type": "string"}
        ],
        "Location": "s3://bucket/data/customer_base/year=2025/month=12/day=10/",
        "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
        "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
        "SerdeInfo": {
          "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
        }
      }
    }
  ]'
```

### 查看分区

```bash
# 列出所有分区
aws glue get-partitions --database-name customer_data --table-name customer_base

# 查看特定分区
aws glue get-partition \
  --database-name customer_data \
  --table-name customer_base \
  --partition-values 2025 12 10
```

### 删除分区

```bash
aws glue batch-delete-partition \
  --database-name customer_data \
  --table-name customer_base \
  --partitions-to-delete '[
    {"Values": ["2025", "12", "10"]}
  ]'
```

## 数据类型

### 基本类型

| 类型 | 说明 | 示例 |
|------|------|------|
| `string` | 字符串 | "hello" |
| `int` | 32 位整数 | 42 |
| `long` | 64 位整数 | 9223372036854775807 |
| `float` | 32 位浮点数 | 3.14 |
| `double` | 64 位浮点数 | 3.14159265359 |
| `boolean` | 布尔值 | true/false |
| `timestamp` | 时间戳 | 2025-12-10 10:30:00 |
| `date` | 日期 | 2025-12-10 |
| `binary` | 二进制数据 | 0x48656C6C6F |

### 复杂类型

| 类型 | 说明 | 示例 |
|------|------|------|
| `array<type>` | 数组 | ["a", "b", "c"] |
| `map<key,value>` | 映射 | {"key1": "value1"} |
| `struct<field:type>` | 结构体 | {"name": "John", "age": 30} |

## 最佳实践

### 1. 命名规范
- 使用小写字母和下划线
- 避免使用保留字
- 使用有意义的名称

### 2. 列设计
- 选择合适的数据类型
- 添加列描述
- 避免过多的列

### 3. 分区策略
- 按时间分区（年/月/日）
- 避免过多的分区级别
- 定期清理过期分区

### 4. 存储格式
- 使用 Parquet（推荐）
- 使用 ORC（大数据场景）
- 避免 CSV（低效）

### 5. 性能优化
- 使用分区减少扫描
- 使用列式格式
- 定期更新统计信息

## 相关文档

- [数据目录](./01_DATA_CATALOG.md)
- [爬虫和连接](./03_CRAWLERS_AND_CONNECTIONS.md)
- [Glue 操作指南](../operations/01_OPERATIONS_GUIDE.md)

---

**最后更新**: 2025-12-10
