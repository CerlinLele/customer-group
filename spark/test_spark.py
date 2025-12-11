import os
import sys

# Ensure environment variables are set
if 'JAVA_HOME' not in os.environ:
    java_home = "C:\\Program Files\\Java\\jdk-11"
    os.environ['JAVA_HOME'] = java_home

if 'SPARK_HOME' not in os.environ:
    spark_home = "C:\\Users\\hy120\\spark\\spark-3.5.7-bin-hadoop3"
    os.environ['SPARK_HOME'] = spark_home
# 让 Spark executor 和 driver 都用当前这个 Python（你的 .venv 里的 python）
os.environ["PYSPARK_PYTHON"] = sys.executable
os.environ["PYSPARK_DRIVER_PYTHON"] = sys.executable

print("Environment setup:")
print("  JAVA_HOME:", os.environ.get("JAVA_HOME"))
print("  SPARK_HOME:", os.environ.get("SPARK_HOME"))
print("  PYSPARK_PYTHON:", os.environ.get("PYSPARK_PYTHON"))

from pyspark.sql import SparkSession

print("Creating Spark Session...")
spark = SparkSession.builder \
    .appName("TestSpark") \
    .master("local[*]") \
    .config("spark.driver.memory", "2g") \
    .config("spark.executor.memory", "1g") \
    .getOrCreate()

print("Spark Session created successfully!")
print(f"Spark version: {spark.version}")
print()

df = spark.createDataFrame(
    [(1, "a"), (2, "b"), (3, "c")],
    ["id", "value"]
)

print("Data frame created, showing data:")
df.show()

spark.stop()
print("Test completed successfully!")
