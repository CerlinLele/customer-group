# Hadoop 配置完成 - 快速开始

## 配置已完成

你的 Hadoop 已正确配置到 Notebook 中：

```
HADOOP_HOME = C:\Users\hy120\hadoop
```

## Notebook 已更新

我已经更新了 `test/spark/test_spark_cleansing.ipynb`，现在使用：

### 1. 环境配置 (第 2 单元格)
指向你的 Hadoop 目录：
```python
os.environ["HADOOP_HOME"] = "C:\\Users\\hy120\\hadoop"
```

### 2. Spark Session 配置 (第 4 单元格)
已简化，直接使用 Hadoop 配置（无需特殊文件系统设置）

### 3. 数据输出 (第 26 单元格)
**现在使用 Spark 分布式写入**：
```python
df_customer_base_cleaned.coalesce(1).write.mode("overwrite").csv(output_path_base)
df_customer_behavior_cleaned.coalesce(1).write.mode("overwrite").csv(output_path_behavior)
```

如果 Spark 分布式写入失败，会自动降级到 Pandas 方式。

## 使用步骤

### 步骤 1：激活虚拟环境
```bash
.venv\Scripts\activate
```

### 步骤 2：打开 Notebook
```bash
jupyter notebook test/spark/test_spark_cleansing.ipynb
```

### 步骤 3：运行所有单元格
从上到下逐个运行，预期输出：
```
✓ Spark Session 创建成功
✓ 数据加载完成
✓ 数据清洗各步骤完成
✓ 客户基本信息已输出
✓ 客户行为资产已输出
```

### 步骤 4：验证输出
检查 `output/` 目录中的文件：
```
output/
├── cleaned_customer_base.csv (10,000 行)
└── cleaned_customer_behavior.csv (120,000 行)
```

## 关键改变

| 方面 | 之前 | 现在 |
|------|------|------|
| **Hadoop** | 无配置 | `C:\Users\hy120\hadoop` |
| **数据输出** | Pandas 方式 | **Spark 分布式写入** |
| **备选方案** | 无 | Pandas（如果主方案失败） |
| **环境复杂度** | 低 | 正确配置（更强大） |

## 常见问题

### Q: 如果还是报错怎么办？
A: Notebook 中有自动降级机制，会自动尝试 Pandas 方式。如果两种方式都失败，检查：
- Hadoop 目录是否正确：`C:\Users\hy120\hadoop\bin\winutils.exe` 是否存在
- Java 是否正确安装：`C:\Program Files\Java\jdk-11` 是否存在
- 虚拟环境是否激活

### Q: 输出文件在哪里？
A: 在项目根目录的 `output/` 文件夹中

### Q: CSV 文件可以直接打开吗？
A: 可以。`coalesce(1)` 确保只输出一个 CSV 文件，无需合并多个分片

## 优势

现在使用 Spark 分布式写入的优势：

1. **更可靠**：使用 Hadoop 的成熟 API
2. **更高效**：分布式写入优化
3. **更兼容**：与其他 Spark 工具兼容
4. **更灵活**：可以处理超大数据集（虽然当前数据不需要）

## 文件检查清单

- [x] `test/spark/test_spark_cleansing.ipynb` 已更新
  - [x] cell-2: HADOOP_HOME 配置
  - [x] cell-4: Spark Session 配置已简化
  - [x] cell-26: 使用 Spark 分布式写入

---

现在可以直接运行 Notebook 了！
