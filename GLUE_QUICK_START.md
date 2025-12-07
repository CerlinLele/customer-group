# AWS Glue Pipeline 快速执行参考

## 快速开始（推荐）

### 1️⃣ 部署基础设施

```bash
cd infra
terraform init
terraform apply
```

### 2️⃣ 运行原始数据爬虫

```bash
# 运行爬虫来扫描 CSV 文件
aws glue start-crawler --name "case-dev-raw-customer-base-crawler"
aws glue start-crawler --name "case-dev-raw-customer-behavior-crawler"

# 等待爬虫完成（监控状态）
watch -n 5 'aws glue get-crawler --name case-dev-raw-customer-base-crawler | grep State'
```

**预期时间**: 1-2 分钟

### 3️⃣ 验证原始表

```bash
# 列出原始表
aws glue get-tables --database-name customer_raw_db

# 查询验证
aws athena start-query-execution \
  --query-string "SELECT COUNT(*) FROM customer_raw_db.raw_customer_base" \
  --query-execution-context Database=customer_raw_db \
  --result-configuration OutputLocation=s3://your-bucket/athena-results/
```

### 4️⃣ 运行数据清洗作业

```bash
# 启动作业
aws glue start-job-run --job-name customer-data-cleansing

# 获取作业 ID
JOB_RUN_ID=$(aws glue start-job-run --job-name customer-data-cleansing --query 'JobRunId' --output text)
echo "Job Run ID: $JOB_RUN_ID"

# 监控作业进度
aws glue get-job-run --job-name customer-data-cleansing --run-id $JOB_RUN_ID

# 查看实时日志
aws logs tail "/aws-glue/jobs/customer-data-cleansing" --follow
```

**预期时间**: 5-15 分钟

### 5️⃣ 运行清洗后数据爬虫

```bash
# 等待上一步作业完成后，运行爬虫
aws glue start-crawler --name "case-dev-cleaned-customer-base-crawler"
aws glue start-crawler --name "case-dev-cleaned-customer-behavior-crawler"

# 监控状态
watch -n 5 'aws glue get-crawler --name case-dev-cleaned-customer-base-crawler | grep State'
```

**预期时间**: 1-2 分钟

### 6️⃣ 验证清洗表

```bash
# 列出清洗表
aws glue get-tables --database-name customer_cleaned_db

# 查询验证
SELECT * FROM customer_cleaned_db.cleaned_customer_base LIMIT 5;
SELECT COUNT(*) FROM customer_cleaned_db.cleaned_customer_behavior;
```

### 7️⃣ 运行特征工程作业

```bash
# 启动作业
aws glue start-job-run --job-name customer-feature-engineering

# 监控和查看日志
JOB_RUN_ID=$(aws glue start-job-run --job-name customer-feature-engineering --query 'JobRunId' --output text)
aws logs tail "/aws-glue/jobs/customer-feature-engineering" --follow
```

**预期时间**: 10-20 分钟

---

## 完整命令脚本

### 一键部署（如果所有先决条件已满足）

```bash
#!/bin/bash
set -e

echo "=========================================="
echo "AWS Glue Pipeline - 完整自动化执行"
echo "=========================================="

# 配置变量
PROJECT_NAME="case"
ENVIRONMENT="dev"
REGION="us-east-1"

# Step 1: 部署 Terraform
echo "Step 1: 部署 Terraform 基础设施..."
cd infra
terraform apply -auto-approve
cd ..

# Step 2: 运行原始数据爬虫
echo "Step 2: 运行原始数据爬虫..."
aws glue start-crawler --name "$PROJECT_NAME-$ENVIRONMENT-raw-customer-base-crawler" --region $REGION
aws glue start-crawler --name "$PROJECT_NAME-$ENVIRONMENT-raw-customer-behavior-crawler" --region $REGION

# 等待爬虫完成
echo "等待爬虫完成..."
while true; do
  CRAWLER_STATE=$(aws glue get-crawler --name "$PROJECT_NAME-$ENVIRONMENT-raw-customer-base-crawler" --region $REGION --query 'Crawler.State' --output text)
  if [ "$CRAWLER_STATE" = "READY" ]; then
    echo "爬虫已完成"
    break
  fi
  echo "爬虫正在运行... (状态: $CRAWLER_STATE)"
  sleep 10
done

# Step 3: 运行数据清洗作业
echo "Step 3: 运行数据清洗作业..."
JOB_RUN_ID=$(aws glue start-job-run --job-name customer-data-cleansing --region $REGION --query 'JobRunId' --output text)
echo "作业运行 ID: $JOB_RUN_ID"

# 等待作业完成
echo "等待数据清洗作业完成..."
while true; do
  JOB_STATE=$(aws glue get-job-run --job-name customer-data-cleansing --run-id $JOB_RUN_ID --region $REGION --query 'JobRun.JobRunState' --output text)
  if [ "$JOB_STATE" = "SUCCEEDED" ]; then
    echo "数据清洗作业已完成"
    break
  elif [ "$JOB_STATE" = "FAILED" ]; then
    echo "数据清洗作业失败！"
    exit 1
  fi
  echo "作业状态: $JOB_STATE，等待中..."
  sleep 30
done

# Step 4: 运行清洗后数据爬虫
echo "Step 4: 运行清洗后数据爬虫..."
aws glue start-crawler --name "$PROJECT_NAME-$ENVIRONMENT-cleaned-customer-base-crawler" --region $REGION
aws glue start-crawler --name "$PROJECT_NAME-$ENVIRONMENT-cleaned-customer-behavior-crawler" --region $REGION

# 等待爬虫完成
echo "等待清洗爬虫完成..."
while true; do
  CRAWLER_STATE=$(aws glue get-crawler --name "$PROJECT_NAME-$ENVIRONMENT-cleaned-customer-base-crawler" --region $REGION --query 'Crawler.State' --output text)
  if [ "$CRAWLER_STATE" = "READY" ]; then
    echo "清洗爬虫已完成"
    break
  fi
  echo "爬虫正在运行... (状态: $CRAWLER_STATE)"
  sleep 10
done

# Step 5: 运行特征工程作业
echo "Step 5: 运行特征工程作业..."
JOB_RUN_ID=$(aws glue start-job-run --job-name customer-feature-engineering --region $REGION --query 'JobRunId' --output text)
echo "作业运行 ID: $JOB_RUN_ID"

echo ""
echo "=========================================="
echo "✅ 所有任务已启动！"
echo "=========================================="
echo "原始爬虫: ✓"
echo "数据清洗作业: ✓"
echo "清洗爬虫: ✓"
echo "特征工程作业: 运行中..."
echo ""
echo "要监控特征工程作业，运行："
echo "aws logs tail '/aws-glue/jobs/customer-feature-engineering' --follow"
```

