#!/bin/bash

# Terraform Glue Module Validation Script
# 用途: 验证Terraform Glue模块配置是否正确

set -e

echo "=========================================="
echo "AWS Glue Terraform 模块验证脚本"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查计数
PASSED=0
FAILED=0

# 函数: 检查项
check_item() {
  local item="$1"
  local cmd="$2"

  if eval "$cmd" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} $item"
    ((PASSED++))
  else
    echo -e "${RED}✗${NC} $item"
    ((FAILED++))
  fi
}

# 函数: 通知
notify() {
  local msg="$1"
  echo -e "${YELLOW}ℹ${NC} $msg"
}

echo "=== 步骤 1: 检查前置条件 ==="
echo ""

check_item "Terraform已安装" "terraform version"
check_item "AWS CLI已安装" "aws --version"
check_item "jq已安装" "jq --version"

echo ""
echo "=== 步骤 2: 检查文件结构 ==="
echo ""

check_item "infra目录存在" "[ -d infra ]"
check_item "glue模块目录存在" "[ -d infra/modules/glue ]"
check_item "JSON配置文件存在" "[ -f glue_scripts/config/glue_jobs_config.json ]"

echo ""
echo "=== 步骤 3: 检查Terraform文件 ==="
echo ""

check_item "variables.tf存在" "[ -f infra/modules/glue/variables.tf ]"
check_item "main.tf存在" "[ -f infra/modules/glue/main.tf ]"
check_item "iam.tf存在" "[ -f infra/modules/glue/iam.tf ]"
check_item "databases.tf存在" "[ -f infra/modules/glue/databases.tf ]"
check_item "crawlers.tf存在" "[ -f infra/modules/glue/crawlers.tf ]"
check_item "jobs.tf存在" "[ -f infra/modules/glue/jobs.tf ]"
check_item "triggers.tf存在" "[ -f infra/modules/glue/triggers.tf ]"
check_item "cloudwatch.tf存在" "[ -f infra/modules/glue/cloudwatch.tf ]"
check_item "outputs.tf存在" "[ -f infra/modules/glue/outputs.tf ]"
check_item "README.md存在" "[ -f infra/modules/glue/README.md ]"

echo ""
echo "=== 步骤 4: 检查文档文件 ==="
echo ""

check_item "迁移指南存在" "[ -f docs/TERRAFORM_MIGRATION_GUIDE.md ]"
check_item "运维手册存在" "[ -f docs/GLUE_OPERATIONS_GUIDE.md ]"
check_item "实现总结存在" "[ -f IMPLEMENTATION_SUMMARY.md ]"

echo ""
echo "=== 步骤 5: 验证JSON配置 ==="
echo ""

if jq . glue_scripts/config/glue_jobs_config.json > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} JSON配置格式有效"
  ((PASSED++))

  # 提取配置统计
  JOBS=$(jq '.glue_jobs | length' glue_scripts/config/glue_jobs_config.json)
  CRAWLERS=$(jq '.crawlers | length' glue_scripts/config/glue_jobs_config.json)
  DATABASES=$(jq '.databases | length' glue_scripts/config/glue_jobs_config.json)
  ALARMS=$(jq '.cloudwatch_alarms | length' glue_scripts/config/glue_jobs_config.json)

  echo -e "  - Jobs: $JOBS"
  echo -e "  - Crawlers: $CRAWLERS"
  echo -e "  - Databases: $DATABASES"
  echo -e "  - CloudWatch Alarms: $ALARMS"
else
  echo -e "${RED}✗${NC} JSON配置格式无效"
  echo "  请运行: jq . glue_scripts/config/glue_jobs_config.json"
  ((FAILED++))
fi

echo ""
echo "=== 步骤 6: 检查AWS凭证 ==="
echo ""

check_item "AWS凭证已配置" "aws sts get-caller-identity"

if aws sts get-caller-identity > /dev/null 2>&1; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  REGION=$(aws configure get region || echo "us-east-1")
  echo -e "  - AWS账户: $ACCOUNT_ID"
  echo -e "  - AWS区域: $REGION"
fi

echo ""
echo "=== 步骤 7: 检查IAM权限 ==="
echo ""

# 检查关键权限
if aws iam get-role --role-name GlueCustomerDataRole 2>/dev/null; then
  echo -e "${YELLOW}ℹ${NC} 发现现有IAM角色 (GlueCustomerDataRole)"
  echo "  这是生产环境部署，需要导入现有资源"
  ((PASSED++))
else
  echo -e "${YELLOW}ℹ${NC} 未发现现有IAM角色"
  echo "  这是全新环境部署，可以直接创建"
  ((PASSED++))
fi

echo ""
echo "=== 步骤 8: 检查S3 Bucket ==="
echo ""

# 尝试获取已配置的S3 bucket名称
if [ -f "terraform.tfvars" ]; then
  notify "找到terraform.tfvars文件"
  S3_BUCKET=$(grep "^[[:space:]]*s3_bucket" terraform.tfvars | head -1 | cut -d'"' -f2)
  if [ ! -z "$S3_BUCKET" ]; then
    if aws s3 ls "s3://$S3_BUCKET" 2>/dev/null; then
      echo -e "${GREEN}✓${NC} S3 Bucket可访问: $S3_BUCKET"
      ((PASSED++))
    else
      echo -e "${RED}✗${NC} 无法访问S3 Bucket: $S3_BUCKET"
      ((FAILED++))
    fi
  fi
fi

echo ""
echo "=== 步骤 9: Terraform初始化和验证 ==="
echo ""

# 进入infra目录
cd infra || exit 1

if [ -d ".terraform" ]; then
  notify "Terraform已初始化"
  check_item "Terraform验证" "terraform validate"
  check_item "Terraform格式化" "terraform fmt -check -recursive"
else
  notify "Terraform尚未初始化"
  echo "请运行: cd infra && terraform init"
fi

cd - > /dev/null || exit 1

echo ""
echo "=========================================="
echo "验证结果总结"
echo "=========================================="
echo -e "通过: ${GREEN}$PASSED${NC}"
echo -e "失败: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ 所有检查通过！${NC}"
  echo ""
  echo "后续步骤:"
  echo "1. cd infra"
  echo "2. terraform init"
  echo "3. terraform plan"
  echo "4. terraform apply"
  echo ""
  exit 0
else
  echo -e "${RED}✗ 有失败项，请先修复${NC}"
  echo ""
  echo "故障排查:"
  echo "1. 检查JSON配置格式: jq . glue_scripts/config/glue_jobs_config.json"
  echo "2. 检查AWS凭证: aws sts get-caller-identity"
  echo "3. 检查IAM权限: aws iam get-user"
  echo ""
  exit 1
fi
