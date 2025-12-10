# 数据清洗笔记本使用指南

根据 [glue_scripts/1_data_cleansing.py](../glue_scripts/1_data_cleansing.py) 创建的两个本地数据清洗笔记本。

## 📋 笔记本列表

### 1. Pandas 版本（推荐 ⭐⭐⭐）

**文件路径**: [test/pandas/test_pandas_cleansing.ipynb](test_pandas_cleansing.ipynb)

**特点**:
- ✓ 无需 Java 依赖
- ✓ 速度快
- ✓ 完全兼容 Windows
- ✓ 代码易读易维护

**适用场景**:
- 单机数据处理
- 开发和测试
- 数据分析和可视化

**数据大小**: < 100GB

---

### 2. Spark 版本

**文件路径**: [test/spark/test_spark_cleansing.ipynb](../spark/test_spark_cleansing.ipynb)

**特点**:
- ✓ 分布式处理
- ✓ 大数据支持
- ✓ 生产级性能

**适用场景**:
- 大数据处理 (> 100GB)
- 生产环境
- 分布式计算

**需求**: Java 11

---

## 🚀 快速开始

### Pandas 版本

```bash
# 1. 进入项目目录
cd c:\Users\hy120\Downloads\zhihullm\CASE-customer-group

# 2. 激活虚拟环境
.venv\Scripts\activate.bat

# 3. 安装 Pandas (如果还未安装)
pip install pandas

# 4. 启动 Jupyter
jupyter notebook test/pandas/test_pandas_cleansing.ipynb
```

### Spark 版本

```bash
# 1. 进入项目目录
cd c:\Users\hy120\Downloads\zhihullm\CASE-customer-group

# 2. 激活虚拟环境
.venv\Scripts\activate.bat

# 3. 安装 Java 11 (如果还未安装)
# https://www.oracle.com/java/technologies/downloads/#java11

# 4. 设置 JAVA_HOME
set JAVA_HOME=C:\Program Files\Java\jdk-11

# 5. 启动 Jupyter
jupyter notebook test/spark/test_spark_cleansing.ipynb
```

---

## 📝 笔记本内容对比

| 功能 | Pandas | Spark |
|------|--------|-------|
| 环境配置 | ✓ | ✓ (含Java配置) |
| 数据加载 | ✓ | ✓ |
| 客户基本信息清洗 | ✓ | ✓ |
| 客户行为资产清洗 | ✓ | ✓ |
| 数据质量报告 | ✓ | ✓ |
| 数据输出 | ✓ | ✓ |
| 统计分析 | ✓ | ✗ |
| 数据可视化 | ✓ | ✗ |

---

## 🔍 数据处理流程

### 第一部分：加载数据

```
输入:
  - customer_base.csv (客户基本信息)
  - customer_behavior_assets.csv (客户行为资产)

输出:
  - df_customer_base (Pandas) / df_customer_base (Spark)
  - df_customer_behavior (Pandas) / df_customer_behavior (Spark)
```

### 第二部分：清洗客户基本信息

**步骤**:

1. **数据类型转换**
   - 字符串去空格
   - 数值类型转换
   - 日期类型转换

2. **异常值处理**
   - 年龄: 18-100 岁
   - 月收入: 0-100万

3. **数据标准化**
   - 性别: [男, 女]
   - 日期提取: 年月信息

4. **缺失值统计**
   - 记录各字段缺失值

5. **去重**
   - 基于 customer_id
   - 保留第一条记录

### 第三部分：清洗客户行为资产

**步骤**:

1. **数据类型转换**
   - 资产类字段转换为 double
   - 标志字段转换为 int
   - 时间戳转换

2. **资产数据验证**
   - 总资产: 0-1亿
   - 资产结余检查

3. **行为数据验证**
   - 非负数检查
   - 对负数进行修正

4. **产品标志验证**
   - 检查取值必须为 0 或 1

5. **缺失值处理**
   - contact_result 缺失值标记

6. **去重**
   - 基于 (customer_id, stat_month)
   - 保留最新的记录 (按 last_app_login_time)

### 第四部分：输出数据

```
输出目录: output/
  - cleaned_customer_base.csv
  - cleaned_customer_behavior.csv
```

---

## 📊 数据质量报告

笔记本会生成详细的数据质量检查报告，包含：

**客户基本信息**:
- 输入/输出行数
- 移除重复行数
- 年龄异常值
- 收入异常值
- 性别异常值

