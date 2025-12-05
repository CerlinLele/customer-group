#!/usr/bin/env python3
"""
AWS Glue - Data Cleansing Job
功能: 清洗客户基本信息和行为资产数据
输入: raw_customer_base, raw_customer_behavior_assets
输出: cleaned_customer_base, cleaned_customer_behavior
"""

import sys
import logging
from datetime import datetime
from pyspark.context import SparkContext
from pyspark.sql import SparkSession, Window
from pyspark.sql.functions import (
    col, when, to_date, to_timestamp,
    trim, upper, lower, length,
    isnan, isnull, coalesce, lit,
    row_number, md5, concat_ws, year, month, sum
)
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, IntegerType, DateType

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

# 获取Glue任务参数
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'INPUT_DATABASE',
    'INPUT_TABLE_BASE',
    'INPUT_TABLE_BEHAVIOR',
    'OUTPUT_BUCKET',
    'OUTPUT_PATH_BASE',
    'OUTPUT_PATH_BEHAVIOR'
])

# Spark和Glue会话
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

logger.info(f"开始执行 {args['JOB_NAME']} 任务")

# ============================================================================
# 1. 加载数据
# ============================================================================

logger.info("步骤1: 加载源数据...")

try:
    # 加载客户基本信息表
    df_customer_base = glueContext.create_dynamic_frame.from_catalog(
        database=args['INPUT_DATABASE'],
        table_name=args['INPUT_TABLE_BASE']
    ).toDF()

    # 加载客户行为资产表
    df_customer_behavior = glueContext.create_dynamic_frame.from_catalog(
        database=args['INPUT_DATABASE'],
        table_name=args['INPUT_TABLE_BEHAVIOR']
    ).toDF()

    logger.info(f"客户基本信息行数: {df_customer_base.count()}")
    logger.info(f"客户行为资产行数: {df_customer_behavior.count()}")

except Exception as e:
    logger.error(f"加载数据失败: {str(e)}")
    raise

# ============================================================================
# 2. 清洗 - 客户基本信息表
# ============================================================================

logger.info("步骤2: 清洗客户基本信息表...")

# 2.1 数据类型转换和标准化
df_customer_base_cleaned = df_customer_base \
    .withColumn("customer_id", trim(col("customer_id"))) \
    .withColumn("name", trim(col("name"))) \
    .withColumn("age", col("age").cast(IntegerType())) \
    .withColumn("gender", trim(col("gender"))) \
    .withColumn("occupation", trim(col("occupation"))) \
    .withColumn("occupation_type", trim(col("occupation_type"))) \
    .withColumn("monthly_income", col("monthly_income").cast(DoubleType())) \
    .withColumn("open_account_date", to_date(col("open_account_date"), "yyyy-MM-dd")) \
    .withColumn("lifecycle_stage", trim(col("lifecycle_stage"))) \
    .withColumn("marriage_status", trim(col("marriage_status"))) \
    .withColumn("city_level", trim(col("city_level"))) \
    .withColumn("branch_name", trim(col("branch_name")))

# 2.2 异常值处理
df_customer_base_cleaned = df_customer_base_cleaned \
    .withColumn("age",
                when((col("age") < 18) | (col("age") > 100), None)
                .otherwise(col("age"))) \
    .withColumn("monthly_income",
                when((col("monthly_income") < 0) | (col("monthly_income") > 1000000), None)
                .otherwise(col("monthly_income")))

# 2.3 性别标准化 (保留原始值，但标记异常)
df_customer_base_cleaned = df_customer_base_cleaned \
    .withColumn("gender_flag",
                when(col("gender").isin(["男", "女"]), "valid")
                .otherwise("invalid"))

# 2.4 日期验证
df_customer_base_cleaned = df_customer_base_cleaned \
    .withColumn("open_account_year",
                when(col("open_account_date").isNotNull(),
                     year(col("open_account_date")))
                .otherwise(None)) \
    .withColumn("open_account_month",
                when(col("open_account_date").isNotNull(),
                     month(col("open_account_date")))
                .otherwise(None))

# 2.5 空值处理统计
null_counts_base = df_customer_base_cleaned.select([
    sum(isnull(col(c)).cast("int")).alias(c) for c in df_customer_base_cleaned.columns
])
logger.info("客户基本信息缺失值统计:")
null_counts_base.show()

