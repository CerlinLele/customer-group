# AWS Glue 网络连接问题修复

## 问题描述
在运行 `1_data_cleansing.py` job 时出现错误：
```
java.io.IOException: Failed to connect to /172.39.119.103:42817
Connection refused
```

这是 Spark 执行器之间的 RPC 通信失败导致的。

## 根本原因分析

1. **Worker 配置不足**
   - 原始配置: `G.1X` 类型，仅 2 个 capacity
   - 问题: 资源不足导致网络不稳定

2. **重复的 count() 操作**
   - 原脚本多次调用 `count()` 导致重复的全表扫描
   - 触发大量的 shuffle 操作和网络通信

3. **Spark 网络配置**
   - 默认的网络超时和重试参数不适合 Glue 环境
   - 需要提高容错性

## 实施的修复

### 1. 升级 Job 配置 (`glue_jobs_config.json`)

| 参数 | 原始值 | 新值 | 原因 |
|------|--------|-------|------|
| `max_capacity` | 2 | 4 | 提供更多计算资源 |
| `worker_type` | G.1X | G.2X | 每个 worker 更多内存 (16GB vs 8GB) |
| `timeout` | 30 分钟 | 60 分钟 | 给予足够时间完成 |
| 参数 | 无 | `--TempDir` | 指定临时文件位置 |
| 参数 | 无 | `--enable-glue-datacatalog` | 优化 Catalog 访问 |
| 参数 | 无 | `--job-bookmark-option` | 启用增量处理 |

### 2. 优化 Spark 配置 (两个脚本都添加)

```python
# 增加网络通信的容错性
spark_conf.set("spark.network.timeout", "300s")        # 5分钟超时
spark_conf.set("spark.executor.heartbeatInterval", "60s") # 心跳间隔
spark_conf.set("spark.rpc.numRetries", "5")            # RPC 重试次数
spark_conf.set("spark.shuffle.io.retryWait", "5s")     # Shuffle 重试等待
spark_conf.set("spark.dynamicAllocation.enabled", "false") # 禁用动态分配
```

### 3. 减少不必要的 count() 调用 (`1_data_cleansing.py`)

**问题代码:**
```python
# 多次调用 count() - 每次都扫描全表
logger.info(f"清洗后行数: {df_customer_base_cleaned.count()}")
# 质量检查报告中又调用一次
"output_rows": df_customer_base_cleaned.count(),
# CloudWatch 指标中再调用一次
```

**修复方案:**
```python
# 缓存结果，只调用一次
cleaned_base_count = df_customer_base_cleaned.count()
logger.info(f"清洗后行数: {cleaned_base_count}")

# 复用缓存的值
"output_rows": cleaned_base_count,
```

### 4. 添加数据框缓存

```python
df_customer_base_cleaned = df_customer_base_cleaned \
    .dropDuplicates(["customer_id"]) \
    .persist()  # 缓存，避免重复计算
```

### 5. 使用聚合而不是多次过滤 (`2_feature_engineering.py`)

**问题代码:**
```python
# 三次完整扫描
vip_count = df_final_features.filter(col("customer_tier") == "VIP高价值").count()
at_risk_count = df_final_features.filter(col("is_at_risk") == 1).count()
total_count = df_final_features.count()
```

**修复方案:**
```python
# 一次扫描通过聚合获取所有统计
stats_df = df_final_features.select(
    (col("customer_tier") == "VIP高价值").cast("int").alias("is_vip"),
    col("is_at_risk")
).agg(
    sum(col("is_vip")).alias("vip_count"),
    sum(col("is_at_risk")).alias("at_risk_count")
).collect()[0]
```

## 预期结果

- ✅ 网络连接失败错误消失
- ✅ Job 执行时间减少（减少不必要的扫描）
- ✅ 内存使用更稳定（更多 worker 资源）
- ✅ 容错性提高（网络重试和超时配置）

## 测试步骤

1. 上传更新的脚本到 S3
2. 使用新的配置部署 Glue Jobs
3. 运行数据清洗 job：
   ```bash
   aws glue start-job-run --job-name customer-data-cleansing
   ```
4. 监控 CloudWatch 日志查看是否有网络错误
5. 如果成功，运行特征工程 job：
   ```bash
   aws glue start-job-run --job-name customer-feature-engineering
   ```

## 其他建议

如果问题仍然存在，可尝试：

1. **进一步增加资源**
   - 升级到 `G.2X` 且 `max_capacity=6`
   - 或使用 `G.4X` workers

2. **检查网络配置**
   - 确保 Glue Job VPC 配置正确
   - 检查安全组允许 Spark 通信（所有 TCP 端口）

3. **数据大小评估**
   - 如果数据集非常大，考虑分区处理
   - 使用 `--OUTPUT_PARTITION_KEYS` 参数

4. **启用详细日志**
   - 在 Glue Job 中设置 `--debug` 参数查看更详细的日志
   - 导出日志到 S3 便于分析
