# 快速修复清单

## 已修复的文件

### 1. `glue_scripts/config/glue_jobs_config.json`
- ✅ 升级 worker 配置：G.1X → G.2X
- ✅ 增加容量：2 → 4 capacity units
- ✅ 增加超时：30 → 60 分钟
- ✅ 添加 Spark 优化参数

### 2. `glue_scripts/1_data_cleansing.py`
- ✅ 添加 Spark 网络容错配置
- ✅ 缓存清洗结果 (`.persist()`)
- ✅ 消除重复的 `count()` 调用
- ✅ 缓存的计数值用于统计报告
- ✅ 添加异常处理防止统计失败

### 3. `glue_scripts/2_feature_engineering.py`
- ✅ 添加 Spark 网络容错配置
- ✅ 合并多个统计查询为单次扫描
- ✅ 使用聚合而不是多次过滤
- ✅ 添加异常处理防止统计失败

## 关键改进

| 改进 | 位置 | 效果 |
|------|------|------|
| 网络超时配置 | 两个脚本 | 减少连接超时错误 |
| RPC 重试 | 两个脚本 | 提高网络容错性 |
| 数据缓存 | 数据清洗脚本 | 避免重复计算 |
| 批量统计 | 特征工程脚本 | 减少 Spark 扫描次数 |
| Worker 升级 | 配置文件 | 更多内存和计算资源 |

## 部署步骤

### 第一步：上传脚本到 S3

```bash
# 假设 S3 bucket 为 your-customer-data-bucket
aws s3 cp glue_scripts/1_data_cleansing.py s3://your-customer-data-bucket/scripts/
aws s3 cp glue_scripts/2_feature_engineering.py s3://your-customer-data-bucket/scripts/
```

### 第二步：使用 Terraform 或 Glue CLI 更新 Jobs

**使用 AWS CLI 更新现有 Job:**

```bash
# 更新数据清洗 job
aws glue update-job \
  --name customer-data-cleansing \
  --role GlueCustomerDataRole \
  --command Name=glueetl,ScriptLocation=s3://your-customer-data-bucket/scripts/1_data_cleansing.py,PythonVersion=3 \
  --max-capacity 4 \
  --worker-type G.2X \
  --glue-version 4.0 \
  --timeout 60 \
  --default-arguments '{
    "--TempDir":"s3://your-customer-data-bucket/temp",
    "--enable-glue-datacatalog":"true",
    "--job-bookmark-option":"job-bookmark-enable",
    "--INPUT_DATABASE":"customer_raw_db",
    "--INPUT_TABLE_BASE":"raw_customer_base",
    "--INPUT_TABLE_BEHAVIOR":"raw_customer_behavior_assets",
    "--OUTPUT_BUCKET":"s3://your-customer-data-bucket/cleaned",
    "--OUTPUT_PATH_BASE":"customer_base",
    "--OUTPUT_PATH_BEHAVIOR":"customer_behavior"
  }'

# 更新特征工程 job
aws glue update-job \
  --name customer-feature-engineering \
  --role GlueCustomerDataRole \
  --command Name=glueetl,ScriptLocation=s3://your-customer-data-bucket/scripts/2_feature_engineering.py,PythonVersion=3 \
  --max-capacity 4 \
  --worker-type G.2X \
  --glue-version 4.0 \
  --timeout 60 \
  --default-arguments '{
    "--TempDir":"s3://your-customer-data-bucket/temp",
    "--enable-glue-datacatalog":"true",
    "--job-bookmark-option":"job-bookmark-enable",
    "--INPUT_DATABASE":"customer_cleaned_db",
    "--INPUT_TABLE_BASE":"cleaned_customer_base",
    "--INPUT_TABLE_BEHAVIOR":"cleaned_customer_behavior",
    "--OUTPUT_BUCKET":"s3://your-customer-data-bucket/features",
    "--OUTPUT_PATH":"customer_features"
  }'
```

### 第三步：测试修复

```bash
# 运行数据清洗 job
aws glue start-job-run --job-name customer-data-cleansing

# 等待完成（查询 job 状态）
aws glue get-job-run \
  --job-name customer-data-cleansing \
  --run-id <run-id-from-previous-command>
```

### 第四步：检查日志

```bash
# 查看 CloudWatch 日志
aws logs tail /aws-glue/jobs/customer-data-cleansing --follow

# 或在 AWS Console 中查看：
# Glue > Jobs > customer-data-cleansing > Run details > Logs
```

## 成功指标

✅ Job 不再报 `Connection refused` 或 `Failed to connect` 错误
✅ Job 完成时间减少 20-30%（减少重复扫描）
✅ CloudWatch 日志显示正常完成

## 故障排查

### 问题：仍然出现网络错误

1. **检查 VPC 配置**
   - Glue Job VPC 和子网是否配置正确
   - 检查安全组出站规则（应允许所有 TCP）

2. **增加更多资源**
   - 在 `glue_jobs_config.json` 中增加 `max_capacity` 到 6 或 8
   - 尝试 `G.4X` worker 类型

3. **启用调试日志**
   - 添加 `"--debug": "true"` 到 job 参数
   - 查看详细的网络和 Spark 日志

### 问题：Job 仍然超时

1. **增加超时时间**
   - 在配置中设置 `timeout: 120` 或更高

2. **优化查询**
   - 检查是否有其他 shuffle 操作
   - 考虑分区处理大数据集

3. **监控内存**
   - 在 CloudWatch 中检查 executor 内存使用
   - 如果内存不足，升级到更高容量

## 需要的 AWS 权限

确保 IAM 角色有以下权限：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "glue:UpdateJob",
        "glue:StartJobRun",
        "glue:GetJobRun",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

## 相关文档

- [GLUE_FIXES.md](GLUE_FIXES.md) - 详细的修复说明
- [AWS Glue 最佳实践](https://docs.aws.amazon.com/glue/latest/dg/best-practices.html)
- [Spark 配置优化](https://spark.apache.org/docs/latest/configuration.html)
