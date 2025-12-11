# 特征工程计划

## 项目目标

通过特征工程为客户数据创建机器学习特征，支持客户分析和预测模型。

## 特征工程流程

```
原始数据 → 数据清洗 → 特征提取 → 特征工程 → 特征输出
```

## 阶段 1: 数据清洗

**目标**: 清洗和标准化原始客户数据

**输入**: 原始客户数据 (S3)
**输出**: 清洗后的客户数据 (S3)
**脚本**: `glue_scripts/1_data_cleansing.py`

### 清洗步骤

1. **去重**: 按 `customer_id` 去重
2. **验证**: 验证邮箱和电话格式
3. **填充**: 处理缺失值
4. **标准化**: 统一数据格式
5. **质量检查**: 生成质量报告

### 输出表

- `customer_base_cleaned` - 清洗后的客户基础数据

## 阶段 2: 特征工程

**目标**: 从清洗后的数据生成机器学习特征

**输入**: 清洗后的客户数据 (S3)
**输出**: 特征化的客户数据 (S3)
**脚本**: `glue_scripts/2_feature_engineering.py`

### 特征类别

#### 1. 基础特征
- `customer_id` - 客户 ID
- `name` - 客户名称
- `email` - 邮箱
- `phone` - 电话

#### 2. 行为特征
- `total_purchases` - 总购买次数
- `total_amount` - 总购买金额
- `avg_order_value` - 平均订单金额
- `last_purchase_date` - 最后购买日期
- `days_since_last_purchase` - 距离最后购买的天数

#### 3. 价值特征
- `customer_tier` - 客户等级（普通、高价值、VIP）
- `lifetime_value` - 客户生命周期价值
- `annual_value` - 年度价值

#### 4. 风险特征
- `is_at_risk` - 是否有流失风险（0/1）
- `churn_probability` - 流失概率（0-1）
- `engagement_score` - 参与度评分（0-100）

### 特征计算

#### 客户等级
```
普通: 总金额 < 1000
高价值: 1000 <= 总金额 < 5000
VIP: 总金额 >= 5000
```

#### 流失风险
```
is_at_risk = 1 if:
  - 距离最后购买 > 90 天
  - 最近 3 个月无购买
  - 参与度评分 < 30
```

### 输出表

- `customer_features` - 特征化的客户数据

## 阶段 3: 数据输出

**目标**: 将特征数据输出到目标系统

**输出格式**: Parquet
**输出位置**: S3
**分区**: 按日期分区 (year/month/day)

## 执行流程

### 手动执行

```bash
# 1. 运行数据清洗 job
aws glue start-job-run --job-name customer-data-cleansing

# 2. 等待完成
aws glue get-job-run --job-name customer-data-cleansing --run-id $JOB_RUN_ID

# 3. 运行特征工程 job
aws glue start-job-run --job-name customer-feature-engineering

# 4. 验证输出
aws s3 ls s3://bucket/data/customer_features/
```

### 自动执行（使用 Step Functions）

可以配置 AWS Step Functions 自动执行整个流程。

## 监控和告警

### 监控指标

- Job 执行时间
- 处理的行数
- 错误率
- 数据质量指标

### 告警规则

- Job 失败时告警
- 执行时间超过阈值时告警
- 数据质量问题时告警

## 性能优化

### 1. 数据分区
- 按日期分区减少扫描
- 使用分区修剪提高查询性能

### 2. 资源配置
- 调整 Glue worker 类型和数量
- 优化 Spark 配置

### 3. 代码优化
- 避免重复的 count() 操作
- 使用缓存减少重复计算
- 使用聚合而不是多次过滤

## 相关文档

- [AWS 云端处理方案](./02_AWS_SOLUTION.md)
- [增量数据处理指南](./03_INCREMENTAL_PROCESSING.md)
- [Glue 快速开始](../glue/00_QUICK_START.md)

---

**最后更新**: 2025-12-10
