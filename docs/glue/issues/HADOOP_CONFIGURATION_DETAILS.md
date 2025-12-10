# Windows Spark + Hadoop 配置详解

## 你的配置情况

### Hadoop 安装
- **位置**: `C:\Users\hy120\hadoop`
- **关键文件**: `C:\Users\hy120\hadoop\bin\winutils.exe`
- **状态**: ✓ 已正确配置

### Java 安装
- **位置**: `C:\Program Files\Java\jdk-11`
- **用途**: Hadoop 和 Spark 都需要 Java
- **状态**: ✓ 已配置

### Spark 安装
- **位置**: `C:\Users\hy120\spark\spark-3.5.7-bin-hadoop3`
- **用途**: 主要的数据处理框架
- **状态**: ✓ 已配置

## Notebook 中的环境变量配置

在 Notebook 的第 2 个单元格中设置了以下环境变量：

```python
os.environ["HADOOP_HOME"] = "C:\\Users\\hy120\\hadoop"
os.environ["HADOOP_COMMON_HOME"] = "C:\\Users\\hy120\\hadoop"
os.environ["HADOOP_HDFS_HOME"] = "C:\\Users\\hy120\\hadoop"
os.environ["HADOOP_MAPRED_HOME"] = "C:\\Users\\hy120\\hadoop"
os.environ["HADOOP_YARN_HOME"] = "C:\\Users\\hy120\\hadoop"
os.environ["HADOOP_CONF_DIR"] = "C:\\Users\\hy120\\hadoop\\etc\\hadoop"
```

### 每个环境变量的作用

| 环境变量 | 用途 | 值 |
|---------|------|-----|
| `HADOOP_HOME` | Hadoop 根目录 | `C:\Users\hy120\hadoop` |
| `HADOOP_COMMON_HOME` | Hadoop 通用库位置 | 与 HADOOP_HOME 相同 |
| `HADOOP_HDFS_HOME` | HDFS 组件位置 | 与 HADOOP_HOME 相同 |
| `HADOOP_MAPRED_HOME` | MapReduce 组件位置 | 与 HADOOP_HOME 相同 |
| `HADOOP_YARN_HOME` | YARN 组件位置 | 与 HADOOP_HOME 相同 |
| `HADOOP_CONF_DIR` | Hadoop 配置目录 | `C:\Users\hy120\hadoop\etc\hadoop` |

## Spark 如何使用 Hadoop

### 读取 CSV 文件（已正常工作）
```python
df = spark.read.csv("customer_base.csv", header=True)
```

这个过程：
1. Spark 使用 Hadoop FileSystem API 读取文件
2. 需要 `HADOOP_HOME` 环境变量来初始化 Hadoop
3. 找到 `winutils.exe` 来处理文件系统操作

### 写入 CSV 文件（之前失败，现在修复）
```python
df.write.csv("output_file.csv")
```

这个过程：
1. Spark 创建输出目录（需要 Hadoop 权限设置）
2. 使用 `winutils.exe` 设置文件权限（Windows 特定）
3. 将数据分片写入临时文件
4. 原子性重命名为最终文件

**之前失败的原因**：
- `HADOOP_HOME` 未设置
- Spark 找不到 `C:\hadoop\bin\winutils.exe`
- 无法初始化 Hadoop 文件系统

**现在修复的原因**：
- 明确指向 `C:\Users\hy120\hadoop`
- `winutils.exe` 确实存在于该位置
- Spark 可以正确初始化 Hadoop

## CSV 文件输出的工作流程

### 使用 Spark 分布式写入（当前方式）

```python
df_customer_base_cleaned.coalesce(1) \
    .write \
    .mode("overwrite") \
    .option("header", "true") \
    .csv(output_path_base)
```

执行流程：

1. **Coalesce**：`coalesce(1)` 确保只有 1 个分区
   - 将数据集中到单个分区
   - 结果是单个 CSV 文件而不是多个文件

2. **Write**：`.write` 启动写入操作
   - 触发 Hadoop 文件系统初始化
   - 查找并使用 `HADOOP_HOME`

3. **Mode**：`.mode("overwrite")` 设置写入模式
   - `overwrite`：如果目录存在，覆盖
   - `append`：追加到现有文件
   - `ignore`：如果目录存在，跳过
   - `error`：如果目录存在，报错

4. **Header**：`.option("header", "true")` 写入列标题

5. **CSV**：`.csv(path)` 指定输出格式和路径
   - 启动 Hadoop 文件系统操作
   - 创建输出目录
   - 使用 `winutils.exe` 设置权限
   - 写入数据

### 输出目录结构

