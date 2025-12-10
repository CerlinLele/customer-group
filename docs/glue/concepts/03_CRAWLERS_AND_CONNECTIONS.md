# AWS Glue 爬虫和连接

## 爬虫 (Crawler)

### 什么是爬虫？

爬虫是一个自动化工具，用于：
- 扫描数据源
- 发现数据结构
- 创建或更新表定义
- 更新数据目录

### 爬虫工作流程

```
1. 连接到数据源
2. 扫描数据
3. 推断数据结构
4. 创建/更新表
5. 更新数据目录
```

### 创建爬虫

#### 使用 AWS CLI

```bash
aws glue create-crawler \
  --name customer-data-crawler \
  --role arn:aws:iam::ACCOUNT_ID:role/glue-role \
  --database-name customer_data \
  --targets S3Targets='[{Path=s3://bucket/data/customer_base}]' \
  --schedule-expression 'cron(0 2 * * ? *)' \
  --schema-change-policy UpdateBehavior=UPDATE_IN_DATABASE,DeleteBehavior=LOG
```

#### 使用 Terraform

```hcl
resource "aws_glue_crawler" "customer_data" {
  name          = "customer-data-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.customer_data.name

  s3_target {
    path = "s3://bucket/data/customer_base"
  }

  schedule = "cron(0 2 * * ? *)"

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }
}
```

### 运行爬虫

```bash
# 手动运行
aws glue start-crawler --name customer-data-crawler

# 查看运行状态
aws glue get-crawler --name customer-data-crawler

# 查看运行历史
aws glue get-crawler-metrics --crawler-name customer-data-crawler
```

### 爬虫配置

#### 数据源

**S3**:
```bash
--targets S3Targets='[{Path=s3://bucket/data}]'
```

**JDBC 数据库**:
```bash
--targets JdbcTargets='[{ConnectionName=my-connection,Path=public.%}]'
```

**DynamoDB**:
```bash
--targets DynamoDBTargets='[{Path=my-table}]'
```

#### 调度

```bash
# 每天凌晨 2 点运行
--schedule-expression 'cron(0 2 * * ? *)'

# 每小时运行
--schedule-expression 'cron(0 * * * ? *)'

# 每周一凌晨 2 点运行
--schedule-expression 'cron(0 2 ? * MON *)'
```

#### 模式变更策略

```bash
--schema-change-policy UpdateBehavior=UPDATE_IN_DATABASE,DeleteBehavior=LOG
```

- `UpdateBehavior`: `UPDATE_IN_DATABASE` 或 `LOG`
- `DeleteBehavior`: `DELETE_FROM_DATABASE` 或 `LOG`

### 查看爬虫

```bash
# 列出所有爬虫
aws glue list-crawlers

# 查看爬虫详情
aws glue get-crawler --name customer-data-crawler

# 查看爬虫指标
aws glue get-crawler-metrics --crawler-name customer-data-crawler
```

### 更新爬虫

```bash
aws glue update-crawler \
  --name customer-data-crawler \
  --role arn:aws:iam::ACCOUNT_ID:role/glue-role \
  --database-name customer_data \
  --targets S3Targets='[{Path=s3://bucket/data/customer_base}]'
```

### 删除爬虫

```bash
aws glue delete-crawler --name customer-data-crawler
```

## 连接 (Connection)

### 什么是连接？

连接定义了如何连接到外部数据源，如数据库、数据仓库等。

### 连接类型

| 类型 | 说明 | 用途 |
|------|------|------|
| JDBC | Java 数据库连接 | MySQL, PostgreSQL, Oracle 等 |
| MONGODB | MongoDB 连接 | MongoDB 数据库 |
| KAFKA | Kafka 连接 | Kafka 消息队列 |
| NETWORK | 网络连接 | VPC 内的资源 |
| SALESFORCE | Salesforce 连接 | Salesforce CRM |
| SNOWFLAKE | Snowflake 连接 | Snowflake 数据仓库 |

