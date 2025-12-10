# 生产环境增量数据处理方案

## 背景
用户目前有两个静态CSV文件用于练习，但想了解生产环境中如何处理每天新增的数据。假设数据按日期命名存储在S3中，如：`customer_base_20251203.csv`

## 当前架构分析
- S3存储：使用分层结构 (raw/ -> cleaned/ -> features/)
- Glue Crawler：每天扫描S3并更新Glue Catalog
- Glue ETL：从Catalog读取数据，进行清洗和特征工程
- 当前处理模式：`overwrite` 模式，每次全量覆盖

## 推荐方案：基于日期分区的增量处理

### 核心设计理念
1. **S3按日期分区存储**：使用标准Hive分区格式
2. **Glue增量处理**：只处理新到达的分区数据
3. **自动化分区管理**：Crawler自动发现新分区
4. **灵活的历史数据策略**：支持快照和覆盖两种模式

---

## 实施方案

### 1. S3目录结构重组

#### 原始数据层 (raw/)
```
s3://bucket/raw/customer_base/
  ├── date=2025-12-01/
  │   └── customer_base_20251201.csv
  ├── date=2025-12-02/
  │   └── customer_base_20251202.csv
  └── date=2025-12-03/
      └── customer_base_20251203.csv

s3://bucket/raw/customer_behavior_assets/
  ├── date=2025-12-01/
  │   └── customer_behavior_assets_20251201.csv
  └── ...
```

**优点**：
- Glue Crawler自动识别分区
- 查询时可按日期过滤
- 便于数据管理和删除

#### 清洗数据层 (cleaned/)
```
s3://bucket/cleaned/customer_base/
  ├── date=2025-12-01/
  │   └── part-00000.parquet
  └── date=2025-12-02/
      └── part-00000.parquet
```

#### 特征数据层 (features/)
```
s3://bucket/features/customer_features/
  └── date=2025-12-03/
      └── part-00000.parquet
```

---

### 2. Glue增量处理策略

#### 方案A：每日快照模式（推荐用于历史分析）
- **适用场景**：需要追踪客户状态变化历史
- **处理逻辑**：每天处理新分区，保留所有历史分区
- **存储成本**：较高（保留完整历史）
- **查询灵活性**：高（可查询任意时间点状态）

#### 方案B：最新状态模式（推荐用于实时应用）
- **适用场景**：只关心最新客户状态
- **处理逻辑**：每天处理新分区，覆盖或合并到主表
- **存储成本**：低（只保留最新状态）
- **查询性能**：高（数据量小）

---

### 3. 修改内容详解

#### 3.1 修改Glue Crawler配置
**文件**: `glue_scripts/config/glue_jobs_config.json`

**变更点**：
- 启用分区投影(Partition Projection)以提高性能
- 配置Crawler自动发现新分区
- 添加分区过滤规则

#### 3.2 修改数据清洗脚本
**文件**: `glue_scripts/1_data_cleansing.py`

**新增功能**：
1. **参数化处理日期**
   - 添加 `--PROCESSING_DATE` 参数（默认：昨天）
   - 支持批量回填历史数据

2. **增量读取**
   - 使用 `pushDownPredicate` 过滤特定分区
   - 只读取需要处理的日期分区

3. **输出模式选择**
   - 支持 `append` 模式（快照）
   - 支持 `overwrite` 模式（单分区覆盖）
   - 支持 `merge` 模式（upsert语义）

4. **Job Bookmark集成**
   - 使用Glue Job Bookmark跟踪处理进度
   - 自动处理未处理的分区

#### 3.3 修改特征工程脚本
**文件**: `glue_scripts/2_feature_engineering.py`

**变更点**：
- 根据清洗数据的最新分区触发
- 支持增量特征计算或全量重算
- 添加滑动窗口特征（如：最近7天/30天指标）

#### 3.4 添加分区管理脚本（新建）
**文件**: `glue_scripts/utils/partition_manager.py`

**功能**：
- 获取未处理的分区列表
- 清理过期分区（根据retention policy）
- 手动触发特定日期回填

#### 3.5 Terraform配置更新
**文件**: `infra/modules/glue/main.tf`

**变更点**：
- 添加Job Bookmark配置
- 配置S3事件触发器（可选，用于准实时处理）
- 添加分区管理相关IAM权限

---

### 4. 数据上传最佳实践

#### 方式1：手动上传（练习环境）
```bash
# 使用AWS CLI上传
aws s3 cp customer_base_20251203.csv \
  s3://bucket/raw/customer_base/date=2025-12-03/

# Crawler会在下次运行时自动发现新分区
```

