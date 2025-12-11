# Feature Engineering - 特征工程详解

## 概述

`glue_scripts/2_feature_engineering.py` 是一个完整的特征工程 Job，基于清洗后的客户数据生成机器学习特征。

**输入**:
- `cleaned_customer_base` - 清洗后的客户基本信息
- `cleaned_customer_behavior` - 清洗后的客户行为资产

**输出**:
- `customer_features` - 包含 40+ 个计算特征的特征表

---

## 🎯 核心目标

1. **客户分层** - 将客户分为 VIP、核心、培育、低价值四个等级
2. **风险识别** - 识别有流失风险的客户
3. **交叉销售** - 发现产品升级和交叉销售机会
4. **行为分析** - 量化客户的活跃度和参与度
5. **价值评估** - 综合评估客户的商业价值

---

## 📊 特征工程流程

### 步骤 1: 加载数据

```python
df_customer_base = glueContext.create_dynamic_frame.from_catalog(
    database=args['INPUT_DATABASE'],
    table_name=args['INPUT_TABLE_BASE']
).toDF()

df_customer_behavior = glueContext.create_dynamic_frame.from_catalog(
    database=args['INPUT_DATABASE'],
    table_name=args['INPUT_TABLE_BEHAVIOR']
).toDF()
```

**输入数据**:
- 客户基本信息表：客户 ID、年龄、性别、收入、生命周期阶段等
- 客户行为资产表：资产余额、登录次数、投资次数、联系记录等

---

### 步骤 2: 基础特征构建

#### 2.1 人口统计特征

从客户基本信息表中提取：
- `customer_id` - 客户 ID
- `age` - 年龄
- `gender` - 性别
- `monthly_income` - 月收入
- `occupation_type` - 职业类型
- `marriage_status` - 婚姻状态
- `city_level` - 城市等级
- `lifecycle_stage` - 生命周期阶段

#### 2.2 客户周期特征

```python
# 计算开户周期（天数和月数）
days_as_customer = datediff(ref_date, open_account_date)
months_as_customer = months_between(ref_date, open_account_date)
```

**用途**: 衡量客户的忠诚度和历史长度

#### 2.3 基础评分特征

**收入评分** (`income_score`):
```
月收入 >= 50,000 → 100 分
月收入 >= 30,000 → 75 分
月收入 >= 15,000 → 50 分
其他 → 25 分
```

**年龄分组** (`age_group`):
```
18-30, 30-40, 40-50, 50-60, 60+
```

**生命周期评分** (`lifecycle_score`):
```
价值客户 → 100 分
忠诚客户 → 85 分
成熟客户 → 70 分
成长客户 → 55 分
新客户 → 30 分
```

---

### 步骤 3: RFM 分析特征

RFM 是客户价值分析的经典模型：
- **R (Recency)** - 最近性：最后一次联系距今多久
- **F (Frequency)** - 频率：联系频率
- **M (Monetary)** - 金额：客户资产规模

#### 3.1 Recency（最近性）

```python
recency_days = datediff(ref_date, last_contact_date)
```

**含义**:
- 值越小，客户越活跃
- 999 天表示从未联系

#### 3.2 Frequency（频率）

```python
frequency_score = case(
    app_login_count >= 10 → 100,
    app_login_count >= 5 → 75,
    app_login_count >= 2 → 50,
    else → 25
)
```

**含义**: 基于 App 登录次数评分

#### 3.3 Monetary（金额）

```python
# 计算资产分位数
p25, p50, p75 = percentile_approx(total_assets, [0.25, 0.50, 0.75])

monetary_score = case(
    total_assets >= p75 → 100,
    total_assets >= p50 → 75,
    total_assets >= p25 → 50,
    else → 25
)
```

**含义**: 基于客户总资产的分位数评分

#### 3.4 综合 RFM 评分

```python
rfm_score = frequency_score * 0.4 +
            monetary_score * 0.4 +
            (100 - recency_days/999*100) * 0.2
```

