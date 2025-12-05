#!/usr/bin/env python3
"""
AWS Glue - Feature Engineering Job
功能: 基于清洗数据生成机器学习特征
输入: cleaned_customer_base, cleaned_customer_behavior
输出: customer_features (包含所有计算特征)

特征包括:
- RFM分析 (Recency, Frequency, Monetary)
- 客户生命周期评分
- 行为活跃度评分
- 产品交叉销售指数
- 客户价值评分
"""

import sys
import logging
from datetime import datetime, timedelta
from pyspark.sql import SparkSession, Window
from pyspark.sql.functions import (
    col, when, sum as spark_sum, avg, max as spark_max, min as spark_min,
    row_number, rank, dense_rank, ntile,
    datediff, months_between, year, month,
    round, log, sqrt, abs as spark_abs,
    lit, coalesce, first, last
)

# AWS Glue imports
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ============================================================================
# 配置部分
# ============================================================================

args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'INPUT_DATABASE',
    'INPUT_TABLE_BASE',
    'INPUT_TABLE_BEHAVIOR',
    'OUTPUT_BUCKET',
    'OUTPUT_PATH'
])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

logger.info(f"开始执行 {args['JOB_NAME']} 任务")

# ============================================================================
# 1. 加载清洗后的数据
# ============================================================================

logger.info("步骤1: 加载清洗后的数据...")

try:
    df_customer_base = glueContext.create_dynamic_frame.from_catalog(
        database=args['INPUT_DATABASE'],
        table_name=args['INPUT_TABLE_BASE']
    ).toDF()

    df_customer_behavior = glueContext.create_dynamic_frame.from_catalog(
        database=args['INPUT_DATABASE'],
        table_name=args['INPUT_TABLE_BEHAVIOR']
    ).toDF()

    logger.info(f"加载客户基本信息: {df_customer_base.count()} 行")
    logger.info(f"加载客户行为资产: {df_customer_behavior.count()} 行")

except Exception as e:
    logger.error(f"加载数据失败: {str(e)}")
    raise

# ============================================================================
# 2. 基础特征构建
# ============================================================================

logger.info("步骤2: 构建基础特征...")

# 2.1 人口统计特征
df_features = df_customer_base.select(
    col("customer_id"),
    col("name"),
    col("age"),
    col("gender"),
    col("occupation"),
    col("occupation_type"),
    col("monthly_income"),
    col("marriage_status"),
    col("city_level"),
    col("lifecycle_stage"),
    col("open_account_date"),
    col("branch_name")
)

# 2.2 计算开户周期（天数）
# 假设当前日期为最新的stat_month对应的月底
reference_date = spark.createDataFrame(
    [{"ref_date": datetime(2025, 6, 30)}]
).select("ref_date")

df_features = df_features.crossJoin(reference_date).select(
    col("customer_id"),
    col("name"),
    col("age"),
    col("gender"),
    col("occupation_type"),
    col("monthly_income"),
    col("marriage_status"),
    col("city_level"),
    col("lifecycle_stage"),
    col("open_account_date"),
    datediff(col("ref_date"), col("open_account_date")).alias("days_as_customer"),
    months_between(col("ref_date"), col("open_account_date")).alias("months_as_customer")
)

# 2.3 添加基础评分特征（基于人口统计）
df_features = df_features \
    .withColumn("income_score",
                when(col("monthly_income") >= 50000, 100)
                .when(col("monthly_income") >= 30000, 75)
                .when(col("monthly_income") >= 15000, 50)
                .otherwise(25)) \
    .withColumn("age_group",
                when(col("age") < 30, "18-30")
                .when(col("age") < 40, "30-40")
                .when(col("age") < 50, "40-50")
                .when(col("age") < 60, "50-60")
                .otherwise("60+")) \
    .withColumn("lifecycle_score",
                when(col("lifecycle_stage") == "价值客户", 100)
                .when(col("lifecycle_stage") == "忠诚客户", 85)
                .when(col("lifecycle_stage") == "成熟客户", 70)
                .when(col("lifecycle_stage") == "成长客户", 55)
                .when(col("lifecycle_stage") == "新客户", 30)
                .otherwise(0))

# ============================================================================
# 3. RFM 分析特征
# ============================================================================

logger.info("步骤3: 生成RFM特征...")

# 准备行为数据，按客户汇总最新数据
df_behavior_latest = df_customer_behavior \
    .withColumn("rn", row_number().over(
        Window.partitionBy("customer_id").orderBy(col("stat_month").desc())
    )) \
    .filter(col("rn") == 1) \
    .select(
        col("customer_id"),
        col("stat_month").alias("last_contact_month"),
        col("last_app_login_time"),
        col("last_contact_time"),
        col("total_assets"),
        col("credit_card_monthly_expense"),
        col("investment_monthly_count"),
        col("app_login_count"),
        col("contact_result")
    )

