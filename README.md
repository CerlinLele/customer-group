# 客户数据处理完整方案 - README

## 📚 项目概述

本项目提供了一套完整的**客户数据分析和处理解决方案**，包括：

1. **📊 EDA分析** - 2000+ 行客户数据的深度分析
2. **☁️ AWS Glue实现** - 云端自动化数据处理管道
3. **🎯 商业洞察** - 基于数据驱动的客户分层和营销策略

---

## 📁 项目结构

```
CASE-customer group/
├── 📋 EDA分析部分
│   ├── customer_base.csv                        # 源数据：客户基本信息
│   ├── customer_behavior_assets.csv             # 源数据：客户行为资产
│   ├── EDA_Analysis.ipynb                       # 📊 交互式EDA分析
│   └── EDA_Summary_Report.md                    # 📄 EDA详细报告
│
├── ☁️ AWS Glue部分
│   ├── AWS_Glue_Implementation_Plan.md          # 🏗️ Glue实现方案设计
│   ├── AWS_Glue_QuickStart_Guide.md             # 🚀 快速开始指南
│   │
│   └── glue_scripts/
│       ├── 1_data_cleansing.py                  # ✨ 数据清洗脚本
│       ├── 2_feature_engineering.py             # 🧠 特征工程脚本
│       ├── 3_customer_segmentation.py           # 🎯 客户分群脚本 (待实现)
│       ├── 4_marketing_recommendation.py        # 📢 营销推荐脚本 (待实现)
│       ├── 5_data_quality_monitoring.py         # 🔍 质量监控脚本 (待实现)
│       │
│       ├── config/
│       │   ├── glue_jobs_config.json            # ⚙️ Glue任务配置
│       │   └── database_config.json             # 📚 数据库配置
│       │
│       ├── utils/
│       │   ├── data_validator.py                # 🔎 数据验证工具
│       │   ├── feature_builder.py               # 🏗️ 特征构建工具
│       │   └── logger.py                        # 📝 日志工具
│       │
│       ├── deploy.sh                            # 🚀 自动部署脚本
│       └── README.md                            # 📖 Glue脚本说明
│
└── README.md                                    # 本文件
```

---

## 🎯 快速导航

### 对于数据分析师
👉 开始于: [EDA_Summary_Report.md](EDA_Summary_Report.md)
- 查看关键数据洞察
- 了解客户特征分布
- 发现商业机会

### 对于数据工程师
👉 开始于: [AWS_Glue_QuickStart_Guide.md](AWS_Glue_QuickStart_Guide.md)
- 5分钟快速部署
- 详细的逐步教程
- 故障排查指南

### 对于架构师
👉 开始于: [AWS_Glue_Implementation_Plan.md](AWS_Glue_Implementation_Plan.md)
- 完整的架构设计
- 成本估算
- 扩展方案

### 对于基础设施工程师
👉 **快速开始**: [Terraform快速参考卡](TERRAFORM_QUICKREF.md)
- 一键部署命令
- 常用命令速查表
- 常见错误解决

👉 **完整指南**: [Terraform部署详细指南](docs/feature-engineering/TERRAFORM_DEPLOYMENT_GUIDE.md)
- 完整的前置条件和部署流程
- 资源详细配置说明
- 高级管理和优化

👉 **变更总结**: [本次更新说明](UPDATE_SUMMARY.md)
- 所有更改内容总结
- 技术细节说明
- 改进优势对比

---

## 🚀 快速开始（3步）

### Step 1: 查看EDA结果（5分钟）

```bash
# 打开Jupyter Notebook查看可视化分析
jupyter notebook EDA_Analysis.ipynb

# 或者直接阅读报告
cat EDA_Summary_Report.md
```

### Step 2: 使用Terraform部署AWS基础设施（5分钟）

#### 前提条件

```bash
# 1. 安装Terraform (>=1.0)
terraform version

# 2. 配置AWS CLI凭证
aws configure
# 输入: AWS Access Key ID, Secret Access Key, Region, Output format
```

#### 部署步骤

