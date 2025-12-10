# Windows Spark 数据写入问题 - 快速修复指南

## 问题
在 Windows 上运行 Spark Notebook 时，数据写入操作失败：
```
Hadoop home directory C:\hadoop does not exist
```

## 解决方案

我已经在你的 Jupyter Notebook 中修复了这个问题。关键改动包括：

### 1. 环境配置 (cell-2)

添加了 Hadoop 环境变量的设置：
```python
os.environ["HADOOP_HOME"] = spark_home
os.environ["HADOOP_COMMON_HOME"] = spark_home
os.environ["HADOOP_HDFS_HOME"] = spark_home
os.environ["HADOOP_MAPRED_HOME"] = spark_home
os.environ["HADOOP_YARN_HOME"] = spark_home
```

### 2. Spark Session 配置 (cell-4)

添加了本地文件系统支持的配置：
```python
.config("spark.hadoop.fs.file.impl", "org.apache.hadoop.fs.LocalFileSystem") \
.config("spark.hadoop.fs.file.impl.disable.cache", "true") \
```

### 3. 数据输出方法 (cell-26)

**改用 Pandas 方式替代 Spark 分布式写入**（推荐）：

```python
# 方法：使用 Pandas 进行本地输出
df_customer_base_cleaned.toPandas().to_csv(output_path_base, index=False, encoding='utf-8')
df_customer_behavior_cleaned.toPandas().to_csv(output_path_behavior, index=False, encoding='utf-8')
```

**优点**：
- 无需配置 Hadoop
- 代码简单易用
- 适合本地数据处理
- 支持 UTF-8 编码

**备选方案**：
如果 Pandas 方法失败，代码会自动尝试 Spark 分布式写入。

## 使用方法

1. **打开你的 Notebook**：`test/spark/test_spark_cleansing.ipynb`

2. **逐个运行单元格**，从上到下

3. **预期结果**：
   - 数据成功加载
   - 清洗操作完成
   - 清洗后的数据保存到 `output/` 目录下：
     - `output/cleaned_customer_base.csv`
     - `output/cleaned_customer_behavior.csv`

## 文件大小注意

Pandas 方法会将数据加载到内存，请检查数据大小：

```python
# 检查数据量
print(f"Customer base rows: {df_customer_base_cleaned.count()}")
print(f"Customer behavior rows: {df_customer_behavior_cleaned.count()}")
```

对于当前数据集（10,000 + 120,000 行），内存使用量应该在 100-200 MB 以内，不会有问题。

## 完整的数据输出单元格代码

```python
# 创建output目录
output_dir = project_root / "output"
output_dir.mkdir(exist_ok=True)

output_path_base = str(output_dir / "cleaned_customer_base.csv")
output_path_behavior = str(output_dir / "cleaned_customer_behavior.csv")

print("开始导出清洗后的数据...")

try:
    # 主要方案：Pandas 本地输出
    df_customer_base_cleaned.toPandas().to_csv(output_path_base, index=False, encoding='utf-8')
    print(f"✓ 客户基本信息已输出: {output_path_base}")

    df_customer_behavior_cleaned.toPandas().to_csv(output_path_behavior, index=False, encoding='utf-8')
    print(f"✓ 客户行为资产已输出: {output_path_behavior}")

except Exception as e:
    print(f"✗ Pandas 导出失败: {e}")
    print("尝试使用 Spark 分布式写入...")

    try:
        df_customer_base_cleaned.write.mode("overwrite").option("header", "true").csv(output_path_base)
        df_customer_behavior_cleaned.write.mode("overwrite").option("header", "true").csv(output_path_behavior)
        print("✓ 数据已使用分布式方式导出")
    except Exception as e2:
        print(f"✗ 两种方法都失败: {e2}")
```

## 其他可能的问题

### 如果仍然遇到问题：

1. **检查 Python 版本**（应该 >= 3.8）
   ```python
   import sys
   print(sys.version)
   ```

2. **确保 Pandas 已安装**
   ```python
   import pandas as pd
   print(pd.__version__)
   ```

3. **检查磁盘空间**
   - 确保有足够的空间存储输出文件

4. **清理旧的临时文件**
   - 删除 `.venv/spark-warehouse` 目录
   - 删除 `spark_test_output` 目录

## 完整的环境配置

如果想要深入配置 Hadoop，可以参考 `WINDOWS_SPARK_FIX.md` 文件了解更多详情。

## 总结

✓ **已为你做的修改**：
- 更新了 Spark Notebook 的环境配置
- 改用 Pandas 方式输出数据（主要）
- 添加了自动降级到 Spark 分布式写入的备选方案

✓ **你需要做的**：
- 在虚拟环境中打开 Notebook
- 按顺序运行所有单元格
- 清洗后的数据将自动保存到 `output/` 目录

有问题可以参考错误消息和 `WINDOWS_SPARK_FIX.md` 中的故障排除部分。
