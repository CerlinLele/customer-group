# VPC冲突解决 - 完成报告

## 问题

在部署过程中，遇到了一个安全组冲突：

```
Error: creating Security Group (case-customer-group-dev-glue-sg):
The security group 'case-customer-group-dev-glue-sg' already exists for VPC 'vpc-0f180782b8a66df47'
```

**原因**:
- VPC模块创建了一个名为 `case-customer-group-dev-glue-sg` 的安全组
- Glue模块也试图创建同名的安全组
- 导致资源重复冲突

## 解决方案

### 1. 删除重复的安全组定义

**文件**: `infra/modules/glue/security.tf`

**改动**: 移除了Glue模块中的 `aws_security_group.glue_sg` 资源定义，因为这个资源现在由VPC模块提供

**之前**:
```hcl
resource "aws_security_group" "glue_sg" {
  count = length(var.subnet_ids) > 0 ? 1 : 0
  # ... 安全组配置 ...
}
```

**之后**:
```hcl
# Note: Security group for Glue jobs is now created by the VPC module
# This avoids duplication and ensures proper VPC integration.
```

### 2. 更新Glue作业默认参数

**文件**: `infra/modules/glue/jobs.tf`

**改动**: 简化了安全组ID的引用，直接使用通过Terraform变量传入的 `var.security_group_ids`

**之前**:
```hcl
"--vpc-security-group-ids" = join(",", length(var.security_group_ids) > 0 ? var.security_group_ids : [aws_security_group.glue_sg[0].id])
```

**之后**:
```hcl
"--vpc-security-group-ids" = join(",", var.security_group_ids)
```

## 架构改进

这个解决方案改进了架构设计：

```
之前 (有冲突):
┌─────────────────┐
│  Glue模块       │
│  ├─ Jobs        │
│  ├─ Security.tf │◄─── 创建安全组 ❌ 冲突
│  └─ IAM         │
└─────────────────┘

VPC模块          │
├─ VPC           │
├─ Subnets       │
├─ NAT/IGW       │
└─ Security Group◄─── 也创建安全组 ❌ 冲突
```

```
之后 (已解决):
┌─────────────────┐
│  VPC模块        │
│  ├─ VPC         │
│  ├─ Subnets     │
│  ├─ NAT/IGW     │
│  └─ Security Grp✓ 唯一的安全组
└─────────────────┘
         ▲
         │ 引用
┌─────────────────┐
│  Glue模块       │
│  ├─ Jobs        │
│  ├─ IAM         │
│  └─ (不创建SG) ✓
└─────────────────┘
```

## 部署结果

✅ **部署成功!**

### VPC资源
- VPC ID: `vpc-0f180782b8a66df47`
- VPC CIDR: `10.0.0.0/16`

### 子网
- **公共子网**:
  - `subnet-055931e8e9290557b` (10.0.1.0/24, us-east-1a)
  - `subnet-00da01c9e5321a34b` (10.0.2.0/24, us-east-1b)

- **私有子网** (Glue运行位置):
  - `subnet-0f6b6ddf50c8f84f1` (10.0.11.0/24, us-east-1a)
  - `subnet-00bbf3f110741d0ec` (10.0.12.0/24, us-east-1b)

### 安全组
- 安全组ID: `sg-0345d58351a9f8de8`
- 名称: `case-customer-group-dev-glue-sg`
- 管理者: VPC模块

### Glue作业更新
两个Glue作业已成功更新VPC配置：

1. **customer-data-cleansing**
   - 现在运行在VPC私有子网中
   - 使用配置的安全组
   - 已应用Glue安全配置

2. **customer-feature-engineering**
   - 现在运行在VPC私有子网中
   - 使用配置的安全组
   - 已应用Glue安全配置

## 配置变更

Terraform应用了以下变更：

```
Plan: 0 to add, 3 to change, 0 to destroy

- aws_s3_object.customer_behavior_assets_csv (版本更新)
- aws_glue_job.jobs["customer-data-cleansing"] (添加VPC参数)
- aws_glue_job.jobs["customer-feature-engineering"] (添加VPC参数)
```

**新增的Glue作业参数**:
```
--vpc-subnet-ids = "subnet-0f6b6ddf50c8f84f1,subnet-00bbf3f110741d0ec"
--vpc-security-group-ids = "sg-0345d58351a9f8de8"
```

## 最佳实践

这个解决方案遵循以下最佳实践：

1. ✅ **单一责任**: VPC模块负责所有网络基础设施
2. ✅ **无重复**: 避免在多个地方定义相同的资源
3. ✅ **解耦**: Glue模块通过变量接收网络配置，而不是创建它们
4. ✅ **灵活性**: 支持带或不带VPC的Glue部署

## 验证步骤

您可以验证配置是否正确：

```bash
# 查看VPC详情
terraform output vpc_id
terraform output private_subnet_ids
terraform output glue_security_group_id

# 或查看完整的VPC信息
terraform output | grep vpc_
```

## 对比总结

| 方面 | 之前 | 之后 |
|------|------|------|
| 安全组定义位置 | Glue模块 (冲突) | VPC模块 (清晰) |
| 安全组数量 | 2个 (重复) | 1个 (统一) |
| Glue集成 | 引用本地资源 | 引用VPC输出 |
| 架构清晰性 | 低 | 高 |
| 维护性 | 低 | 高 |

---

**状态**: ✅ 完全解决
**解决时间**: 2025-12-06
**部署状态**: 成功
**后续行动**: 无需进一步配置