```bash
# 1. 进入Terraform配置目录
cd infra

# 2. 初始化Terraform工作目录（下载提供商插件）
terraform init

# 3. 查看部署计划（检查将要创建的资源）
terraform plan

# 4. 应用配置（创建S3 bucket和Glue管道）
terraform apply
# 输入: yes 确认部署

# 5. 查看输出（获取创建的资源信息）
terraform output
```

#### 部署细节说明

**自动创建的资源：**

- **S3 Bucket**: 用于存储客户数据
  - 启用版本控制
  - 启用加密
  - 阻止公共访问
  - 自动上传源数据文件（customer_base.csv 和 customer_behavior_assets.csv）

- **S3 文件夹结构**:
  ```
  s3://your-bucket/
  ├── raw/                    # 原始数据
  │   ├── customer_base.csv
  │   └── customer_behavior_assets.csv
  ├── cleaned/                # 清洗后数据（Glue输出）
  ├── features/               # 特征数据（Glue输出）
  ├── scripts/                # Glue脚本
  └── temp/                   # 临时文件
  ```

- **Glue Pipeline**: 包含数据清洗和特征工程jobs
  - 自动创建IAM角色
  - 配置CloudWatch日志
  - 设置Job书签

#### Terraform 变量配置

编辑 `infra/terraform.tfvars` 配置部署参数：

```hcl
environment  = "dev"              # 开发环境
project_name = "customer-group"   # 项目名称
aws_region   = "us-east-1"        # AWS区域

# S3配置
s3_block_public_access = true     # 阻止公共访问
s3_enable_encryption   = true     # 启用加密
```

### Step 3: 运行Glue处理管道（自动执行）

Terraform部署完成后，CSV文件已自动上传到S3的 `raw/` 文件夹。接下来可以：

```bash
# 1. 启动Glue Crawler（自动发现数据架构）
aws glue start-crawler --name customer-data-crawler

# 2. 查看爬虫进度
aws glue get-crawler --name customer-data-crawler

# 3. 启动数据清洗Job
aws glue start-job-run \
  --job-name customer-data-cleansing \
  --arguments '{"--INPUT_DATABASE":"customer_raw_db","--INPUT_TABLE_BASE":"raw_customer_base","--INPUT_TABLE_BEHAVIOR":"raw_customer_behavior_assets"}'

# 4. 查看Job执行结果
aws s3 ls s3://your-bucket/cleaned/
```

#### 清理资源

```bash
# 进入infra目录
cd infra

# 删除所有Terraform创建的资源
terraform destroy
# 输入: yes 确认删除
```

---

## 📊 EDA关键发现

### 🎯 数据概览
- **客户数量**: ~1000+
- **行为记录**: ~3000+
- **时间跨度**: 12个月 (2024-07 ~ 2025-06)
- **数据质量**: 优秀 (缺失值<5%)

### 💰 经济特征
| 指标 | 数值 |
|-----|------|
| 平均月收入 | ¥30-40k |
| 平均总资产 | ¥300-500k |
| 高净值客户(100万+) | 30% |

### 📈 业务机会
| 领域 | 现状 | 机会 |
|-----|------|------|
| 存款产品 | 95% 持有率 | 成熟市场 |
| 理财产品 | 25% 持有率 | ↑ 升级70% |
| 基金产品 | 15% 持有率 | ↑ 升级85% |
| 保险产品 | 5% 持有率 | ↑ 升级95% 🚀 |

### ⚠️ 关键问题
1. 接触成功率仅 35% → 需优化营销策略
2. 75% 客户无投资记录 → 巨大的投资市场机会
3. 15% App 未登录 → 需要拉活营销

---

## ☁️ AWS Glue 架构

### 处理流程

```
原始数据 (CSV)
    ↓
S3 Raw Layer
    ↓
Glue Crawler (元数据发现)
    ↓
Glue Catalog
    ↓
Job 1: 数据清洗
    ↓
S3 Cleaned Layer
    ↓
Job 2: 特征工程
    ↓
S3 Feature Layer
    ↓
Job 3: 客户分群
    ↓
Job 4: 营销推荐
    ↓
最终输出 (JSON/Parquet)
    ↓
BI工具 / 营销系统
```

### 关键特性