**客户行为资产**:
- 输入/输出行数
- 移除重复行数
- contact_result 缺失值
- 资产异常值

**示例输出**:
```
========================================
数据质量检查报告
========================================

【客户基本信息】
  input_rows: 10000
  output_rows: 9985
  duplicate_removed: 15
  age_invalid_count: 5
  income_invalid_count: 3
  gender_invalid_count: 0

【客户行为资产】
  input_rows: 15000
  output_rows: 14950
  duplicate_removed: 50
  contact_result_missing: 120
  assets_invalid_count: 2
```

---

## 🛠 自定义和扩展

### 修改清洗规则

**Pandas 版本** - 修改异常值阈值:
```python
# 原来
df_customer_base_cleaned.loc[
    (df_customer_base_cleaned['age'] < 18) | (df_customer_base_cleaned['age'] > 100),
    'age'
] = np.nan

# 修改为
df_customer_base_cleaned.loc[
    (df_customer_base_cleaned['age'] < 16) | (df_customer_base_cleaned['age'] > 120),
    'age'
] = np.nan
```

**Spark 版本** - 修改异常值阈值:
```python
# 原来
when((col("age") < 18) | (col("age") > 100), None)

# 修改为
when((col("age") < 16) | (col("age") > 120), None)
```

### 添加新的清洗规则

可以在相应的步骤后添加新的数据处理逻辑。例如：

```python
# Pandas
df_customer_base_cleaned['age_group'] = pd.cut(
    df_customer_base_cleaned['age'],
    bins=[0, 30, 40, 50, 100],
    labels=['18-30', '31-40', '41-50', '50+']
)

# Spark
from pyspark.sql.functions import when
df_customer_base_cleaned = df_customer_base_cleaned.withColumn(
    "age_group",
    when(col("age") <= 30, "18-30")
    .when(col("age") <= 40, "31-40")
    .when(col("age") <= 50, "41-50")
    .otherwise("50+")
)
```

---

## ⚠️ 常见问题

### Q: 笔记本无法找到数据文件？

**原因**: 未在项目根目录或 Jupyter 工作目录不正确

**解决**:
```python
# 检查当前目录
from pathlib import Path
print(Path.cwd())

# 确保数据文件存在
import os
print(os.listdir('.'))
```

### Q: Spark 版本报 Java 错误？

**原因**: Java 未安装或版本不兼容

**解决**:
```bash
# 检查 Java
java -version

# 安装 Java 11
# https://www.oracle.com/java/technologies/downloads/#java11

# 设置环境变量
set JAVA_HOME=C:\Program Files\Java\jdk-11
```

### Q: Pandas 版本缺少依赖？

**原因**: NumPy 或 Pandas 未安装

**解决**:
```bash
pip install pandas numpy
```

### Q: 输出文件位置在哪里？

**位置**: `output/` 目录
```
output/
  ├── cleaned_customer_base.csv
  └── cleaned_customer_behavior.csv
```

---

## 🔗 相关资源

- [AWS Glue 清洗脚本](../glue_scripts/1_data_cleansing.py)
- [Pandas 文档](https://pandas.pydata.org/)
- [PySpark 文档](https://spark.apache.org/docs/latest/api/python/)
- [Jupyter 文档](https://jupyter.org/)

---

## 📈 性能对比

| 指标 | Pandas | Spark |
|------|--------|-------|
| 启动时间 | < 1秒 | 10-20秒 |
| 处理速度 (小数据) | 快 | 中等 |
| 处理速度 (大数据) | 慢/OOM | 快 |
| 内存使用 | 中等 | 高 |
| 分布式 | ✗ | ✓ |

**建议**:
- 数据 < 10GB: 使用 Pandas
- 数据 > 100GB: 使用 Spark
- 开发阶段: 使用 Pandas
- 生产环境: 使用 Spark 或 AWS Glue

---

## 📝 执行步骤汇总

### 使用 Pandas（推荐）

1. ✓ 打开 test/pandas/test_pandas_cleansing.ipynb
2. ✓ 依次执行所有单元格
3. ✓ 查看输出目录中的结果

### 使用 Spark

1. ✓ 安装 Java 11
2. ✓ 设置 JAVA_HOME
3. ✓ 打开 test/spark/test_spark_cleansing.ipynb
4. ✓ 依次执行所有单元格
5. ✓ 查看输出目录中的结果

---

**祝您使用愉快！** 🎉

有问题? 查看 [WINDOWS_SPARK_SETUP.md](../WINDOWS_SPARK_SETUP.md)
