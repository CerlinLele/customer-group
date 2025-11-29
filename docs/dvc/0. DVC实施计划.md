# DVC (Data Version Control) 实施计划
## 客户分群精准营销项目 - MLOps 实践

---

## 📋 项目现状快照 (2025-11-29 更新)

### 当前状态
- **项目阶段**: 初始规划阶段,准备实施 DVC
- **Git 状态**: ✅ 已初始化 (当前分支: dvc, 4次提交)
- **DVC 状态**: ❌ 尚未初始化
- **代码状态**: ❌ 尚未开发 (仅有数据和文档)
- **文件总数**: 5个文件 (2个数据文件 + 3个文档文件)

### 现有资源
| 类型 | 文件名 | 大小 | 状态 |
|------|--------|------|------|
| 数据 | customer_base.csv | 1.6MB | ✅ 根目录 |
| 数据 | customer_behavior_assets.csv | 24.6MB | ✅ 根目录 |
| 文档 | 项目说明.txt | 0.7KB | ✅ 业务目标 |
| 文档 | 字段说明.md | 8.1KB | ✅ 数据字典 |
| 文档 | DVC实施计划.md | 22.8KB | ✅ 本文件 |

### 待创建资源
- **目录**: 6个 (data/, models/, scripts/, outputs/, docs/, tests/)
- **配置文件**: 5个 (config.py, params.yaml, dvc.yaml, requirements.txt, README.md)
- **Python 模块**: 6个 (models/ 下的各类模型)
- **执行脚本**: 8个 (scripts/ 下的流水线脚本)

### 下一步行动
1. ⏳ 安装 DVC: `pip install dvc`
2. ⏳ 初始化 DVC: `dvc init`
3. ⏳ 配置远程存储并追踪数据
4. ⏳ 创建项目目录结构
5. ⏳ 开始实施第1周的任务

---

## 📖 文档目录