#### 方式2：自动化脚本（生产环境）
```python
# 每天由上游系统调用
import boto3
from datetime import datetime

s3 = boto3.client('s3')
today = datetime.now().strftime('%Y-%m-%d')

s3.upload_file(
    'customer_base.csv',
    'bucket',
    f'raw/customer_base/date={today}/customer_base_{today.replace("-", "")}.csv'
)
```

#### 方式3：S3事件触发（准实时）
- 配置S3 Event Notification
- 新文件到达时触发Lambda
- Lambda启动Glue Job处理新分区

---

### 5. 处理流程示例

#### 场景：每天凌晨处理前一天数据

**时间轴**：
```
23:50 - 上游系统将数据上传到 s3://bucket/raw/.../date=2025-12-03/
00:00 - Crawler运行，发现新分区，更新Glue Catalog
02:00 - Glue Job (data-cleansing) 启动
       - 读取 date=2025-12-03 分区
       - 清洗数据
       - 输出到 cleaned/date=2025-12-03/
02:30 - Crawler (cleaned) 更新Catalog
03:00 - Glue Job (feature-engineering) 启动
       - 读取 date=2025-12-03 清洗数据
       - 计算特征
       - 输出到 features/date=2025-12-03/
```

#### 查询示例
```sql
-- 查询最新一天数据
SELECT * FROM cleaned_customer_base
WHERE date = '2025-12-03';

-- 查询最近7天数据
SELECT * FROM cleaned_customer_base
WHERE date >= date_add('day', -7, current_date);

-- 查询所有历史数据
SELECT * FROM cleaned_customer_base;
```

---

### 6. 优化建议

#### 性能优化
1. **分区剪枝**：查询时始终带上日期过滤条件
2. **文件合并**：定期合并小文件（S3 DistCP或Glue Job）
3. **列式存储**：使用Parquet格式并启用压缩（Snappy/ZSTD）
4. **分区投影**：对于规则的日期分区，使用Partition Projection避免Catalog调用

#### 成本优化
1. **生命周期策略**：
   - raw数据：90天后转到IA存储，180天后归档到Glacier
   - cleaned数据：180天后转到IA
   - features数据：365天保留

2. **按需删除**：
   - 定期删除不再需要的历史分区
   - 使用S3 Lifecycle Rules自动化

#### 可靠性
1. **失败重试**：Glue Job配置最大重试次数
2. **数据验证**：处理后验证记录数、必填字段等
3. **告警监控**：CloudWatch监控Job失败、数据量异常

---

## 关键文件清单

### 需要修改的文件
1. `glue_scripts/config/glue_jobs_config.json` - 添加分区相关配置
2. `glue_scripts/1_data_cleansing.py` - 增量处理逻辑
3. `glue_scripts/2_feature_engineering.py` - 支持增量特征
4. `infra/modules/glue/main.tf` - Job Bookmark和IAM配置

### 需要新建的文件
1. `glue_scripts/utils/partition_manager.py` - 分区管理工具
2. `glue_scripts/utils/s3_uploader.py` - 数据上传辅助脚本
3. `docs/feature-engineering/incremental_processing_guide.md` - 操作文档

---

## 实施步骤

### Phase 1: S3结构调整
1. 创建新的分区目录结构
2. 将现有数据移动到 `date=2025-12-01/` 分区
3. 测试Crawler是否正确识别分区

### Phase 2: 代码修改
1. 更新Glue Job配置文件
2. 修改数据清洗脚本支持分区
3. 修改特征工程脚本支持增量
4. 添加分区管理工具

### Phase 3: Terraform部署
1. 更新Glue相关Terraform配置
2. 应用变更到AWS环境

### Phase 4: 测试验证
1. 上传新日期的测试数据
2. 手动触发Glue Job测试增量处理
3. 验证输出数据正确性
4. 测试查询性能

### Phase 5: 文档和自动化
1. 编写操作文档
2. 配置定时任务
3. 设置监控告警

---

## 常见问题

**Q: 如果某天忘记上传数据怎么办？**
A: 当日Job会因找不到分区而跳过，第二天可以回填历史数据并手动触发Job

**Q: 数据到达时间不固定怎么办？**
A: 使用S3事件触发Lambda，Lambda检测到新文件后启动Glue Job

**Q: 需要重新处理历史数据怎么办？**
A: 使用分区管理脚本，指定日期范围批量回填

**Q: 分区太多会影响查询性能吗？**
A: 使用Partition Projection可以避免这个问题，或定期合并历史分区