✅ **完全自动化** - 支持日程调度
✅ **可扩展** - 支持PB级数据
✅ **成本优化** - 按需计费，月成本<$50
✅ **监控完善** - CloudWatch告警 + 数据质量检查
✅ **易于部署** - 一键脚本部署

---

## 📖 使用说明

### 对于EDA分析

```bash
# 1. 打开Jupyter Notebook
jupyter notebook EDA_Analysis.ipynb

# 2. 运行所有单元格 (Kernel → Restart & Run All)

# 3. 查看各类可视化和统计
#    - 客户特征分布
#    - 资产和产品分析
#    - 行为指标分析
#    - 相关性热力图
```

### 对于Glue部署

推荐使用Terraform进行部署，可以自动化完整的基础设施创建和数据上传：

```bash
# 1. 使用Terraform部署（推荐）
cd infra
terraform init
terraform plan
terraform apply

# 2. 启动Glue处理（Terraform部署后）
aws glue start-crawler --name customer-data-crawler

# 3. 查看结果
aws s3 ls s3://bucket-name/cleaned/
```

或者使用传统脚本部署：

```bash
# 1. 阅读快速开始指南
cat AWS_Glue_QuickStart_Guide.md

# 2. 手动部署
cd glue_scripts
./deploy.sh

# 3. 手动上传源数据
aws s3 cp customer_base.csv s3://bucket/raw/
aws s3 cp customer_behavior_assets.csv s3://bucket/raw/
```

---

## 🔧 配置参数

### Glue Jobs 参数

在 `glue_scripts/config/glue_jobs_config.json` 中修改：

```json
{
  "job_name": "customer-data-cleansing",
  "max_capacity": 2,              // DPU数量
  "worker_type": "G.1X",          // Worker类型
  "timeout": 30,                  // 超时时间(分钟)
  "max_retries": 1                // 最大重试次数
}
```

### 成本参数

| 参数 | 默认值 | 说明 |
|-----|-------|------|
| DPU数量 | 2 | 降低提高速度，增加降低成本 |
| Worker类型 | G.1X | G.2X更快但成本2倍 |
| 并发数 | 5 | 同时运行的Job数 |

**月成本估算**: ~$30-50 (取决于数据量和处理频率)

---

## 📊 输出数据说明

### 清洗后的数据 (Cleaned Layer)

位置: `s3://bucket/cleaned/`

**customer_base**
- 数据类型标准化
- 异常值处理
- 去重

**customer_behavior**
- 时间戳标准化
- 资产数据验证
- 行为指标正常化

### 特征层数据 (Feature Layer)

位置: `s3://bucket/features/`

**customer_features** 包含:
- RFM评分 (Recency, Frequency, Monetary)
- 客户价值评分 (0-100)
- 活跃类型分类
- 交叉销售机会评分
- 流失风险评分

### 分群层数据 (Segment Layer)

位置: `s3://bucket/segments/`

**customer_segments** 包含:
- 细分群体ID (S001-S012)
- 群体名称和特征
- 群体规模和价值

### 推荐层数据 (Recommendation Layer)

位置: `s3://bucket/recommendations/`

**marketing_targets** 包含:
- 推荐的产品
- 推荐优先级
- 预期客户价值
- 最佳接触时机

---

## 🔍 监控和告警

### CloudWatch指标

```
指标名称                    | 阈值 | 说明
---------------------------|------|--------
glue_job_failure            | >=1  | Job执行失败
contact_result_missing_rate | >5%  | 缺失值过高
customer_behavior_rows      | <2500| 行数异常低
```

### 启用告警

```bash
# 创建SNS主题用于告警通知
aws sns create-topic --name glue-alerts

# 订阅邮件
aws sns subscribe \
  --topic-arn arn:aws:sns:region:account:glue-alerts \
  --protocol email \
  --notification-endpoint your-email@company.com
```

---

## 🎓 学习资源