**权重分配**:
- 频率 40% - 最重要
- 金额 40% - 最重要
- 最近性 20% - 参考

---

### 步骤 4: 行为活跃度特征

#### 4.1 参与度评分

```python
engagement_score = (app_login_count * 10 +
                    investment_monthly_count * 20) / 30
```

**含义**: 综合 App 使用和投资活动的活跃度

#### 4.2 活跃类型标签

```python
activity_type = case(
    is_active_app AND is_active_investor → "多元活跃",
    is_active_investor → "投资活跃",
    is_active_app → "应用活跃",
    is_active_consumer → "消费活跃",
    else → "低活跃"
)
```

**活跃类型定义**:
- `is_active_app` - App 登录 >= 3 次
- `is_active_investor` - 投资次数 >= 1
- `is_active_consumer` - 信用卡消费 > 0

---

### 步骤 5: 资产特征

#### 5.1 资产集中度

```python
asset_concentration = (deposit_balance² +
                       financial_balance² +
                       fund_balance² +
                       insurance_balance²) / total_assets²
```

**含义**:
- 值越小，资产分散度越高
- 值越大，资产集中在某一类产品

#### 5.2 产品多样性

```python
investment_product_diversity = deposit_flag +
                               financial_flag +
                               fund_flag +
                               insurance_flag
```

**范围**: 0-4（持有的产品类型数）

#### 5.3 多样化评分

```python
diversification_score = case(
    diversity == 4 → 100,
    diversity == 3 → 75,
    diversity == 2 → 50,
    diversity == 1 → 25,
    else → 0
)
```

**含义**: 鼓励客户持有多种产品

---

### 步骤 6: 客户价值评分

综合多个维度的评分，计算客户的总体价值。

```python
customer_value_score = rfm_score * 0.4 +
                       engagement_score * 0.3 +
                       diversification_score * 0.3
```

**权重分配**:
- RFM 评分 40% - 最重要（历史价值）
- 参与度 30% - 中等（当前活跃度）
- 多样化 30% - 中等（产品持有）

#### 客户分层

```python
customer_tier = case(
    customer_value_score >= 80 → "VIP高价值",
    customer_value_score >= 60 → "核心客户",
    customer_value_score >= 40 → "重点培育",
    else → "低价值"
)
```

**分层标准**:
- **VIP 高价值** (80+) - 高价值客户，重点维护
- **核心客户** (60-80) - 稳定客户，持续服务
- **重点培育** (40-60) - 潜力客户，重点开发
- **低价值** (<40) - 低价值客户，基础服务

---

### 步骤 7: 产品交叉销售机会

识别客户可能感兴趣的产品升级机会。

#### 7.1 理财产品升级

```python
financial_upgrade_score = case(
    deposit_flag == 1 AND financial_flag == 0
        → engagement_score * 1.2,
    else → 0
)
```

**逻辑**: 已持有存款但未持有理财的客户

#### 7.2 基金产品升级

```python
fund_upgrade_score = case(
    financial_flag == 1 AND fund_flag == 0
        → engagement_score * 0.9,
    else → 0
)
```

**逻辑**: 已持有理财但未持有基金的客户

#### 7.3 保险产品升级

```python
insurance_upgrade_score = case(
    insurance_flag == 0
        → rfm_score * engagement_score / 100,
    else → 0
)
```

**逻辑**: 未持有保险的所有客户

#### 7.4 信用卡升级

```python
credit_card_upgrade_score = case(
    credit_card_monthly_expense > 0
        → 50 + engagement_score * 0.5,
    else → 30
)
```

**逻辑**: 已消费客户得分更高

---

### 步骤 8: 风险评分

识别有流失风险的客户。

#### 8.1 流失风险评分

```python
churn_risk_score = case(
    recency_days > 180 → 80,      # 6个月未联系
    recency_days > 90 → 60,       # 3个月未联系
    recency_days > 30 → 40,       # 1个月未联系
    contact_result == "拒绝" → 50,
    else → 20
)
```

