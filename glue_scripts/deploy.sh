#!/bin/bash

# AWS Glue 部署脚本
# 用途: 自动创建和配置所有Glue组件
# 前置条件: AWS CLI已安装和配置, 拥有必要的IAM权限

set -e

# ============================================================================
# 配置变量
# ============================================================================

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
S3_BUCKET="your-customer-data-bucket"
ROLE_NAME="GlueCustomerDataRole"
GLUE_SCRIPTS_PATH="s3://${S3_BUCKET}/scripts"
CONFIG_FILE="glue_scripts_config.json"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================================================
# 辅助函数
# ============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================================================
# Step 1: 创建IAM角色
# ============================================================================

create_iam_role() {
    log_info "Step 1: 创建IAM角色 ($ROLE_NAME)..."

    # 检查角色是否已存在
    if aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null; then
        log_warn "IAM角色 $ROLE_NAME 已存在，跳过创建"
    else
        # 创建信任策略文档
        cat > /tmp/trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

        aws iam create-role \
            --role-name "$ROLE_NAME" \
            --assume-role-policy-document file:///tmp/trust-policy.json \
            --region "$AWS_REGION"

        log_info "IAM角色 $ROLE_NAME 创建成功"

        # 附加必要的策略
        aws iam attach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole \
            --region "$AWS_REGION"

        log_info "已附加 AWSGlueServiceRole 策略"

        # 附加自定义S3策略
        cat > /tmp/s3-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3Access",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${S3_BUCKET}/*",
        "arn:aws:s3:::${S3_BUCKET}"
      ]
    }
  ]
}
EOF

        aws iam put-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-name S3AccessPolicy \
            --policy-document file:///tmp/s3-policy.json

        log_info "S3访问策略已附加"

        # 等待角色生效
        sleep 10
    fi
}

# ============================================================================
# Step 2: 创建S3桶和目录结构
# ============================================================================

create_s3_structure() {
    log_info "Step 2: 创建S3桶和目录结构..."

    # 检查桶是否存在
    if aws s3 ls "s3://${S3_BUCKET}" 2>/dev/null; then
        log_warn "S3桶 $S3_BUCKET 已存在"
    else
        aws s3 mb "s3://${S3_BUCKET}" --region "$AWS_REGION"
        log_info "S3桶 $S3_BUCKET 创建成功"
    fi

    # 创建目录结构
    aws s3api put-object --bucket "$S3_BUCKET" --key "raw/" \
        --region "$AWS_REGION" 2>/dev/null || true
    aws s3api put-object --bucket "$S3_BUCKET" --key "scripts/" \
        --region "$AWS_REGION" 2>/dev/null || true
    aws s3api put-object --bucket "$S3_BUCKET" --key "cleaned/" \
        --region "$AWS_REGION" 2>/dev/null || true
    aws s3api put-object --bucket "$S3_BUCKET" --key "features/" \
        --region "$AWS_REGION" 2>/dev/null || true
    aws s3api put-object --bucket "$S3_BUCKET" --key "segments/" \
        --region "$AWS_REGION" 2>/dev/null || true
    aws s3api put-object --bucket "$S3_BUCKET" --key "recommendations/" \
        --region "$AWS_REGION" 2>/dev/null || true

    log_info "S3目录结构创建成功"
}

# ============================================================================
# Step 3: 上传Glue脚本
# ============================================================================

upload_glue_scripts() {
    log_info "Step 3: 上传Glue脚本到S3..."

    # 上传数据清洗脚本
    aws s3 cp "glue_scripts/1_data_cleansing.py" \
        "${GLUE_SCRIPTS_PATH}/1_data_cleansing.py" \
        --region "$AWS_REGION"

    # 上传特征工程脚本
    aws s3 cp "glue_scripts/2_feature_engineering.py" \
        "${GLUE_SCRIPTS_PATH}/2_feature_engineering.py" \
        --region "$AWS_REGION"

    log_info "Glue脚本上传成功"
}

# ============================================================================
# Step 4: 创建Glue数据库
# ============================================================================

create_glue_databases() {
    log_info "Step 4: 创建Glue数据库..."

    databases=("customer_raw_db" "customer_cleaned_db" "customer_feature_db" "customer_segment_db")

    for db in "${databases[@]}"; do
        # 检查数据库是否存在
        if aws glue get-database --name "$db" --region "$AWS_REGION" 2>/dev/null; then
            log_warn "数据库 $db 已存在"
        else
            aws glue create-database \
                --database-input "{\"Name\": \"$db\", \"Description\": \"Customer data database\"}" \
                --region "$AWS_REGION"
            log_info "数据库 $db 创建成功"
        fi
    done
}

# ============================================================================
# Step 5: 创建Glue Crawler
# ============================================================================