### AWS Glue相关
- [官方文档](https://docs.aws.amazon.com/glue/)
- [Glue最佳实践](https://docs.aws.amazon.com/glue/latest/dg/best-practices.html)
- [PySpark API](https://spark.apache.org/docs/latest/api/python/)

### 数据处理相关
- [Spark性能优化](https://spark.apache.org/docs/latest/tuning.html)
- [数据质量最佳实践](https://docs.aws.amazon.com/glue/latest/dg/managing-connections.html)

### 商业分析相关
- [RFM分析详解](https://en.wikipedia.org/wiki/RFM_(customer_value))
- [客户分群方法论](https://en.wikipedia.org/wiki/Market_segmentation)

---

## 🚀 后续扩展

### Phase 1 (1-2周) ✅ 已完成
- [x] EDA分析
- [x] Glue架构设计
- [x] 数据清洗脚本
- [x] 特征工程脚本

### Phase 2 (2-4周) 待实现
- [ ] 客户分群脚本 (3_customer_segmentation.py)
- [ ] 营销推荐脚本 (4_marketing_recommendation.py)
- [ ] 质量监控脚本 (5_data_quality_monitoring.py)
- [ ] BI工具集成 (Tableau/QuickSight)

### Phase 3 (1-3月) 高级功能
- [ ] 机器学习模型 (SageMaker集成)
- [ ] 实时处理 (Kinesis流处理)
- [ ] 客户流失预警
- [ ] CLV (客户终生价值)预测

---

## ❓ 常见问题

### Q1: 数据如何从本地迁移到AWS?

```bash
# 方式1: AWS CLI
aws s3 cp customer_base.csv s3://bucket/raw/

# 方式2: AWS DataSync (适合大数据量)
# 访问AWS Console → DataSync → 创建任务

# 方式3: AWS数据迁移服务 (DMS)
# 用于数据库迁移
```

### Q2: 如何修改Glue脚本?

```bash
# 1. 编辑本地脚本
vim glue_scripts/1_data_cleansing.py

# 2. 上传到S3
aws s3 cp glue_scripts/1_data_cleansing.py s3://bucket/scripts/

# 3. 更新Glue Job指向新脚本位置
aws glue update-job \
  --name customer-data-cleansing \
  --command "Name=glueetl,ScriptLocation=s3://bucket/scripts/1_data_cleansing.py"
```

### Q3: 如何处理Glue Job超时?

```bash
# 1. 增加超时时间
aws glue update-job \
  --name customer-data-cleansing \
  --timeout 60  # 改为60分钟

# 2. 增加DPU
aws glue update-job \
  --max-capacity 4  # 从2增到4

# 3. 优化脚本性能
# 使用分区、缓存等Spark优化技术
```

### Q4: 成本太高，如何优化?

```bash
# 1. 降低DPU数量
--max-capacity 1

# 2. 使用G.2X worker (某些情况下)
--worker-type G.2X --number-of-workers 1

# 3. 设置S3生命周期策略删除旧数据
aws s3api put-bucket-lifecycle-configuration ...

# 4. 减少Job运行频率
# 改为每周运行而不是每天
```

---

## 📞 支持和反馈

### 遇到问题?

1. 查看 [AWS_Glue_QuickStart_Guide.md](AWS_Glue_QuickStart_Guide.md) 中的常见问题
2. 检查CloudWatch Logs中的错误信息
3. 参考AWS Glue官方文档

### 想要改进?

- 提交Issue或Pull Request
- 提供反馈和建议

---

## 📄 许可证

MIT License - 自由使用和修改

---

## 🙏 致谢

感谢使用本项目！如有问题，欢迎提问。

---

## 📝 更新日志

### v1.0.0 (2025-12-01)
- ✅ EDA分析完成
- ✅ Glue实现方案设计完成
- ✅ 数据清洗脚本完成
- ✅ 特征工程脚本完成
- ✅ 快速开始指南完成

### v1.1.0 (2025-12-06) ✅ 已完成
- ✅ Terraform自动化部署
- ✅ S3自动上传CSV数据
- ✅ 完整的部署文档
- ✅ 快速参考卡片
- 🔄 客户分群脚本
- 🔄 营销推荐脚本
- 🔄 质量监控脚本

---

**项目更新时间**: 2025-12-06
**维护者**: Data Engineering Team
**联系方式**: data-team@company.com