**风险等级**:
- 80 - 极高风险（6个月未联系）
- 60 - 高风险（3个月未联系）
- 40 - 中风险（1个月未联系）
- 50 - 中风险（拒绝联系）
- 20 - 低风险

#### 8.2 风险标签

```python
is_at_risk = case(
    churn_risk_score >= 60 → 1,
    else → 0
)
```

**含义**: 标记高风险客户（评分 >= 60）

---

### 步骤 9-12: 合并、统计、输出

#### 9. 合并所有特征

```python
df_final_features = df_features.join(
    df_behavior_latest,
    on="customer_id",
    how="left"
)
```

**结果**: 包含 40+ 列的完整特征表

#### 10. 特征统计

```python
# 客户分层分布
tier_stats = df_final_features.groupBy("customer_tier").count()

# 活跃类型分布
activity_stats = df_final_features.groupBy("activity_type").count()
```

#### 11. 输出特征表

```python
df_final_features.coalesce(1) \
    .write.mode("overwrite") \
    .option("header", "true") \
    .parquet(output_path)
```

**输出格式**: Parquet（压缩、列式存储）

#### 12. 上报 CloudWatch 指标

```python
cloudwatch.put_metric_data(
    Namespace='CustomerDataPipeline',
    MetricData=[
        {'MetricName': 'TotalCustomersWithFeatures', 'Value': total_count},
        {'MetricName': 'VIPCustomersCount', 'Value': vip_count},
        {'MetricName': 'AtRiskCustomersCount', 'Value': at_risk_count}
    ]
)
```

---

## 📋 输出特征列表

### 基础信息（10 列）
- `customer_id` - 客户 ID
- `name` - 客户名称
- `age` - 年龄
- `age_group` - 年龄分组
- `gender` - 性别
- `occupation_type` - 职业类型
- `monthly_income` - 月收入
- `marriage_status` - 婚姻状态
- `city_level` - 城市等级
- `lifecycle_stage` - 生命周期阶段

### 客户周期特征（2 列）
- `days_as_customer` - 开户天数
- `months_as_customer` - 开户月数

### 资产特征（8 列）
- `total_assets` - 总资产
- `deposit_balance` - 存款余额
- `financial_balance` - 理财余额
- `fund_balance` - 基金余额
- `insurance_balance` - 保险余额
- `asset_concentration` - 资产集中度
- `investment_product_diversity` - 产品多样性

### 行为特征（7 列）
- `app_login_count` - App 登录次数
- `credit_card_monthly_expense` - 信用卡月消费
- `investment_monthly_count` - 投资月次数
- `activity_type` - 活跃类型
- `is_active_app` - 是否 App 活跃
- `is_active_investor` - 是否投资活跃
- `is_active_consumer` - 是否消费活跃

### RFM 评分（4 列）
- `recency_days` - 最近性（天数）
- `frequency_score` - 频率评分
- `monetary_score` - 金额评分
- `rfm_score` - 综合 RFM 评分

### 多维度评分（4 列）
- `income_score` - 收入评分
- `lifecycle_score` - 生命周期评分
- `engagement_score` - 参与度评分
- `diversification_score` - 多样化评分

### 客户价值评分（2 列）
- `customer_value_score` - 客户价值评分
- `customer_tier` - 客户分层

### 交叉销售机会（4 列）
- `financial_upgrade_score` - 理财升级评分
- `fund_upgrade_score` - 基金升级评分
- `insurance_upgrade_score` - 保险升级评分
- `credit_card_upgrade_score` - 信用卡升级评分

### 风险评分（2 列）
- `churn_risk_score` - 流失风险评分
- `is_at_risk` - 是否高风险

### 时间戳（2 列）
- `last_contact_date` - 最后联系日期
- `last_app_login_time` - 最后登录时间

**总计**: 46 列特征

---

## 🔧 性能优化

### 1. 网络连接优化