create_glue_crawler() {
    log_info "Step 5: 创建Glue Crawler..."

    ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"

    # 创建原始数据crawler
    aws glue create-crawler \
        --name customer-data-crawler \
        --role "$ROLE_ARN" \
        --database-name customer_raw_db \
        --targets "S3Targets=[{Path=s3://${S3_BUCKET}/raw/}]" \
        --schedule-expression "cron(0 0 * * ? *)" \
        --table-prefix raw_ \
        --region "$AWS_REGION" 2>/dev/null || \
    log_warn "Crawler customer-data-crawler 可能已存在"

    log_info "Glue Crawler 创建成功"
}

# ============================================================================
# Step 6: 创建Glue Jobs
# ============================================================================

create_glue_jobs() {
    log_info "Step 6: 创建Glue Jobs..."

    ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"

    # Job 1: 数据清洗
    aws glue create-job \
        --name customer-data-cleansing \
        --role "$ROLE_ARN" \
        --command "Name=glueetl,ScriptLocation=${GLUE_SCRIPTS_PATH}/1_data_cleansing.py" \
        --max-capacity 2 \
        --glue-version 4.0 \
        --timeout 30 \
        --max-retries 1 \
        --region "$AWS_REGION" 2>/dev/null || \
    log_warn "Job customer-data-cleansing 可能已存在"

    # Job 2: 特征工程
    aws glue create-job \
        --name customer-feature-engineering \
        --role "$ROLE_ARN" \
        --command "Name=glueetl,ScriptLocation=${GLUE_SCRIPTS_PATH}/2_feature_engineering.py" \
        --max-capacity 2 \
        --glue-version 4.0 \
        --timeout 30 \
        --max-retries 1 \
        --region "$AWS_REGION" 2>/dev/null || \
    log_warn "Job customer-feature-engineering 可能已存在"

    log_info "Glue Jobs 创建成功"
}

# ============================================================================
# Step 7: 创建Glue Triggers (可选)
# ============================================================================

create_glue_triggers() {
    log_info "Step 7: 创建Glue Triggers..."

    # 创建trigger: 清洗job完成后启动特征工程job
    aws glue create-trigger \
        --name feature-engineering-trigger \
        --type CONDITIONAL \
        --actions "[{JobName=customer-feature-engineering}]" \
        --predicate "{Logical=ANY,Conditions=[{LogicalOperator=EQUALS,JobName=customer-data-cleansing,State=SUCCEEDED}]}" \
        --region "$AWS_REGION" 2>/dev/null || \
    log_warn "Trigger feature-engineering-trigger 可能已存在"

    log_info "Glue Triggers 创建成功"
}

# ============================================================================
# Step 8: 显示部署摘要
# ============================================================================

display_summary() {
    log_info "=========================================="
    log_info "AWS Glue 部署完成！"
    log_info "=========================================="
    echo ""
    echo "🎯 部署信息:"
    echo "  AWS 区域: $AWS_REGION"
    echo "  AWS 账户: $AWS_ACCOUNT_ID"
    echo "  S3 桶: $S3_BUCKET"
    echo "  IAM 角色: $ROLE_NAME"
    echo ""
    echo "📋 已创建组件:"
    echo "  ✓ IAM 角色"
    echo "  ✓ S3 桶和目录"
    echo "  ✓ Glue 脚本"
    echo "  ✓ Glue 数据库"
    echo "  ✓ Glue Crawler"
    echo "  ✓ Glue Jobs"
    echo "  ✓ Glue Triggers"
    echo ""
    echo "🚀 后续步骤:"
    echo "  1. 上传源数据到: s3://${S3_BUCKET}/raw/"
    echo "  2. 运行 Crawler: aws glue start-crawler --name customer-data-crawler"
    echo "  3. 运行清洗 Job: aws glue start-job-run --job-name customer-data-cleansing"
    echo "  4. 查看 Job 执行状态: aws glue get-job-runs --job-name customer-data-cleansing"
    echo ""
    echo "📊 查看结果:"
    echo "  - Athena: SELECT * FROM customer_raw_db.raw_customer_base;"
    echo "  - S3: s3://${S3_BUCKET}/cleaned/"
    echo ""
    log_info "文档: https://docs.aws.amazon.com/glue/"
}

# ============================================================================
# 主函数
# ============================================================================

main() {
    log_info "开始部署 AWS Glue..."
    echo ""

    create_iam_role
    echo ""

    create_s3_structure
    echo ""

    upload_glue_scripts
    echo ""

    create_glue_databases
    echo ""

    create_glue_crawler
    echo ""

    create_glue_jobs
    echo ""

    create_glue_triggers
    echo ""

    display_summary
}

# 执行主函数
main
