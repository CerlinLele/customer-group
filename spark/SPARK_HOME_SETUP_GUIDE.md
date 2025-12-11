# SPARK_HOME 配置指南

## 概述
本文档介绍如何在Windows系统上配置SPARK_HOME环境变量，以及相关的依赖项配置。

## 前置要求
- Java JDK (版本11或以上)
- Apache Spark (版本3.5.7或以上)
- Python 3.7+ 与 PySpark

## 1. 环境变量配置

### 1.1 JAVA_HOME 配置

#### Windows系统配置方法

**方式一：使用PowerShell永久设置**
```powershell
# 打开 PowerShell (管理员权限)
$env:JAVA_HOME = "C:\Program Files\Java\jdk-11"
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk-11", "User")
```

**方式二：系统环境变量设置**
1. 右键点击"此电脑" → 属性
2. 点击"高级系统设置"
3. 点击"环境变量"按钮
4. 新建用户变量或系统变量：
   - 变量名：`JAVA_HOME`
   - 变量值：`C:\Program Files\Java\jdk-11`
5. 点击确定并重启系统

**验证JAVA_HOME**
```powershell
echo $env:JAVA_HOME
java -version
```

### 1.2 SPARK_HOME 配置

#### Windows系统配置方法

**方式一：使用PowerShell永久设置**
```powershell
# 打开 PowerShell (管理员权限)
$env:SPARK_HOME = "C:\Users\hy120\spark\spark-3.5.7-bin-hadoop3"
[Environment]::SetEnvironmentVariable("SPARK_HOME", "C:\Users\hy120\spark\spark-3.5.7-bin-hadoop3", "User")
```

**方式二：系统环境变量设置**
1. 右键点击"此电脑" → 属性
2. 点击"高级系统设置"
3. 点击"环境变量"按钮
4. 新建用户变量或系统变量：
   - 变量名：`SPARK_HOME`
   - 变量值：`C:\Users\hy120\spark\spark-3.5.7-bin-hadoop3`
5. 点击确定并重启系统

**验证SPARK_HOME**
```powershell
echo $env:SPARK_HOME
ls $env:SPARK_HOME  # 或 dir %SPARK_HOME% (cmd.exe)
```

### 1.3 PATH 环境变量更新

将Spark和Java的bin目录添加到PATH中：

```powershell
# PowerShell方式
$env:PATH = "C:\Program Files\Java\jdk-11\bin;$env:SPARK_HOME\bin;$env:PATH"
```

## 2. Python环境配置

### 2.1 PySpark环境变量

在Python脚本中设置以下环境变量（在导入PySpark之前）：

```python
import os
import sys

# 设置JAVA_HOME
os.environ['JAVA_HOME'] = 'C:\\Program Files\\Java\\jdk-11'

# 设置SPARK_HOME
os.environ['SPARK_HOME'] = 'C:\\Users\\hy120\\spark\\spark-3.5.7-bin-hadoop3'

# 设置Python解释器路径（使用虚拟环境中的Python）
os.environ['PYSPARK_PYTHON'] = sys.executable
os.environ['PYSPARK_DRIVER_PYTHON'] = sys.executable

# 可选：设置Spark日志级别
os.environ['SPARK_LOG_LEVEL'] = 'WARN'
```

### 2.2 安装PySpark

#### 方式一：通过pip安装（推荐）

```bash
pip install pyspark==3.5.7
```

#### 方式二：下载压缩包安装

**步骤1：下载Spark压缩包**

从官方网站下载对应版本的Spark：

- 官方网站：https://spark.apache.org/downloads.html
- 选择版本：3.5.7
- 选择包类型：`Pre-built for Hadoop 3`
- 下载链接示例：https://archive.apache.org/dist/spark/spark-3.5.7/spark-3.5.7-bin-hadoop3.tgz

**步骤2：解压压缩包**

Windows系统推荐使用以下工具：
- 7-Zip（免费，推荐）
- WinRAR
- Windows内置压缩工具

```powershell
# 使用PowerShell解压
# 首先安装解压工具，或使用第三方工具
# 解压到目标目录
C:\Users\hy120\spark\
```

**步骤3：设置Spark路径**

将解压后的文件夹路径设置为SPARK_HOME：

```powershell
$env:SPARK_HOME = "C:\Users\hy120\spark\spark-3.5.7-bin-hadoop3"
```

**步骤4：验证安装**

```powershell
# 检查Spark目录结构
ls $env:SPARK_HOME

# 查看bin目录
ls $env:SPARK_HOME\bin
```

#### 方式三：使用conda安装

如果你使用Anaconda环境：

```bash
conda install -c conda-forge pyspark=3.5.7
```