# 转换last_contact_time为日期，计算Recency
df_behavior_latest = df_behavior_latest \
    .withColumn("last_contact_date",
                when(col("last_contact_time").isNotNull(),
                     col("last_contact_time").cast("date"))
                .otherwise(None)) \
    .withColumn("recency_days",
                when(col("last_contact_date").isNotNull(),
                     datediff(lit(datetime(2025, 6, 30)), col("last_contact_date")))
                .otherwise(999))  # 从未联系的设为999天

# 频率 (Frequency): 使用app_login_count作为代理
df_behavior_latest = df_behavior_latest \
    .withColumn("frequency_score",
                when(col("app_login_count") >= 10, 100)
                .when(col("app_login_count") >= 5, 75)
                .when(col("app_login_count") >= 2, 50)
                .otherwise(25))

# 金额 (Monetary): 基于total_assets
# 计算所有客户资产的分位数用于评分
asset_percentiles = df_behavior_latest.selectExpr(
    "percentile_approx(total_assets, 0.25) as p25",
    "percentile_approx(total_assets, 0.50) as p50",
    "percentile_approx(total_assets, 0.75) as p75"
).collect()[0]

df_behavior_latest = df_behavior_latest \
    .withColumn("monetary_score",
                when(col("total_assets") >= asset_percentiles['p75'], 100)
                .when(col("total_assets") >= asset_percentiles['p50'], 75)
                .when(col("total_assets") >= asset_percentiles['p25'], 50)
                .otherwise(25))

# 综合RFM评分
df_behavior_latest = df_behavior_latest \
    .withColumn("rfm_score",
                round((col("frequency_score") * 0.4 +
                       col("monetary_score") * 0.4 +
                       (100 - col("recency_days")/999*100) * 0.2), 2))

# ============================================================================
# 4. 行为活跃度特征
# ============================================================================

logger.info("步骤4: 生成行为活跃度特征...")

df_behavior_latest = df_behavior_latest \
    .withColumn("engagement_score",
                round((col("app_login_count") * 10 +
                       col("investment_monthly_count") * 20) / 30, 2)) \
    .withColumn("is_active_app",
                when(col("app_login_count") >= 3, 1).otherwise(0)) \
    .withColumn("is_active_investor",
                when(col("investment_monthly_count") >= 1, 1).otherwise(0)) \
    .withColumn("is_active_consumer",
                when(col("credit_card_monthly_expense") > 0, 1).otherwise(0)) \
    .withColumn("activity_type",
                when((col("is_active_app") == 1) & (col("is_active_investor") == 1), "多元活跃")
                .when(col("is_active_investor") == 1, "投资活跃")
                .when(col("is_active_app") == 1, "应用活跃")
                .when(col("is_active_consumer") == 1, "消费活跃")
                .otherwise("低活跃"))

# ============================================================================
# 5. 资产特征
# ============================================================================

logger.info("步骤5: 生成资产特征...")

df_behavior_latest = df_behavior_latest \
    .withColumn("asset_concentration",
                round(((col("deposit_balance") ** 2 +
                        col("financial_balance") ** 2 +
                        col("fund_balance") ** 2 +
                        col("insurance_balance") ** 2) /
                       (col("total_assets") ** 2)), 4)) \
    .withColumn("investment_product_diversity",
                col("deposit_flag") + col("financial_flag") +
                col("fund_flag") + col("insurance_flag")) \
    .withColumn("diversification_score",
                when(col("investment_product_diversity") == 4, 100)
                .when(col("investment_product_diversity") == 3, 75)
                .when(col("investment_product_diversity") == 2, 50)
                .when(col("investment_product_diversity") == 1, 25)
                .otherwise(0))

# ============================================================================
# 6. 客户价值评分
# ============================================================================

logger.info("步骤6: 计算客户价值评分...")

df_behavior_latest = df_behavior_latest \
    .withColumn("customer_value_score",
                round((col("rfm_score") * 0.4 +
                       col("engagement_score") * 0.3 +
                       col("diversification_score") * 0.3), 2)) \
    .withColumn("customer_tier",
                when(col("customer_value_score") >= 80, "VIP高价值")
                .when(col("customer_value_score") >= 60, "核心客户")
                .when(col("customer_value_score") >= 40, "重点培育")
                .otherwise("低价值"))

# ============================================================================
# 7. 产品交叉销售机会评分
# ============================================================================

logger.info("步骤7: 生成交叉销售指数...")

df_behavior_latest = df_behavior_latest \
    .withColumn("financial_upgrade_score",
                when((col("deposit_flag") == 1) & (col("financial_flag") == 0),
                     round(col("engagement_score") * 1.2, 2))
                .otherwise(0)) \
    .withColumn("fund_upgrade_score",
                when((col("financial_flag") == 1) & (col("fund_flag") == 0),
                     round(col("engagement_score") * 0.9, 2))
                .otherwise(0)) \
    .withColumn("insurance_upgrade_score",
                when(col("insurance_flag") == 0,
                     round(col("rfm_score") * col("engagement_score") / 100, 2))
                .otherwise(0)) \
    .withColumn("credit_card_upgrade_score",
                when(col("credit_card_monthly_expense") > 0,
                     50 + round(col("engagement_score") * 0.5, 2))
                .otherwise(30))

