# AWS Glue 操作指南

日常操作和管理 AWS Glue 的完整指南。

## Job 管理

### 创建 Job

#### 使用 Terraform（推荐）

编辑 `infra/modules/glue/jobs.tf`：

```hcl
resource "aws_glue_job" "my_job" {
  name              = "my-job"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.scripts.id}/my_job.py"
  }
  max_capacity      = 2
  timeout           = 60
}
```

然后运行：
```bash
cd infra
terraform apply
```

#### 使用 AWS CLI

```bash
aws glue create-job \
  --name my-job \
  --role arn:aws:iam::ACCOUNT_ID:role/glue-role \
  --command Name=glueetl,ScriptLocation=s3://bucket/my_job.py \
  --max-capacity 2 \
  --timeout 60
```

### 更新 Job

#### 使用 Terraform

编辑 `infra/modules/glue/jobs.tf`，修改相应配置，然后：

```bash
cd infra
terraform apply
```

#### 使用 AWS CLI

```bash
aws glue update-job \
  --name my-job \
  --role arn:aws:iam::ACCOUNT_ID:role/glue-role \
  --command Name=glueetl,ScriptLocation=s3://bucket/my_job.py \
  --max-capacity 4
```

### 删除 Job

#### 使用 Terraform

从 `infra/modules/glue/jobs.tf` 中删除相应资源，然后：

```bash
cd infra
terraform apply
```

#### 使用 AWS CLI

```bash
aws glue delete-job --name my-job
```

### 列出所有 Job

```bash
aws glue list-jobs
```

### 查看 Job 详情

```bash
aws glue get-job --name my-job
```

## Job 执行

### 运行 Job

```bash
aws glue start-job-run --job-name my-job
```

带参数运行：

```bash
aws glue start-job-run \
  --job-name my-job \
  --arguments '{"--input_path":"s3://bucket/input","--output_path":"s3://bucket/output"}'
```

### 查看 Job 执行状态

```bash
# 获取 job run ID
JOB_RUN_ID=$(aws glue start-job-run --job-name my-job --query 'JobRunId' --output text)

# 查看执行状态
aws glue get-job-run --job-name my-job --run-id $JOB_RUN_ID

# 查看所有执行记录
aws glue get-job-runs --job-name my-job
```

### 停止 Job 执行

```bash
aws glue batch-stop-job-run \
  --job-name my-job \
  --job-run-ids $JOB_RUN_ID
```

## 日志管理

### 查看 Job 日志

```bash
# 查看最近的日志
aws logs tail /aws-glue/jobs/my-job --follow

# 查看特定时间范围的日志
aws logs filter-log-events \
  --log-group-name /aws-glue/jobs/my-job \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --end-time $(date +%s)000
```

### 搜索错误

```bash
# 搜索所有错误
aws logs filter-log-events \
  --log-group-name /aws-glue/jobs/my-job \
  --filter-pattern "ERROR"

# 搜索特定错误
aws logs filter-log-events \
  --log-group-name /aws-glue/jobs/my-job \
  --filter-pattern "ConnectException"
```

### 导出日志

```bash
# 导出到文件
aws logs filter-log-events \
  --log-group-name /aws-glue/jobs/my-job \
  --query 'events[*].message' \
  --output text > job_logs.txt
```

## 数据目录管理

### 查看数据库

```bash
aws glue get-databases
```

### 查看表

```bash
aws glue get-tables --database-name my_database
```

### 查看表详情

```bash
aws glue get-table --database-name my_database --name my_table
```

## 爬虫管理

### 创建爬虫

```bash
aws glue create-crawler \
  --name my-crawler \
  --role arn:aws:iam::ACCOUNT_ID:role/glue-role \
  --database-name my_database \
  --targets S3Targets='[{Path=s3://bucket/data}]'
```

### 运行爬虫

```bash
aws glue start-crawler --name my-crawler
```

### 查看爬虫状态

```bash
aws glue get-crawler --name my-crawler
```

## 连接管理

### 创建连接

```bash
aws glue create-connection \
  --catalog-id 123456789012 \
  --connection-input Name=my-connection,ConnectionType=JDBC,ConnectionProperties='{"JDBC_DRIVER_JAR_URI":"s3://bucket/driver.jar","JDBC_DRIVER_CLASS_NAME":"com.mysql.jdbc.Driver","SECRET_ID":"my-secret"}'
```

### 测试连接

```bash
aws glue test-connection --name my-connection
```

### 查看连接

```bash
aws glue get-connection --name my-connection
```

## 监控和告警

### 查看 Job 指标

```bash
# 查看 Job 执行时间
aws cloudwatch get-metric-statistics \
  --namespace AWS/Glue \
  --metric-name glue.driver.aggregate.numFailedTasks \
  --dimensions Name=JobName,Value=my-job \
  --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

### 设置告警

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name glue-job-failure \
  --alarm-description "Alert when Glue job fails" \
  --metric-name glue.driver.aggregate.numFailedTasks \
  --namespace AWS/Glue \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1
```

## 故障排除

### Job 运行失败

**检查清单**:
1. 查看 CloudWatch 日志
2. 验证 IAM 权限
3. 检查 S3 路径和数据格式
4. 验证脚本语法
5. 检查网络配置（VPC、安全组）

**常见错误**:
- `AccessDenied`: 检查 IAM 权限
- `EntityNotFoundException`: 检查 S3 路径
- `ConnectException`: 检查网络配置，参考 [Spark 连接失败问题](../issues/01_SPARK_CONNECTION_FAILURE.md)

### Job 执行超时

**解决方案**:
1. 增加 `timeout` 参数
2. 优化脚本性能
3. 增加 `max_capacity`
4. 分区处理数据

### 内存不足

**解决方案**:
1. 增加 `max_capacity`
2. 使用更大的 `worker_type`（G.2X 或 G.4X）
3. 优化脚本内存使用
4. 分批处理数据

## 最佳实践

### 1. 使用 Terraform 管理基础设施
- 版本控制
- 可重复部署
- 易于审查和回滚

### 2. 编写清晰的脚本
- 添加日志
- 处理错误
- 使用参数化配置

### 3. 监控和告警
- 设置 CloudWatch 告警
- 定期检查日志
- 跟踪执行指标

### 4. 安全性
- 使用 IAM 角色
- 加密敏感数据
- 限制网络访问

### 5. 成本优化
- 使用合适的 worker 类型
- 设置合理的超时
- 定期清理过期数据

## 相关文档

- [Glue 快速开始](../00_QUICK_START.md)
- [Job 执行指南](./02_JOB_EXECUTION.md)
- [Feature Engineering](./03_FEATURE_ENGINEERING.md)
- [数据目录](../concepts/01_DATA_CATALOG.md)
- [Spark 连接失败问题](../issues/01_SPARK_CONNECTION_FAILURE.md)

---

**最后更新**: 2025-12-10