#### 安装验证

无论哪种方式安装，都可以通过以下命令验证：

```python
import pyspark
print(pyspark.__version__)

from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("test").master("local").getOrCreate()
print(f"Spark {spark.version} installed successfully!")
spark.stop()
```

## 3. 目录结构说明

Spark安装目录结构如下：

```
spark-3.5.7-bin-hadoop3/
├── bin/                 # 可执行文件（spark-submit, spark-shell等）
├── conf/                # 配置文件
├── data/                # 示例数据
├── jars/                # Java依赖包
├── python/              # Python API
├── R/                   # R API
├── examples/            # 示例代码
└── LICENSE              # 许可证
```

## 4. 验证配置

### 4.1 Python脚本验证

创建测试脚本 `test_spark.py`：

```python
import os
import sys

# 设置环境变量
os.environ['JAVA_HOME'] = 'C:\\Program Files\\Java\\jdk-11'
os.environ['SPARK_HOME'] = 'C:\\Users\\hy120\\spark\\spark-3.5.7-bin-hadoop3'
os.environ['PYSPARK_PYTHON'] = sys.executable
os.environ['PYSPARK_DRIVER_PYTHON'] = sys.executable

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

# 测试数据框操作
df = spark.createDataFrame(
    [(1, "a"), (2, "b"), (3, "c")],
    ["id", "value"]
)
print("\nTest DataFrame:")
df.show()

spark.stop()
print("Test completed successfully!")
```

运行测试：
```bash
python test_spark.py
```

### 4.2 Spark Shell验证

```bash
# 进入SPARK_HOME目录
cd %SPARK_HOME%\bin

# 运行Spark Shell
spark-shell
# 或 PySpark Shell
pyspark
```

## 5. 常见问题排查

### 问题1：找不到Java

**错误信息：** `Error: Could not find or load main class`

**解决方案：**
1. 验证JAVA_HOME是否正确设置
2. 检查Java是否已安装：`java -version`
3. 确保Java版本符合要求（11或更高）

### 问题2：找不到Spark

**错误信息：** `ModuleNotFoundError: No module named 'pyspark'`

**解决方案：**
1. 确保PySpark已安装：`pip install pyspark`
2. 检查SPARK_HOME是否正确设置
3. 在虚拟环境中重新安装PySpark

### 问题3：Winutils错误

**错误信息：** `java.io.IOException: Could not locate executable null\bin\winutils.exe`

**解决方案：**
1. 下载 `winutils.exe` 从 https://github.com/steveloughran/winutils
2. 放置在 `%SPARK_HOME%\bin\` 目录下
3. 或设置环境变量：`$env:HADOOP_HOME = $env:SPARK_HOME`

### 问题4：Python版本不匹配

**错误信息：** `ValueError: Python in worker has different version`

**解决方案：**
1. 确保PYSPARK_PYTHON和PYSPARK_DRIVER_PYTHON指向同一个Python解释器
2. 如果使用虚拟环境，确保在虚拟环境中设置这些变量

## 6. Spark配置参数

### 常用配置参数

```python
spark = SparkSession.builder \
    .appName("MyApp") \
    .master("local[*]")  # local[*] 使用所有CPU核心
    .config("spark.driver.memory", "2g")  # Driver内存
    .config("spark.executor.memory", "1g")  # Executor内存
    .config("spark.sql.shuffle.partitions", "200")  # Shuffle分区数
    .config("spark.default.parallelism", "200")  # 默认并行度
    .config("spark.sql.adaptive.enabled", "true")  # 自适应查询优化
    .getOrCreate()
```

### 日志级别设置

```python
spark.sparkContext.setLogLevel("WARN")
# FATAL, ERROR, WARN, INFO, DEBUG, TRACE
```

## 7. 性能优化建议

1. **内存配置**：根据系统可用内存调整driver和executor内存
2. **并行度**：根据CPU核心数设置合适的并行度
3. **分区数**：大数据处理时调整shuffle分区数
4. **缓存**：使用 `cache()` 或 `persist()` 缓存中间结果
5. **序列化**：使用Kryo序列化器提高性能

## 8. 参考资源

- [Apache Spark官方文档](https://spark.apache.org/docs/latest/)
- [PySpark API文档](https://spark.apache.org/docs/latest/api/python/)
- [Spark性能调优指南](https://spark.apache.org/docs/latest/tuning.html)
- [Windows Spark安装指南](https://spark.apache.org/docs/latest/)

## 版本信息

- Spark版本：3.5.7
- Hadoop版本：3
- Java版本：11+
- Python版本：3.7+

---

**最后更新：** 2025年12月4日