```python
spark_conf.set("spark.network.timeout", "600s")        # 10分钟超时
spark_conf.set("spark.executor.heartbeatInterval", "120s")  # 2分钟心跳
spark_conf.set("spark.rpc.numRetries", "10")           # 10次重试
```

### 2. 内存配置

```python
spark_conf.set("spark.driver.memory", "4g")
spark_conf.set("spark.executor.memory", "4g")
spark_conf.set("spark.executor.cores", "4")
```

### 3. 容错机制

```python
spark_conf.set("spark.speculation", "true")            # 推测执行
spark_conf.set("spark.executor.maxFailures", "5")      # 最大失败次数
```

### 4. 统计优化

```python
# 一次扫描计算多个统计
stats_df = df_final_features.select(
    (col("customer_tier") == "VIP高价值").cast("int").alias("is_vip"),
    col("is_at_risk")
).agg(
    sum(col("is_vip")).alias("vip_count"),
    sum(col("is_at_risk")).alias("at_risk_count")
).collect()[0]
```

---

## 📊 使用场景

### 1. 客户分层管理

```sql
-- 查询 VIP 客户
SELECT * FROM customer_features
WHERE customer_tier = "VIP高价值"
ORDER BY customer_value_score DESC;
```

### 2. 风险预警

```sql
-- 查询高风险客户
SELECT customer_id, name, churn_risk_score
FROM customer_features
WHERE is_at_risk = 1
ORDER BY churn_risk_score DESC;
```

### 3. 交叉销售

```sql
-- 查询理财升级机会
SELECT customer_id, name, financial_upgrade_score
FROM customer_features
WHERE financial_upgrade_score > 0
ORDER BY financial_upgrade_score DESC
LIMIT 100;
```

### 4. 活跃度分析

```sql
-- 按活跃类型统计
SELECT activity_type, COUNT(*) as count,
       AVG(customer_value_score) as avg_value
FROM customer_features
GROUP BY activity_type;
```

---

## 🚀 运行方式

### 使用 AWS CLI

```bash
aws glue start-job-run \
  --job-name customer-feature-engineering \
  --arguments '{
    "INPUT_DATABASE": "customer_data",
    "INPUT_TABLE_BASE": "customer_base_cleaned",
    "INPUT_TABLE_BEHAVIOR": "customer_behavior_cleaned",
    "OUTPUT_BUCKET": "s3://my-bucket",
    "OUTPUT_PATH": "data/customer_features/"
  }'
```

### 使用 Terraform

```hcl
resource "aws_glue_job" "feature_engineering" {
  name = "customer-feature-engineering"

  default_arguments = {
    "--INPUT_DATABASE" = "customer_data"
    "--INPUT_TABLE_BASE" = "customer_base_cleaned"
    "--INPUT_TABLE_BEHAVIOR" = "customer_behavior_cleaned"
    "--OUTPUT_BUCKET" = "s3://my-bucket"
    "--OUTPUT_PATH" = "data/customer_features/"
  }
}
```

---

## 📈 预期输出

### 客户分层分布

```
VIP高价值: 500 人 (5%)
核心客户: 2000 人 (20%)
重点培育: 3500 人 (35%)
低价值: 4000 人 (40%)
```

### 活跃类型分布

```
多元活跃: 1000 人 (10%)
投资活跃: 2000 人 (20%)
应用活跃: 3000 人 (30%)
消费活跃: 2000 人 (20%)
低活跃: 2000 人 (20%)
```

### 风险客户

```
高风险客户: 1500 人 (15%)
```

---

## 🔗 相关文档

- [特征工程计划](../../feature-engineering/01_PLAN.md)
- [Glue 操作指南](./01_OPERATIONS_GUIDE.md)
- [Job 执行指南](./02_JOB_EXECUTION.md)
- [Spark 连接失败问题](../issues/01_SPARK_CONNECTION_FAILURE.md)

---

**最后更新**: 2025-12-10