### 创建连接

#### JDBC 连接

```bash
aws glue create-connection \
  --catalog-id 123456789012 \
  --connection-input '{
    "Name": "mysql-connection",
    "ConnectionType": "JDBC",
    "ConnectionProperties": {
      "JDBC_DRIVER_JAR_URI": "s3://bucket/mysql-connector-java.jar",
      "JDBC_DRIVER_CLASS_NAME": "com.mysql.jdbc.Driver",
      "SECRET_ID": "mysql-credentials",
      "JDBC_ENFORCE_SSL": "false"
    },
    "PhysicalConnectionRequirements": {
      "SubnetId": "subnet-xxxxx",
      "SecurityGroupIdList": ["sg-xxxxx"],
      "AvailabilityZone": "us-east-1a"
    }
  }'
```

#### MongoDB 连接

```bash
aws glue create-connection \
  --catalog-id 123456789012 \
  --connection-input '{
    "Name": "mongodb-connection",
    "ConnectionType": "MONGODB",
    "ConnectionProperties": {
      "CONNECTION_URL": "mongodb://host:27017/database",
      "SECRET_ID": "mongodb-credentials"
    }
  }'
```

### 测试连接

```bash
aws glue test-connection --name mysql-connection
```

### 查看连接

```bash
# 列出所有连接
aws glue list-connections

# 查看连接详情
aws glue get-connection --name mysql-connection
```

### 更新连接

```bash
aws glue update-connection \
  --name mysql-connection \
  --connection-input '{...}'
```

### 删除连接

```bash
aws glue delete-connection --connection-name mysql-connection
```

## 爬虫和连接的配合使用

### 场景 1: 爬虫发现 S3 数据

```bash
# 1. 创建爬虫
aws glue create-crawler \
  --name s3-crawler \
  --role arn:aws:iam::ACCOUNT_ID:role/glue-role \
  --database-name my_database \
  --targets S3Targets='[{Path=s3://bucket/data}]'

# 2. 运行爬虫
aws glue start-crawler --name s3-crawler

# 3. 查看创建的表
aws glue get-tables --database-name my_database
```

### 场景 2: 爬虫发现数据库表

```bash
# 1. 创建连接
aws glue create-connection \
  --catalog-id 123456789012 \
  --connection-input '{
    "Name": "mysql-connection",
    "ConnectionType": "JDBC",
    "ConnectionProperties": {
      "JDBC_DRIVER_JAR_URI": "s3://bucket/mysql-connector-java.jar",
      "JDBC_DRIVER_CLASS_NAME": "com.mysql.jdbc.Driver",
      "SECRET_ID": "mysql-credentials"
    }
  }'

# 2. 创建爬虫
aws glue create-crawler \
  --name mysql-crawler \
  --role arn:aws:iam::ACCOUNT_ID:role/glue-role \
  --database-name my_database \
  --targets JdbcTargets='[{ConnectionName=mysql-connection,Path=public.%}]'

# 3. 运行爬虫
aws glue start-crawler --name mysql-crawler

# 4. 查看创建的表
aws glue get-tables --database-name my_database
```

## 最佳实践

### 1. 爬虫配置
- 定期运行爬虫更新元数据
- 使用合适的调度表达式
- 配置模式变更策略

### 2. 连接管理
- 使用 AWS Secrets Manager 存储凭证
- 定期测试连接
- 监控连接状态

### 3. 性能优化
- 限制爬虫扫描范围
- 使用分区提高效率
- 避免扫描大量小文件

### 4. 安全性
- 使用 IAM 角色限制权限
- 加密敏感数据
- 审计爬虫活动

## 相关文档

- [数据目录](./01_DATA_CATALOG.md)
- [数据库和表](./02_DATABASES_AND_TABLES.md)
- [Glue 操作指南](../operations/01_OPERATIONS_GUIDE.md)

---

**最后更新**: 2025-12-10