# 2.6 去重（基于customer_id）
df_customer_base_cleaned = df_customer_base_cleaned \
    .dropDuplicates(["customer_id"])

logger.info(f"清洗后客户基本信息行数: {df_customer_base_cleaned.count()}")

# ============================================================================
# 3. 清洗 - 客户行为资产表
# ============================================================================

logger.info("步骤3: 清洗客户行为资产表...")

# 3.1 数据类型转换
df_customer_behavior_cleaned = df_customer_behavior \
    .withColumn("id", trim(col("id"))) \
    .withColumn("customer_id", trim(col("customer_id"))) \
    .withColumn("total_assets", col("total_assets").cast(DoubleType())) \
    .withColumn("deposit_balance", col("deposit_balance").cast(DoubleType())) \
    .withColumn("financial_balance", col("financial_balance").cast(DoubleType())) \
    .withColumn("fund_balance", col("fund_balance").cast(DoubleType())) \
    .withColumn("insurance_balance", col("insurance_balance").cast(DoubleType())) \
    .withColumn("deposit_flag", col("deposit_flag").cast(IntegerType())) \
    .withColumn("financial_flag", col("financial_flag").cast(IntegerType())) \
    .withColumn("fund_flag", col("fund_flag").cast(IntegerType())) \
    .withColumn("insurance_flag", col("insurance_flag").cast(IntegerType())) \
    .withColumn("product_count", col("product_count").cast(IntegerType())) \
    .withColumn("financial_repurchase_count", col("financial_repurchase_count").cast(IntegerType())) \
    .withColumn("credit_card_monthly_expense", col("credit_card_monthly_expense").cast(DoubleType())) \
    .withColumn("investment_monthly_count", col("investment_monthly_count").cast(IntegerType())) \
    .withColumn("app_login_count", col("app_login_count").cast(IntegerType())) \
    .withColumn("app_financial_view_time", col("app_financial_view_time").cast(IntegerType())) \
    .withColumn("app_product_compare_count", col("app_product_compare_count").cast(IntegerType())) \
    .withColumn("last_app_login_time", to_timestamp(col("last_app_login_time"), "yyyy-MM-dd HH:mm:ss")) \
    .withColumn("last_contact_time", to_timestamp(col("last_contact_time"), "yyyy-MM-dd HH:mm:ss")) \
    .withColumn("contact_result", trim(col("contact_result"))) \
    .withColumn("marketing_cool_period", to_date(col("marketing_cool_period"), "yyyy-MM-dd")) \
    .withColumn("stat_month", col("stat_month").cast(StringType()))

# 3.2 资产数据验证
df_customer_behavior_cleaned = df_customer_behavior_cleaned \
    .withColumn("total_assets_valid",
                when((col("total_assets") >= 0) &
                     (col("total_assets") < 100000000), "valid")  # < 1亿
                .otherwise("invalid")) \
    .withColumn("assets_balance_check",
                when((col("deposit_balance") + col("financial_balance") +
                      col("fund_balance") + col("insurance_balance")) > 0, "valid")
                .otherwise("invalid"))

# 3.3 行为数据验证（非负数）
behavior_cols = [
    "credit_card_monthly_expense", "investment_monthly_count",
    "app_login_count", "app_financial_view_time", "app_product_compare_count"
]

for col_name in behavior_cols:
    df_customer_behavior_cleaned = df_customer_behavior_cleaned \
        .withColumn(col_name,
                    when(col(col_name) < 0, 0)
                    .otherwise(col(col_name)))

# 3.4 产品标志验证（必须为0或1）
flag_cols = ["deposit_flag", "financial_flag", "fund_flag", "insurance_flag"]
for col_name in flag_cols:
    df_customer_behavior_cleaned = df_customer_behavior_cleaned \
        .withColumn(col_name,
                    when(col(col_name).isin([0, 1]), col(col_name))
                    .otherwise(None))

# 3.5 缺失值处理 - contact_result
df_customer_behavior_cleaned = df_customer_behavior_cleaned \
    .withColumn("contact_result_flag",
                when(col("contact_result").isNull(), "missing")
                .otherwise("present"))

