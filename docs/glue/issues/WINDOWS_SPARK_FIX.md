# Windows 上 Spark 数据写入问题修复指南

## 问题描述

在 Windows 系统上运行 Spark 时，执行数据写操作（如 `df.write.csv()`）会抛出错误：

```
Hadoop home directory C:\hadoop does not exist
java.io.FileNotFoundException: Hadoop home directory C:\hadoop does not exist
```

这是因为 Spark 在 Windows 上依赖 Hadoop 的本地库文件（winutils.exe 等），而默认查找位置 `C:\hadoop` 不存在。

## 解决方案对比

### 方案 A：配置 Hadoop 环境变量（推荐用于生产环境）

设置以下环境变量：

```bash
set HADOOP_HOME=C:\path\to\hadoop
set HADOOP_COMMON_HOME=%HADOOP_HOME%
set HADOOP_HDFS_HOME=%HADOOP_HOME%
set HADOOP_MAPRED_HOME=%HADOOP_HOME%
set HADOOP_YARN_HOME=%HADOOP_HOME%
set HADOOP_CONF_DIR=%HADOOP_HOME%\etc\hadoop
```

或在 Python 代码中：

```python
import os
spark_home = "C:\\Users\\hy120\\spark\\spark-3.5.7-bin-hadoop3"
os.environ["HADOOP_HOME"] = spark_home
os.environ["HADOOP_COMMON_HOME"] = spark_home
os.environ["HADOOP_HDFS_HOME"] = spark_home
os.environ["HADOOP_MAPRED_HOME"] = spark_home
os.environ["HADOOP_YARN_HOME"] = spark_home
os.environ["HADOOP_CONF_DIR"] = os.path.join(spark_home, "etc", "hadoop")
```

**优点**：支持 Spark 的所有功能，包括分布式写入
**缺点**：需要下载并配置 Hadoop 二进制文件

### 方案 B：使用 Pandas 进行本地输出（推荐用于本地开发）

这是我们在 Notebook 中实现的方案。优点：

- 无需下载 Hadoop
- 代码简单直观
- 适合本地数据处理

```python
# 将 Spark DataFrame 转为 Pandas 并保存
df_customer_base_cleaned.toPandas().to_csv(output_path_base, index=False, encoding='utf-8')
```

**优点**：简单易用，无额外依赖
**缺点**：数据需要先加载到内存，不适合超大数据集

## 我们的实现（混合方案）

在 `test_spark_cleansing.ipynb` 中，我们采用了**混合方案**：

1. **首选 Pandas**：使用 `toPandas().to_csv()` 进行本地输出
2. **备选分布式**：如果 Pandas 方法失败，尝试使用 Spark 的分布式写入

```python
try:
    # 主要方案：Pandas 本地输出
    df_customer_base_cleaned.toPandas().to_csv(output_path_base, index=False, encoding='utf-8')
except Exception as e:
    # 备选方案：Spark 分布式写入
    df_customer_base_cleaned.write.mode("overwrite").csv(output_path_base)
```

## 关键 Spark 配置

在 Spark Session 中添加了以下配置以支持本地文件系统：

```python
spark = SparkSession.builder \
    .appName("CustomerDataCleansing") \
    .master("local[2]") \
    .config("spark.hadoop.fs.file.impl", "org.apache.hadoop.fs.LocalFileSystem") \
    .config("spark.hadoop.fs.file.impl.disable.cache", "true") \
    .getOrCreate()
```

这两个配置确保 Spark 正确使用本地文件系统。

## 环境变量配置

在 Notebook 启动时，设置的环境变量：

```python
os.environ["JAVA_HOME"] = "C:\\Program Files\\Java\\jdk-11"
os.environ["SPARK_HOME"] = "C:\\Users\\hy120\\spark\\spark-3.5.7-bin-hadoop3"
os.environ["HADOOP_HOME"] = spark_home
os.environ["PYSPARK_PYTHON"] = sys.executable
os.environ["PYSPARK_DRIVER_PYTHON"] = sys.executable
```

## 故障排除

### 错误：`java.io.FileNotFoundException: Hadoop home directory does not exist`

**原因**：Spark 找不到 Hadoop 安装目录

**解决**：
1. 确保设置了 `HADOOP_HOME` 环境变量
2. 使用 Pandas 方法替代 Spark 分布式写入
3. 检查 Java 安装是否正确

### 错误：`org.apache.hadoop.util.Shell: java.io.IOException: Cannot run program "winutils.exe"`

**原因**：缺少 Hadoop 的 Windows 本地工具

**解决**：
1. 下载 Hadoop for Windows
2. 放在 `C:\hadoop` 或其他位置
3. 设置 `HADOOP_HOME` 环境变量指向该目录

### 错误：`Exception: ArrowException: Could not convert array of type...`

**原因**：Pandas 转换时数据类型不兼容

**解决**：
```python
# 使用 PyArrow 而不是默认的转换器
df.toPandas(types_converter={...})
```

## 最佳实践

1. **本地开发**：使用 Pandas 方法（方案 B）
2. **生产环境**：配置完整的 Hadoop 环境（方案 A）
3. **大数据处理**：使用 Spark 分布式文件系统（HDFS/S3）
4. **数据量检查**：在转为 Pandas 前检查数据大小，确保内存充足

```python
# 检查数据是否过大
print(f"Data size: {df.count()} rows")
print(f"Estimated memory: {df.count() * 100 / 1024 / 1024:.2f} MB")
```

## 参考资源

- [Spark on Windows Guide](https://spark.apache.org/docs/latest/index.html)
- [Hadoop Windows Setup](https://wiki.apache.org/hadoop/WindowsProblems)
- [PySpark Documentation](https://spark.apache.org/docs/latest/api/python/)