# ============================================================================
# 8. 风险评分
# ============================================================================

logger.info("步骤8: 生成风险评分...")

df_behavior_latest = df_behavior_latest \
    .withColumn("churn_risk_score",
                when(col("recency_days") > 180, 80)  # 6个月未联系
                .when(col("recency_days") > 90, 60)   # 3个月未联系
                .when(col("recency_days") > 30, 40)   # 1个月未联系
                .when(col("contact_result") == "拒绝", 50)
                .otherwise(20)) \
    .withColumn("is_at_risk",
                when(col("churn_risk_score") >= 60, 1).otherwise(0))

# ============================================================================
# 9. 合并所有特征
# ============================================================================

logger.info("步骤9: 合并所有特征...")

df_final_features = df_features \
    .join(df_behavior_latest, on="customer_id", how="left") \
    .select(
        # 基础信息
        col("customer_id"),
        col("name"),
        col("age"),
        col("age_group"),
        col("gender"),
        col("occupation_type"),
        col("monthly_income"),
        col("marriage_status"),
        col("city_level"),
        col("lifecycle_stage"),

        # 客户周期特征
        col("days_as_customer"),
        col("months_as_customer"),

        # 资产特征
        col("total_assets"),
        col("deposit_balance"),
        col("financial_balance"),
        col("fund_balance"),
        col("insurance_balance"),
        col("asset_concentration"),
        col("investment_product_diversity"),

        # 行为特征
        col("app_login_count"),
        col("credit_card_monthly_expense"),
        col("investment_monthly_count"),
        col("activity_type"),
        col("is_active_app"),
        col("is_active_investor"),
        col("is_active_consumer"),

        # RFM评分
        col("recency_days"),
        col("frequency_score"),
        col("monetary_score"),
        col("rfm_score"),

        # 活跃度评分
        col("engagement_score"),

        # 多维度评分
        col("income_score"),
        col("lifecycle_score"),
        col("diversification_score"),

        # 客户价值评分
        col("customer_value_score"),
        col("customer_tier"),

        # 交叉销售机会
        col("financial_upgrade_score"),
        col("fund_upgrade_score"),
        col("insurance_upgrade_score"),
        col("credit_card_upgrade_score"),

        # 风险评分
        col("churn_risk_score"),
        col("is_at_risk"),

        # 最后更新时间
        col("last_contact_date"),
        col("last_app_login_time")
    )

# ============================================================================
# 10. 特征统计和验证
# ============================================================================

logger.info("步骤10: 特征统计...")

logger.info(f"最终特征表行数: {df_final_features.count()}")
logger.info(f"特征列数: {len(df_final_features.columns)}")

# 统计各客户分层
tier_stats = df_final_features.groupBy("customer_tier").count().collect()
logger.info("客户分层分布:")
for row in tier_stats:
    logger.info(f"  {row['customer_tier']}: {row['count']} 人")

# 统计活动类型分布
activity_stats = df_final_features.groupBy("activity_type").count().collect()
logger.info("活跃类型分布:")
for row in activity_stats:
    logger.info(f"  {row['activity_type']}: {row['count']} 人")

# ============================================================================
# 11. 输出特征表
# ============================================================================

logger.info("步骤11: 输出特征表...")

output_path = f"{args['OUTPUT_BUCKET']}/{args['OUTPUT_PATH']}"

df_final_features.coalesce(1) \
    .write.mode("overwrite") \
    .option("header", "true") \
    .parquet(output_path)

logger.info(f"特征表已输出到: {output_path}")

# ============================================================================
# 12. 上报CloudWatch指标
# ============================================================================

logger.info("步骤12: 上报监控指标...")

import boto3
cloudwatch = boto3.client('cloudwatch')

try:
    # 计算统计数据
    vip_count = df_final_features.filter(col("customer_tier") == "VIP高价值").count()
    at_risk_count = df_final_features.filter(col("is_at_risk") == 1).count()

    cloudwatch.put_metric_data(
        Namespace='CustomerDataPipeline',
        MetricData=[
            {
                'MetricName': 'TotalCustomersWithFeatures',
                'Value': df_final_features.count(),
                'Unit': 'Count'
            },
            {
                'MetricName': 'VIPCustomersCount',
                'Value': vip_count,
                'Unit': 'Count'
            },
            {
                'MetricName': 'AtRiskCustomersCount',
                'Value': at_risk_count,
                'Unit': 'Count'
            }
        ]
    )
    logger.info("CloudWatch指标上报成功")
except Exception as e:
    logger.warning(f"CloudWatch指标上报失败: {str(e)}")

# ============================================================================
# 完成任务
# ============================================================================

logger.info(f"{args['JOB_NAME']} 任务完成！")
job.commit()
