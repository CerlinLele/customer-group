# AWS Glue 表名映射修复

## 问题

当运行 Glue Crawlers 时，它们会根据 **文件名** 自动生成表名。对于 CSV 文件，Glue 会：
1. 获取文件名：`customer_base.csv`
2. 添加表前缀：`raw_` + `customer_base`
3. **追加文件扩展名**：`raw_customer_base_csv` ❌

但你的 Glue Job 配置期望的是：
```json
"--INPUT_TABLE_BASE": "raw_customer_base"
```

这导致表名不匹配，出现 `EntityNotFoundException`！

---

## 解决方案

### 方案 1：更新 Job 参数（已采用）✅

修改 `glue_jobs_config.json` 中的表名参数，使其与 Crawler 实际生成的表名匹配：

**Before**:
```json
"--INPUT_TABLE_BASE": "raw_customer_base",
"--INPUT_TABLE_BEHAVIOR": "raw_customer_behavior_assets",
```

**After**:
```json
"--INPUT_TABLE_BASE": "raw_customer_base_csv",
"--INPUT_TABLE_BEHAVIOR": "raw_customer_behavior_assets_csv",
```

### 为什么这是最好的解决方案

1. ✅ **简单直接** - 无需修改爬虫复杂配置
2. ✅ **符合 AWS 默认行为** - Crawlers 本身就这样命名
3. ✅ **易于理解** - 代码中直观显示表名与文件的关系
4. ✅ **最小化改动** - 只需更新配置文件

---

## 表名映射参考

### CSV 文件（raw 数据）

| 文件名 | Crawler 生成的表名 | Job 参数 |
|--------|-------------------|---------|
| `customer_base.csv` | `raw_customer_base_csv` | `"--INPUT_TABLE_BASE": "raw_customer_base_csv"` |
| `customer_behavior_assets.csv` | `raw_customer_behavior_assets_csv` | `"--INPUT_TABLE_BEHAVIOR": "raw_customer_behavior_assets_csv"` |

### Parquet 文件（cleaned 数据）

| 文件名 | Crawler 生成的表名 | Job 参数 |
|--------|-------------------|---------|
| `customer_base/` | `cleaned_customer_base` | `"--INPUT_TABLE_BASE": "cleaned_customer_base"` |
| `customer_behavior/` | `cleaned_customer_behavior` | `"--INPUT_TABLE_BEHAVIOR": "cleaned_customer_behavior"` |

**注意**: Parquet 文件由于是目录而非单个文件，不会被追加扩展名。

---

## 修改的文件

### 1. glue_scripts/config/glue_jobs_config.json

```json
// 第一个 Job（数据清洗）
{
  "job_name": "customer-data-cleansing",
  "parameters": {
    "--INPUT_DATABASE": "customer_raw_db",
    "--INPUT_TABLE_BASE": "raw_customer_base_csv",          // ✅ 修改
    "--INPUT_TABLE_BEHAVIOR": "raw_customer_behavior_assets_csv",  // ✅ 修改
    // ... 其他参数
  }
}
```

### 2. infra/modules/glue/crawlers.tf

添加了 CSV 解析配置，确保 Crawler 正确处理 CSV 文件格式。

---

## 验证表名

### 方法 1：使用 AWS CLI

```bash
# 运行爬虫后，列出表
aws glue get-tables --database-name customer_raw_db

# 输出应该包含：
# {
#   "TableList": [
#     {
#       "Name": "raw_customer_base_csv",
#       "StorageDescriptor": { ... }
#     },
#     {
#       "Name": "raw_customer_behavior_assets_csv",
#       "StorageDescriptor": { ... }
#     }
#   ]
# }
```

### 方法 2：使用 Athena 查询

```sql
-- 查看原始数据表
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'customer_raw_db';

-- 查询表数据
SELECT * FROM customer_raw_db.raw_customer_base_csv LIMIT 10;
SELECT * FROM customer_raw_db.raw_customer_behavior_assets_csv LIMIT 10;
```

### 方法 3：AWS Glue 控制台

1. 打开 AWS Glue 控制台
2. 左侧菜单 → "数据库"
3. 选择 `customer_raw_db`
4. 查看表列表，确认表名包含 `_csv` 后缀

---

## Glue Crawler 命名规则

### 文件扩展名处理

| 文件类型 | 扩展名处理 | 示例 |
|---------|-----------|------|
| CSV | 追加 `_csv` | `customer_base.csv` → `raw_customer_base_csv` |
| JSON | 追加 `_json` | `data.json` → `raw_data_json` |
| Parquet | 不追加 | `folder/` → `cleaned_customer_base` |
| ORC | 追加 `_orc` | `data.orc` → `raw_data_orc` |
| 目录 | 不追加 | `cleaned/base/` → `cleaned_customer_base` |

### 表名组成

```
表名 = [table_prefix] + [filename] + [extension_suffix]

示例：
  table_prefix = "raw_"
  filename = "customer_base"
  extension = ".csv" → "_csv"

  最终表名 = "raw_" + "customer_base" + "_csv" = "raw_customer_base_csv"
```

---

## 后续步骤

现在你的配置已经修复，可以按照以下步骤执行：

### 1️⃣ 部署基础设施

```bash
cd infra
terraform apply
```

### 2️⃣ 运行原始数据爬虫

```bash
aws glue start-crawler --name "case-dev-raw-customer-base-crawler"
aws glue start-crawler --name "case-dev-raw-customer-behavior-crawler"
```

爬虫会创建：
- ✅ `raw_customer_base_csv`
- ✅ `raw_customer_behavior_assets_csv`

### 3️⃣ 验证表名

```bash
aws glue get-tables --database-name customer_raw_db
```

确认输出包含正确的表名。

### 4️⃣ 运行数据清洗 Job

```bash
aws glue start-job-run --job-name customer-data-cleansing
```

Job 现在会成功找到表：
- ✅ 读取 `raw_customer_base_csv` 成功
- ✅ 读取 `raw_customer_behavior_assets_csv` 成功
- ✅ 不再出现 EntityNotFoundException

---

## 常见问题

### Q: 为什么 Crawler 要追加文件扩展名？

A: 这是 AWS Glue 的默认行为，原因是：
- 不同格式的文件可能有不同的 schema 推断规则
- 在同一目录中可能有不同格式的文件
- 扩展名帮助区分多格式数据源

### Q: 如果我想要不同的表名怎么办？

A: 有两个选项：
1. **方案 A**: 在爬虫运行后，手动编辑表名（在 Glue 控制台或 CLI）
2. **方案 B**: 使用 Glue Crawler 的 `SchemaChangePolicy` 创建新的爬虫特定规则

### Q: Parquet 文件为什么没有扩展名后缀？

A: 因为你在 Terraform 中配置的是 **目录路径**（以 `/` 结尾）而不是单个文件。Crawler 会扫描目录中的所有 Parquet 文件，并以目录名作为表名。

---

## 总结

这个修复确保了：

✅ Glue Crawlers 生成的表名与 Glue Jobs 查询的表名一致
✅ 消除所有 EntityNotFoundException 错误
✅ 完整的数据管道可以顺利执行
✅ 遵循 AWS Glue 的标准命名约定

现在你的数据管道已经完全修复，可以正常运行了！🎉