---

## 故障排查快速检查表

### ❌ 爬虫显示"FAILED"

```bash
# 查看爬虫日志
aws logs tail /aws-glue/crawlers/PROJECT-ENV-crawler-name --follow

# 验证 S3 路径
aws s3 ls s3://your-bucket/raw/
aws s3 ls s3://your-bucket/cleaned/customer_base/

# 检查 IAM 权限
aws iam get-role-policy --role-name PROJECT-ENV-GlueCustomerDataRole --policy-name GlueExecutionPolicy
```

### ❌ Glue Job 失败：EntityNotFoundException

```bash
# 检查是否有相应的表
aws glue get-table --database-name customer_raw_db --name raw_customer_base

# 如果表不存在，运行爬虫
aws glue start-crawler --name case-dev-raw-customer-base-crawler

# 等待爬虫完成
aws glue wait crawler-ready --name case-dev-raw-customer-base-crawler
```

### ❌ Glue Job 显示"FAILED"

```bash
# 获取作业运行 ID
JOB_RUN_ID=$(aws glue get-job-runs --job-name customer-data-cleansing --max-items 1 --query 'JobRuns[0].Id' --output text)

# 查看错误日志
aws logs tail "/aws-glue/jobs/customer-data-cleansing" --follow

# 获取详细的作业运行信息
aws glue get-job-run --job-name customer-data-cleansing --run-id $JOB_RUN_ID
```

---

## 相关资源

- 📖 [完整执行指南](GLUE_PIPELINE_EXECUTION_GUIDE.md)
- 📁 [Terraform 配置](infra/modules/glue/crawlers.tf)
- 🔧 [Glue 作业配置](glue_scripts/config/glue_jobs_config.json)
- 📊 [数据清洗脚本](glue_scripts/1_data_cleansing.py)
- 🎯 [特征工程脚本](glue_scripts/2_feature_engineering.py)

---

## 成本估算

| 组件 | 估计成本 | 说明 |
|------|--------|------|
| Glue Crawlers | $0.44/爬虫小时 | 每个爬虫通常运行 1-2 分钟 |
| Glue Jobs (G.2X) | $0.44/DPU小时 | 清洗作业: 5-15 分钟; 特征作业: 10-20 分钟 |
| S3 存储 | $0.023/GB/月 | 取决于原始和处理数据大小 |
| Athena 查询 | $5 per TB | 按扫描数据计费 |
| 总计 (每月) | ~$20-50 | 基于每天运行一次的假设 |

---

## 技巧和最佳实践

### 💡 节省成本

1. **使用 On-Demand Crawlers**: 手动触发而不是计划触发
2. **优化 Job 资源**: 根据数据大小调整 Worker 数量
3. **使用 Job Bookmarks**: 只处理新增数据

### ⚡ 加快执行

1. **并行运行爬虫**: 可以同时运行多个爬虫
2. **调整 Worker 配置**: 增加 Worker 数量加速处理
3. **使用 Parquet 格式**: 比 CSV 快 10 倍以上

### 🔒 安全最佳实践

1. **使用 Glue Connection**: 为数据库连接加密
2. **启用 S3 加密**: 使用 KMS 加密敏感数据
3. **限制 IAM 权限**: 遵循最小权限原则
4. **启用 CloudTrail**: 审计所有 API 调用