1. [项目现状分析](#1-项目现状分析) - 现有资源和待创建资源清单
2. [DVC 项目结构设计](#2-dvc-项目结构设计) - 推荐的目录结构和文件组织
3. [DVC 流水线架构设计](#3-dvc-流水线架构设计) - 7阶段流水线详解
4. [参数配置设计](#4-参数配置设计-paramsyaml) - params.yaml 完整配置
5. [远程存储策略](#5-远程存储策略) - 本地/云端存储方案
6. [版本管理策略](#6-版本管理策略) - 数据和模型版本控制
7. [团队协作工作流](#7-团队协作工作流) - Git+DVC 协作流程
8. [与现有项目的集成方案](#8-与现有项目的集成方案) - **⚡ 立即可用的实施步骤**
9. [实施路线图](#9-实施路线图-基于当前项目现状) - **⚡ 4周完整计划**
10. [关键成功因素与建议](#10-关键成功因素与建议) - 最佳实践和即时行动
11. [核心文件清单](#11-核心文件清单) - 最关键的5个文件
12. [附录: 快速参考](#附录快速参考) - DVC 常用命令速查

**快速跳转**:
- 🚀 [快速启动指南](#快速启动指南-第1天可完成) - 30分钟完成 DVC 初始化
- ⚡ [即时行动步骤](#103-即时行动步骤-现在就可以开始) - 5步开始 DVC 之旅
- 📊 [项目现状快照](#-项目现状快照-2025-11-29-更新) - 当前项目状态总览

---

## 1. 项目现状分析

### 1.1 现有资源 ✅
- **数据文件** (位于项目根目录):
  - customer_base.csv (10,001 行, ~1.6MB) - 客户基础信息
  - customer_behavior_assets.csv (120,001 行, ~24.6MB) - 12个月行为资产数据
- **文档文件**:
  - 项目说明.txt - 业务目标与关键举措
  - 字段说明.md - 完整的数据字典文档(23个字段详细说明)
- **版本控制**:
  - Git 仓库已初始化 (当前分支: dvc, 主分支: main)
  - 虚拟环境 .venv 已创建
  - 已有4次提交历史

### 1.2 待创建资源 ⏳
- **代码模块** (models/ 目录需创建):
  - data_loader.py - 数据加载器
  - preprocessing.py - 数据清洗和预处理
  - feature_engineering.py - 特征工程
  - customer_analyzer.py - 客户分析算法
  - segmentation.py - 聚类和分群
  - prediction.py - 转化预测模型
- **执行脚本** (scripts/ 目录需创建):
  - validate_data.py, preprocess.py, feature_engineering.py
  - split_data.py, train_conversion.py, train_segmentation.py
  - train_high_value.py, evaluate.py
- **配置文件**:
  - config.py - Python 配置模块
  - params.yaml - DVC 参数配置
  - dvc.yaml - DVC 流水线定义
  - requirements.txt - Python 依赖包

### 1.3 业务目标与需求
- **核心任务**:
  - 客户转化预测(AUC ≥ 0.85) - 预测百万级客户转化
  - 客户分群与画像 - 识别高复购、中产家庭等群体
  - 高价值客户识别 - 优化营销资源分配
- **应用场景**:
  - Flask 可视化大屏系统 - 资产分层、高潜力客户画像
  - 四维评分模型 - 资产40% + 活跃度30% + 成长性20% + 消费力10%
  - 动态名单更新 - 高潜力客户实时追踪
  - 精准营销渠道 - APP弹窗、电话外呼、转化率监控

---

## 2. DVC 项目结构设计

### 2.1 推荐的目录结构 (基于现有项目)

```
CASE-customer-group/
├── .dvc/                          # DVC 内部配置 (待初始化)
│   ├── config                     # DVC 配置(远程存储等)
│   └── cache/                     # 本地 DVC 缓存
├── .git/                          # Git 仓库 ✅ (已存在)
├── .venv/                         # Python 虚拟环境 ✅ (已存在)
├── .claude/                       # Claude Code 配置 ✅ (已存在)
│
├── data/                          # 数据目录 (待创建, DVC追踪)
│   ├── raw/                       # 原始数据源
│   │   ├── customer_base.csv.dvc
│   │   └── customer_behavior_assets.csv.dvc
│   ├── processed/                 # 清洗后的数据
│   │   ├── cleaned_base.csv.dvc
│   │   ├── cleaned_behavior.csv.dvc
│   │   └── merged_customer_data.csv.dvc
│   ├── features/                  # 特征工程输出
│   │   ├── customer_features.csv.dvc
│   │   └── feature_importance.json
│   └── splits/                    # 训练/验证/测试集
│       ├── train.csv.dvc
│       ├── val.csv.dvc
│       └── test.csv.dvc
│
├── models/                        # Python 模块 (待创建)
│   ├── __init__.py
│   ├── data_loader.py             # 数据加载
│   ├── preprocessing.py           # 数据清洗和预处理
│   ├── feature_engineering.py     # 特征创建
│   ├── customer_analyzer.py       # 客户分析算法
│   ├── segmentation.py            # 聚类和分群
│   └── prediction.py              # 转化预测模型
│
├── outputs/                       # 模型输出和产物 (待创建, DVC追踪)
│   ├── models/                    # 训练好的模型
│   │   ├── conversion_model.pkl.dvc
│   │   ├── segmentation_model.pkl.dvc
│   │   └── high_value_scorer.pkl.dvc
│   ├── predictions/               # 预测结果
│   │   ├── conversion_predictions.csv.dvc
│   │   └── customer_segments.csv.dvc
│   └── metrics/                   # 模型指标
│       ├── conversion_metrics.json
│       ├── segmentation_metrics.json
│       └── high_value_metrics.json
│
├── scripts/                       # 独立执行脚本 (待创建)
│   ├── validate_data.py           # 数据验证
│   ├── preprocess.py              # 数据预处理
│   ├── feature_engineering.py     # 特征工程
│   ├── split_data.py              # 数据切分
│   ├── train_conversion.py        # 训练转化预测模型
│   ├── train_segmentation.py      # 训练分群模型
│   ├── train_high_value.py        # 训练高价值评分模型
│   └── evaluate.py                # 模型评估
│
├── docs/                          # 文档目录 (可选)
│   ├── 项目说明.txt ✅            # 移动自根目录
│   ├── 字段说明.md ✅             # 移动自根目录
│   └── DVC实施计划.md ✅          # 当前文件
│
├── config.py                      # 配置文件 (待创建)
├── params.yaml                    # DVC 参数配置 (待创建)
├── dvc.yaml                       # DVC 流水线定义 (待创建)
├── dvc.lock                       # DVC 流水线锁定文件 (自动生成)
├── metrics.json                   # 模型指标汇总 (DVC追踪)
├── .dvcignore                     # DVC 忽略文件 (待创建)
├── .gitignore                     # Git 忽略文件 (待更新)
├── requirements.txt               # Python 依赖 (待创建)
└── README.md                      # 项目文档 (待创建)
│
├── customer_base.csv ✅           # 待移动到 data/raw/
└── customer_behavior_assets.csv ✅ # 待移动到 data/raw/
```

### 2.2 Git vs DVC 分工

**Git 追踪（小文本文件）**：
- 源代码（.py 文件）
- 配置文件（params.yaml, config.py）
- DVC 元文件（.dvc 文件, dvc.yaml, dvc.lock）
- 文档（README.md）
- 轻量级指标（metrics.json）

**DVC 追踪（大型数据/模型文件）**：
- 原始数据文件（CSV）
- 处理后的数据
- 特征工程输出
- 训练好的模型文件（.pkl）
- 大型预测结果

---

## 3. DVC 流水线架构设计

### 3.1 流水线概览

```
数据验证 (validate_data)
    ↓
数据预处理 (preprocess)
    ↓
特征工程 (feature_engineering)
    ↓
数据切分 (split_data)
    ↓
模型训练（并行3个模型）
    ├── 转化预测模型 (train_conversion_model)
    ├── 客户分群模型 (train_segmentation_model)
    └── 高价值评分模型 (train_high_value_scorer)
    ↓
模型评估 (evaluate_models)
```

### 3.2 流水线各阶段说明

#### Stage 1: 数据验证 (validate_data)
- **目的**：检查数据质量和完整性
- **输入**：原始 CSV 文件
- **输出**：数据质量报告
- **检查项**：缺失值、重复项、日期范围、数据类型

#### Stage 2: 数据预处理 (preprocess)
- **目的**：清洗和合并数据
- **输入**：原始数据 + 验证通过
- **输出**：清洗后的数据和合并数据
- **操作**：缺失值处理、异常值处理、数据合并

#### Stage 3: 特征工程 (feature_engineering)
- **目的**：创建模型特征
- **输入**：合并后的客户数据
- **输出**：特征数据集 + 特征重要性
- **特征类型**：
  - 资产增长率
  - APP 活跃度评分
  - 产品多样性指数
  - RFM 评分
  - 时间序列趋势特征

#### Stage 4: 数据切分 (split_data)
- **目的**：划分训练/验证/测试集
- **输入**：特征数据集
- **输出**：train.csv, val.csv, test.csv
- **策略**：按资产等级分层抽样

#### Stage 5a: 转化预测模型 (train_conversion_model)
- **目的**：预测客户转化概率
- **算法**：XGBoost / LightGBM / Random Forest
- **目标指标**：AUC ≥ 0.85
- **输出**：模型文件 + 性能指标

#### Stage 5b: 客户分群模型 (train_segmentation_model)
- **目的**：客户聚类分群
- **算法**：K-Means / Hierarchical Clustering
- **输出**：分群模型 + 客户分群结果

#### Stage 5c: 高价值评分模型 (train_high_value_scorer)
- **目的**：识别高价值客户
- **方法**：四维评分模型（资产40% + 活跃度30% + 成长性20% + 消费力10%）
- **输出**：评分模型 + 高价值客户列表

#### Stage 6: 模型评估 (evaluate_models)
- **目的**：综合评估所有模型
- **输入**：测试集 + 所有训练好的模型
- **输出**：评估报告（HTML）+ SHAP 解释

---

## 4. 参数配置设计 (params.yaml)

### 4.1 参数分类结构

```yaml
# 数据验证参数
validate:
  check_nulls: true
  check_duplicates: true
  date_range:
    start: "2024-01"
    end: "2024-12"
  expected_customers: 10000
  expected_months: 12

# 数据预处理参数
preprocess:
  handle_missing: "mean"        # mean, median, drop
  outlier_threshold: 3.0        # Z-score 阈值
  date_format: "%Y-%m-%d"

# 特征工程参数
features:
  time_window_months: 3         # 滚动窗口大小
  aggregation_methods:          # 聚合方法
    - mean
    - std
    - trend
  categorical_encoding: "onehot" # onehot, label
  scaling_method: "standard"     # standard, minmax

# 数据切分参数
split:
  test_size: 0.2
  val_size: 0.1
  random_state: 42
  stratify_column: "asset_level"

# 转化预测模型参数
conversion_model:
  algorithm: "xgboost"
  n_estimators: 200
  learning_rate: 0.05
  max_depth: 6
  min_samples_split: 100
  class_weight: "balanced"

# 客户分群参数
segmentation:
  algorithm: "kmeans"
  n_clusters: 5
  features_subset:
    - total_assets
    - monthly_income
    - app_login_count
    - product_count

# 高价值评分参数
high_value:
  score_weights:
    asset_weight: 0.4
    behavior_weight: 0.3
    potential_weight: 0.3
  threshold_percentile: 90

# 模型评估参数
evaluate:
  auc_threshold: 0.85
  generate_shap: true
  shap_sample_size: 1000
```

### 4.2 参数化的好处
- **易于实验**：修改参数后自动重新运行流水线
- **可追溯性**：Git 追踪参数变化历史
- **团队协作**：统一的参数管理
- **避免硬编码**：所有超参数集中管理

---

## 5. 远程存储策略

### 5.1 存储方案推荐

#### 方案 1：本地网络存储（企业推荐）
**优点**：完全控制、无云成本、满足合规要求

**配置方法**：
```bash
# 配置共享 NAS 存储
dvc remote add -d nas /mnt/company-nas/dvc-storage/customer-project

# 或 Windows 网络驱动器
dvc remote add -d nas \\server\share\dvc-storage\customer-project
```

#### 方案 2：AWS S3（可扩展推荐）
**优点**：可扩展、可靠、适合分布式团队

**配置方法**：
```bash
dvc remote add -d s3remote s3://company-bucket/customer-segmentation
dvc remote modify s3remote region cn-north-1  # 中国北京区域
```

#### 方案 3：Azure Blob Storage（备选）
**优点**：与 Microsoft 生态集成

**配置方法**：
```bash
dvc remote add -d azure azure://customer-segmentation/dvc-storage
dvc remote modify azure account_name company-storage
```

#### 方案 4：本地外部驱动器（开发测试）
**优点**：简单、无网络依赖
**缺点**：不适合团队协作

**配置方法**：
```bash
dvc remote add -d local /d/dvc-storage/customer-project
```

### 5.2 存储规划

**预估存储需求**：
- 原始数据：~30MB
- 处理后数据：~50MB
- 特征工程数据：~80MB
- 模型文件：~100MB
- 预测结果：~50MB
- **单次实验总计：~310MB**

**推荐配置**：
- 最小：5GB（15-20 个实验版本）
- 推荐：20GB（60+ 个实验）
- 企业：50-100GB（长期历史）

### 5.3 生产环境配置

```bash
# 主存储（团队共享）
dvc remote add -d production s3://company-ml-storage/customer-segmentation

# 备份存储（灾难恢复）
dvc remote add backup azure://customer-seg-backup/dvc-storage

# 本地缓存配置
dvc config cache.type symlink        # 使用符号链接节省空间
dvc config cache.shared group        # 团队共享缓存
```

---

## 6. 版本管理策略

### 6.1 数据版本管理

**命名规范**：
```
v{MAJOR}.{MINOR}-{DESCRIPTION}

示例：
- v1.0-initial-raw-data
- v1.1-fixed-missing-values
- v2.0-added-external-features
```

**Git 标签管理**：
```bash
# 标记初始数据版本
git tag -a data-v1.0 -m "Initial raw customer data"

# 标记数据清洗后
git tag -a data-v1.1 -m "Cleaned data with missing value imputation"

# 标记生产就绪特征集
git tag -a data-v2.0-prod -m "Production feature set Q4-2024"
```

### 6.2 模型版本管理

**命名规范**：
```
model-{MODEL_TYPE}-v{VERSION}-{METRIC}

示例：
- model-conversion-v1.0-auc0.83
- model-conversion-v1.2-auc0.87
- model-segmentation-v2.0-silhouette0.75
```

**标签示例**：
```bash
# 标记达到 AUC 要求的模型
git tag -a model-conversion-v1.2-auc0.87 -m "Conversion model achieving AUC 0.87"

# 标记生产部署
git tag -a prod-release-2024q4 -m "Production release Q4 2024"

# 标记最佳性能模型
git tag -a best-conversion-model -m "Best conversion model (AUC 0.89)"
```

### 6.3 实验版本管理

**DVC 实验工作流**：
```bash
# 创建新实验
dvc exp run --name exp-005-deep-features

# 修改参数运行实验
dvc exp run --set-param conversion_model.learning_rate=0.1

# 比较实验结果
dvc exp show --include-params --include-metrics

# 应用最佳实验
dvc exp apply exp-005-deep-features
git commit -m "Apply best experiment exp-005"
```

### 6.4 版本回滚策略

**数据回滚**：
```bash
# 查看数据版本历史
git log --oneline data/raw/customer_base.csv.dvc

# 回滚到特定版本
git checkout data-v1.0 data/raw/customer_base.csv.dvc
dvc checkout data/raw/customer_base.csv.dvc
dvc pull
```

**模型回滚**：
```bash
# 回滚到之前的模型版本
git checkout model-conversion-v1.0 outputs/models/conversion_model.pkl.dvc
dvc checkout outputs/models/conversion_model.pkl.dvc
dvc pull
```

---

## 7. 团队协作工作流

### 7.1 数据科学家实验流程

**步骤 1：克隆仓库和设置**
```bash
git clone <repository-url>
cd CASE-customer-group
pip install -r requirements.txt
dvc pull  # 拉取数据和模型
```

**步骤 2：创建实验分支**
```bash
git checkout -b experiment/improve-conversion-model
dvc exp run --name exp-improve-conversion
```

**步骤 3：修改参数并运行**
```bash
# 编辑 params.yaml
vim params.yaml

# 运行流水线
dvc repro train_conversion_model
```

**步骤 4：追踪结果**
```bash
# 查看指标
cat outputs/metrics/conversion_metrics.json

# 与基线对比
dvc metrics diff
dvc params diff

# 提交改进
git add params.yaml dvc.lock outputs/metrics/
git commit -m "exp: improve conversion model learning rate"
```

**步骤 5：分享结果**
```bash
dvc push
git push origin experiment/improve-conversion-model
# 创建 Pull Request 进行代码审查
```

### 7.2 数据共享流程

**数据科学家 A 创建新特征**：
```bash
python scripts/feature_engineering.py --new-features
dvc add data/features/customer_features.csv
dvc push
git add data/features/customer_features.csv.dvc .gitignore
git commit -m "feat: add RFM score features"
git push
```

**数据科学家 B 使用新特征**：
```bash
git pull origin main
dvc pull data/features/customer_features.csv.dvc
python scripts/train_conversion.py  # 使用新特征训练
```

### 7.3 模型部署流程

**开发 → 测试 → 生产**

1. **开发阶段**：
```bash
git checkout -b feature/new-segmentation-algorithm
dvc repro train_segmentation_model
dvc push
git commit -m "feat: implement new segmentation algorithm"
```

2. **代码审查和验证**：
```bash
# 创建 PR，团队审查代码和指标
# 审核通过后合并到 main
git checkout main
git merge feature/new-segmentation-algorithm
```

3. **Staging 部署**：
```bash
git tag -a release-staging-2024-12-01 -m "Staging release"
dvc push
git push --tags
```

4. **生产部署**：
```bash
# Staging 验证通过后，标记生产版本
git tag -a release-prod-2024-12-15 -m "Production release Q4"
git push --tags
dvc push

# 生产系统拉取特定版本
git checkout release-prod-2024-12-15
dvc pull outputs/models/
```

---

## 8. 与现有项目的集成方案

### 8.1 非破坏性集成策略 (当前项目适用)

**阶段 1: 初始化 DVC (第1天)** ⚡

不修改任何现有文件,仅设置 DVC:
```bash
cd "c:\Users\hy120\Downloads\zhihullm\CASE-customer group"

# 确认当前在 dvc 分支
git status

# 初始化 DVC
dvc init

# 配置远程存储 (选择一种)
# 选项1: 本地外部驱动器 (开发测试推荐)
dvc remote add -d storage D:\dvc-storage\customer-project

# 选项2: 云存储 (团队协作推荐)
# dvc remote add -d storage s3://your-bucket/customer-segmentation

# 查看配置
dvc remote list
```

**阶段 2: 追踪现有数据 (第1天)** ⚡

```bash
# 追踪根目录的 CSV 文件
dvc add customer_base.csv
dvc add customer_behavior_assets.csv

# 提交到 Git
git add .dvc .dvcignore customer_base.csv.dvc customer_behavior_assets.csv.dvc .gitignore
git commit -m "Initialize DVC and track data files"

# 推送数据到远程存储
dvc push
```

**阶段 3: 重组项目结构 (第2-3天)**

不破坏现有工作的情况下重组:
```bash
# 创建目录结构
mkdir -p data/raw data/processed data/features data/splits
mkdir -p outputs/models outputs/predictions outputs/metrics
mkdir -p models scripts docs tests

# 移动数据文件
git mv customer_base.csv data/raw/
git mv customer_behavior_assets.csv data/raw/

# 移动文档文件 (可选)
git mv 项目说明.txt docs/
git mv 字段说明.md docs/
git mv DVC实施计划.md docs/

# 更新 DVC 追踪
dvc remove customer_base.csv.dvc customer_behavior_assets.csv.dvc
dvc add data/raw/customer_base.csv
dvc add data/raw/customer_behavior_assets.csv

# 提交结构调整
git add .
git commit -m "Restructure project for DVC pipeline"
dvc push
```

**阶段 4: 创建初始配置文件 (第3-4天)**

```bash
# 创建 params.yaml (基础版本)
cat > params.yaml << 'EOF'
# 数据验证参数
validate:
  check_nulls: true
  check_duplicates: true
  expected_customers: 10000
  expected_months: 12

# 数据预处理参数
preprocess:
  handle_missing: "mean"
  outlier_threshold: 3.0

# 数据切分参数
split:
  test_size: 0.2
  val_size: 0.1
  random_state: 42
EOF

# 创建 .dvcignore
cat > .dvcignore << 'EOF'
# Python
__pycache__
*.pyc
.venv/

# IDE
.idea/
.vscode/
.claude/

# 临时文件
*.tmp
.DS_Store
EOF

# 创建 requirements.txt
cat > requirements.txt << 'EOF'
# 数据处理
pandas==2.0.3
numpy==1.24.3

# 机器学习
scikit-learn==1.3.0
xgboost==1.7.6
lightgbm==4.0.0

# DVC
dvc==3.30.0
dvc-s3==3.0.1  # 如使用 S3

# 数据验证
great-expectations==0.17.0

# 模型解释
shap==0.42.1

# 可视化
matplotlib==3.7.2
seaborn==0.12.2

# Web 框架
flask==2.3.3
EOF

git add params.yaml .dvcignore requirements.txt
git commit -m "Add initial DVC configuration files"
```

**阶段 5: 创建简单流水线 (第4-7天)**

从最简单的数据验证开始:
```yaml
# dvc.yaml - 初始简单流水线
stages:
  validate_data:
    cmd: python scripts/validate_data.py
    deps:
      - data/raw/customer_base.csv
      - data/raw/customer_behavior_assets.csv
      - scripts/validate_data.py
    params:
      - validate
    outs:
      - outputs/metrics/validation_report.json
```

### 8.2 当前项目实施清单

**立即可以执行的操作** ✅:
1. ✅ Git 仓库已就绪 (当前在 dvc 分支)
2. ⏳ 安装 DVC: `pip install dvc`
3. ⏳ 初始化 DVC: `dvc init`
4. ⏳ 配置远程存储 (本地或云)
5. ⏳ 追踪现有 CSV 文件

**需要创建的文件** ⏳:
- config.py - Python 配置模块
- params.yaml - DVC 参数
- dvc.yaml - 流水线定义
- requirements.txt - 依赖管理
- .dvcignore - DVC 忽略规则
- README.md - 项目说明

**需要创建的目录和代码** ⏳:
- models/ - 6个 Python 模块
- scripts/ - 8个执行脚本
- data/ - 4个子目录
- outputs/ - 3个子目录

### 8.3 保持向后兼容性

在过渡期间保持灵活性:
```python
# 示例: config.py 适配新旧结构
import os
from pathlib import Path

# 项目根目录
PROJECT_ROOT = Path(__file__).parent

# 数据路径 (自动适配新旧结构)
def get_data_path(filename):
    # 优先使用新结构
    new_path = PROJECT_ROOT / "data" / "raw" / filename
    if new_path.exists():
        return new_path

    # 回退到根目录 (兼容旧结构)
    old_path = PROJECT_ROOT / filename
    if old_path.exists():
        return old_path

    raise FileNotFoundError(f"Data file not found: {filename}")

# 使用示例
CUSTOMER_BASE_PATH = get_data_path("customer_base.csv")
CUSTOMER_BEHAVIOR_PATH = get_data_path("customer_behavior_assets.csv")
```

---

## 9. 实施路线图 (基于当前项目现状)

### 第1周: DVC 基础设施 ⚡ (立即开始)
- **Day 1**:
  - ✅ 分析当前项目结构 (已完成)
  - ⏳ 安装 DVC: `pip install dvc`
  - ⏳ 初始化 DVC: `dvc init`
  - ⏳ 配置本地远程存储
  - ⏳ 追踪现有 CSV 数据文件
- **Day 2-3**:
  - ⏳ 创建目录结构 (data/, models/, scripts/, outputs/)
  - ⏳ 移动数据文件到 data/raw/
  - ⏳ 移动文档文件到 docs/
  - ⏳ 更新 .gitignore
- **Day 4-5**:
  - ⏳ 创建 params.yaml (基础参数配置)
  - ⏳ 创建 requirements.txt (依赖管理)
  - ⏳ 创建 config.py (路径配置)
  - ⏳ 创建 README.md (项目文档)
- **交付物**: DVC 环境就绪, 项目结构标准化, 数据已追踪

### 第2周: 数据处理流水线
- **Day 1-2**:
  - ⏳ 实现 models/data_loader.py (数据加载模块)
  - ⏳ 实现 scripts/validate_data.py (数据验证)
  - ⏳ 创建 dvc.yaml 第一阶段: validate_data
  - ⏳ 测试: `dvc repro validate_data`
- **Day 3-4**:
  - ⏳ 实现 models/preprocessing.py (清洗逻辑)
  - ⏳ 实现 scripts/preprocess.py (预处理脚本)
  - ⏳ 添加 dvc.yaml 第二阶段: preprocess
  - ⏳ 测试: `dvc repro preprocess`
- **Day 5**:
  - ⏳ 实现 models/feature_engineering.py
  - ⏳ 实现 scripts/feature_engineering.py
  - ⏳ 添加 dvc.yaml 第三阶段: feature_engineering
  - ⏳ 测试完整流水线: `dvc repro`
- **交付物**: 3阶段流水线可运行 (验证 → 预处理 → 特征工程)

### 第3周: 模型训练流水线
- **Day 1**:
  - ⏳ 实现 scripts/split_data.py (数据切分)
  - ⏳ 添加 split_data 阶段到 dvc.yaml
- **Day 2-3**:
  - ⏳ 实现 models/prediction.py (转化预测模型)
  - ⏳ 实现 scripts/train_conversion.py
  - ⏳ 添加 train_conversion_model 阶段
  - ⏳ 调优达到 AUC ≥ 0.85 目标
- **Day 4**:
  - ⏳ 实现 models/segmentation.py (客户分群)
  - ⏳ 实现 scripts/train_segmentation.py
  - ⏳ 添加 train_segmentation_model 阶段
- **Day 5**:
  - ⏳ 实现 models/customer_analyzer.py (高价值评分)
  - ⏳ 实现 scripts/train_high_value.py
  - ⏳ 实现 scripts/evaluate.py (综合评估)
  - ⏳ 添加最后两个阶段
- **交付物**: 完整的 7阶段流水线, 所有模型训练完成

### 第4周: 优化与生产准备
- **Day 1-2**:
  - ⏳ 配置云端远程存储 (可选, 如需团队协作)
  - ⏳ 测试团队协作工作流 (git pull + dvc pull)
  - ⏳ 编写团队使用文档
- **Day 3-4**:
  - ⏳ 运行多组实验 (使用 dvc exp run)
  - ⏳ 调优超参数 (修改 params.yaml)
  - ⏳ 比较实验结果 (dvc exp show)
  - ⏳ 应用最佳实验 (dvc exp apply)
- **Day 5**:
  - ⏳ 标记生产版本 (git tag)
  - ⏳ 创建部署文档
  - ⏳ 准备 Flask 可视化大屏集成
- **交付物**: 生产就绪的 MLOps 系统, 达到 AUC ≥ 0.85

### 第5-6周: 生产部署与监控 (可选)
- **第5周**:
  - Flask 大屏系统开发
  - 集成训练好的模型
  - 实时数据更新机制
- **第6周**:
  - 监控与预警系统
  - A/B 测试框架
  - 持续优化流程
- **交付物**: 完整的精准营销系统上线

### 快速启动指南 (第1天可完成)

```bash
# 1. 进入项目目录
cd "c:\Users\hy120\Downloads\zhihullm\CASE-customer group"

# 2. 安装 DVC
pip install dvc

# 3. 初始化 DVC
dvc init

# 4. 配置本地存储 (开发测试)
dvc remote add -d storage D:\dvc-storage\customer-project

# 5. 追踪数据
dvc add customer_base.csv
dvc add customer_behavior_assets.csv

# 6. 提交到 Git
git add .dvc .dvcignore *.dvc .gitignore
git commit -m "Initialize DVC and track data files"

# 7. 推送数据到存储
dvc push

# ✅ 完成! DVC 基础设施已就绪
```

---

## 10. 关键成功因素与建议

### 10.1 关键成功因素

1. **从简单开始**：先建立基础 DVC 设置，逐步添加流水线阶段
2. **团队认同**：确保所有团队成员理解 DVC 工作流
3. **一致的命名**：遵循文件、阶段、标签的命名规范
4. **定期备份**：配置备份远程存储
5. **文档维护**：保持 README 和工作流文档更新

### 10.2 最佳实践

**DVC 使用**：
- 经常提交，选择性推送（节省带宽）
- 使用描述性的阶段名称
- 利用 DVC 缓存共享
- 标记重要里程碑

**流水线设计**：
- 模块化阶段（一个阶段做一件事）
- 参数化所有内容
- 明确声明依赖关系
- 输出有意义的产物

**团队协作**：
- 使用描述性的提交消息
- 在 Markdown 文件中记录实验
- 在团队会议中分享指标和发现
- 代码审查（审查代码和参数变更）

### 10.3 即时行动步骤 (现在就可以开始!)

**第1步: 安装 DVC** ⚡
```bash
cd "c:\Users\hy120\Downloads\zhihullm\CASE-customer group"
pip install dvc
```

**第2步: 初始化 DVC** ⚡
```bash
dvc init
git status  # 查看 DVC 生成的文件
```

**第3步: 配置远程存储** ⚡
```bash
# 开发测试: 使用本地 D 盘
dvc remote add -d storage D:\dvc-storage\customer-project

# 或团队协作: 使用云存储
# dvc remote add -d storage s3://your-bucket/customer-segmentation
```

**第4步: 追踪现有数据** ⚡
```bash
dvc add customer_base.csv
dvc add customer_behavior_assets.csv
```

**第5步: 提交到 Git** ⚡
```bash
git add .dvc .dvcignore *.dvc .gitignore
git commit -m "chore: Initialize DVC and track data files"
dvc push
```

**后续步骤预览**:
- 第6步: 创建目录结构 (data/, models/, scripts/, outputs/)
- 第7步: 创建配置文件 (params.yaml, requirements.txt, config.py)
- 第8步: 移动数据文件到标准位置
- 第9步: 开始实现第一个流水线阶段

### 10.4 预期收益

- **可重现性**：任何团队成员都可以重现任何实验
- **协作**：轻松共享数据、模型和实验
- **实验追踪**：系统地比较数百个实验
- **版本控制**：在数据和模型版本中时间旅行
- **可扩展性**：流水线从笔记本到集群无缝扩展

---

## 11. 核心文件清单

实施 DVC 时最关键的5个文件：

1. **dvc.yaml** - 核心流水线定义，编排所有数据处理和模型训练阶段
2. **params.yaml** - 集中式参数配置，实现轻松实验和超参数调优
3. **scripts/preprocess.py** - 第一个关键流水线阶段，清洗和合并原始数据
4. **scripts/feature_engineering.py** - 核心特征创建逻辑，生成 customer_features.csv
5. **scripts/train_conversion.py** - 主要模型训练脚本，用于客户转化预测（AUC ≥ 0.85）

---

## 附录：快速参考

### DVC 常用命令

```bash
# 初始化
dvc init

# 追踪数据
dvc add data.csv

# 配置远程存储
dvc remote add -d myremote s3://bucket/path

# 推送/拉取数据
dvc push
dvc pull

# 运行流水线
dvc repro

# 查看流水线
dvc dag

# 实验管理
dvc exp run --name exp-001
dvc exp show
dvc exp diff

# 比较指标
dvc metrics show
dvc metrics diff

# 比较参数
dvc params diff
```

### Git + DVC 协作流程

```bash
# 获取最新代码和数据
git pull
dvc pull

# 修改参数并运行实验
vim params.yaml
dvc repro

# 提交变更
dvc push
git add dvc.lock params.yaml
git commit -m "exp: improve model performance"
git push
```