# 3.6 空值处理统计
null_counts_behavior = df_customer_behavior_cleaned.select([
    sum(isnull(col(c)).cast("int")).alias(c) for c in df_customer_behavior_cleaned.columns
])
logger.info("客户行为资产缺失值统计:")
null_counts_behavior.show()

# 3.7 去重（基于id，保留最新的记录）
window_spec = Window.partitionBy("customer_id", "stat_month").orderBy(col("last_app_login_time").desc())
df_customer_behavior_cleaned = df_customer_behavior_cleaned \
    .withColumn("row_num", row_number().over(window_spec)) \
    .filter(col("row_num") == 1) \
    .drop("row_num")

logger.info(f"清洗后客户行为资产行数: {df_customer_behavior_cleaned.count()}")

# ============================================================================
# 4. 数据质量检查报告
# ============================================================================

logger.info("步骤4: 数据质量检查...")

quality_report = {
    "timestamp": datetime.now().isoformat(),
    "job_name": args['JOB_NAME'],
    "customer_base": {
        "input_rows": df_customer_base.count(),
        "output_rows": df_customer_base_cleaned.count(),
        "duplicate_removed": df_customer_base.count() - df_customer_base_cleaned.count(),
        "age_invalid_count": df_customer_base_cleaned.filter(col("age").isNull()).count(),
        "income_invalid_count": df_customer_base_cleaned.filter(col("monthly_income").isNull()).count(),
        "gender_invalid_count": df_customer_base_cleaned.filter(col("gender_flag") == "invalid").count()
    },
    "customer_behavior": {
        "input_rows": df_customer_behavior.count(),
        "output_rows": df_customer_behavior_cleaned.count(),
        "duplicate_removed": df_customer_behavior.count() - df_customer_behavior_cleaned.count(),
        "contact_result_missing": df_customer_behavior_cleaned.filter(col("contact_result_flag") == "missing").count(),
        "assets_invalid_count": df_customer_behavior_cleaned.filter(col("total_assets_valid") == "invalid").count()
    }
}

logger.info("======== 数据质量检查报告 ========")
for key, value in quality_report.items():
    logger.info(f"{key}: {value}")
logger.info("================================")

# ============================================================================
# 5. 输出清洗后的数据
# ============================================================================

logger.info("步骤5: 输出清洗后的数据...")

output_path_base = f"{args['OUTPUT_BUCKET']}/{args['OUTPUT_PATH_BASE']}"
output_path_behavior = f"{args['OUTPUT_BUCKET']}/{args['OUTPUT_PATH_BEHAVIOR']}"

# 客户基本信息输出
df_customer_base_cleaned.coalesce(1) \
    .write.mode("overwrite") \
    .option("header", "true") \
    .parquet(output_path_base)

logger.info(f"客户基本信息已输出到: {output_path_base}")

# 客户行为资产输出
df_customer_behavior_cleaned.coalesce(1) \
    .write.mode("overwrite") \
    .option("header", "true") \
    .parquet(output_path_behavior)

logger.info(f"客户行为资产已输出到: {output_path_behavior}")

# ============================================================================
# 6. CloudWatch指标上报
# ============================================================================

logger.info("步骤6: 上报监控指标...")

import boto3
cloudwatch = boto3.client('cloudwatch')

try:
    cloudwatch.put_metric_data(
        Namespace='CustomerDataPipeline',
        MetricData=[
            {
                'MetricName': 'CustomerBaseRows',
                'Value': df_customer_base_cleaned.count(),
                'Unit': 'Count'
            },
            {
                'MetricName': 'CustomerBehaviorRows',
                'Value': df_customer_behavior_cleaned.count(),
                'Unit': 'Count'
            },
            {
                'MetricName': 'ContactResultMissingRate',
                'Value': (quality_report["customer_behavior"]["contact_result_missing"] /
                         quality_report["customer_behavior"]["output_rows"] * 100),
                'Unit': 'Percent'
            }
        ]
    )
    logger.info("CloudWatch指标上报成功")
except Exception as e:
    logger.warning(f"CloudWatch指标上报失败: {str(e)}")

# ============================================================================
# 7. 完成任务
# ============================================================================

logger.info(f"{args['JOB_NAME']} 任务完成！")
job.commit()