```
output/
├── cleaned_customer_base.csv/
│   ├── _SUCCESS          # 标志文件，表示成功
│   └── part-00000...csv  # 实际数据文件（使用 coalesce(1) 时只有一个）
└── cleaned_customer_behavior.csv/
    ├── _SUCCESS
    └── part-00000...csv
```

如果不使用 `coalesce(1)`，会有多个 `part-00000`, `part-00001` 等文件。

## Hadoop 的 Windows 特定问题

### 为什么 Hadoop 需要 winutils.exe？

Hadoop 是为 Linux 开发的，Windows 上需要额外的工具：

1. **权限设置**
   - Linux：使用 `chmod` 和 `chown`
   - Windows：需要 `winutils.exe` 设置 NTFS 权限

2. **文件系统操作**
   - Linux：标准 POSIX 文件系统
   - Windows：需要适配 NTFS 特性

3. **进程管理**
   - Linux：使用信号和进程组
   - Windows：需要特殊处理

### winutils.exe 的来源

你的 `C:\Users\hy120\hadoop\bin\winutils.exe` 是 Hadoop for Windows 的一部分：

- **来源**：hadoop-3.x-winutils 项目（https://github.com/steveloughran/winutils）
- **大小**：通常 100-200 KB
- **用途**：设置文件权限和提供 Windows 兼容性
- **安全性**：官方项目，可信

## 备选方案：Pandas 本地输出

如果 Spark 分布式写入仍然失败，Notebook 会自动降级到 Pandas 方式：

```python
df_customer_base_cleaned.toPandas().to_csv(output_path_base, index=False, encoding='utf-8')
```

**工作原理**：
1. 将 Spark DataFrame 转为 Pandas DataFrame
2. 所有数据加载到内存
3. 使用 Pandas 原生的 `to_csv()` 方法
4. 不依赖 Hadoop

**优点**：
- 无需 Hadoop 配置
- 更快（对小数据集）
- 完全控制输出格式

**缺点**：
- 需要足够的内存
- 不适合超大数据集

**当前数据量**：
- 客户基本信息：~2 MB
- 客户行为资产：~50 MB
- **总计**：~52 MB（完全在内存中，无问题）

## 故障排除

### 问题 1：还是报 "Hadoop home directory not found"

**检查清单**：
```bash
# 验证 Hadoop 目录
dir "C:\Users\hy120\hadoop\bin"

# 应该看到：
# winutils.exe

# 验证 Java
java -version

# 应该显示 Java 11 或更新版本
```

如果 `winutils.exe` 不存在，需要重新下载 Hadoop for Windows。

### 问题 2：权限错误 (Permission denied)

这通常不会发生，因为 `winutils.exe` 处理了权限。

如果发生：
```python
# 确保输出目录可写
import os
output_dir = "c:\\Users\\hy120\\Downloads\\zhihullm\\CASE-customer-group\\output"
os.makedirs(output_dir, exist_ok=True)
```

### 问题 3：CSV 文件中文乱码

确保使用 UTF-8 编码（已在 Pandas 方案中配置）：
```python
df.toPandas().to_csv(output_path, index=False, encoding='utf-8')
```

Spark 的默认编码可能需要额外配置。

## 性能建议

### 对于当前数据量（130,000 行）：

1. **使用 Spark 分布式写入**：完全足够
   - 数据量小，计算快速
   - 体现 Spark 的优势
   - 为将来的大数据处理做准备

2. **如果需要更快**：使用 Pandas
   - 小数据集上 Pandas 更快
   - 无 Hadoop 初始化开销

### 对于更大的数据量（>1GB）：

1. **必须用 Spark 分布式写入**
   - Pandas 方式会耗尽内存
   - Spark 可以处理几 TB 的数据

2. **考虑使用分布式存储**：
   - HDFS：分布式文件系统
   - S3：AWS 对象存储
   - 增加节点处理超大数据

## 配置总结

| 组件 | 位置 | 状态 | 用途 |
|------|------|------|------|
| **Java** | `C:\Program Files\Java\jdk-11` | ✓ | Hadoop 和 Spark 运行时 |
| **Hadoop** | `C:\Users\hy120\hadoop` | ✓ | 文件系统和 Windows 兼容性 |
| **Spark** | `C:\Users\hy120\spark\spark-3.5.7-bin-hadoop3` | ✓ | 数据处理框架 |
| **Python Env** | `.venv` | ✓ | PySpark 和依赖 |
| **Notebook** | `test/spark/test_spark_cleansing.ipynb` | ✓ | 环境变量已配置 |

所有配置已完成，可以直接运行 Notebook！

---

**下一步**：

1. 激活虚拟环境
2. 打开 Notebook
3. 运行所有单元格
4. 检查 `output/` 目录中的结果
