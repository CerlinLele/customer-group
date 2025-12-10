# AWS Glue 问题修复总览

本文档按时间顺序记录项目中遇到的 AWS Glue 相关问题及其解决方案。

## 问题列表

### 问题 #1: Spark Executor 连接失败 (2025-12-06)

**状态**: ✅ 已解决

**问题描述**:
```
java.net.ConnectException: Connection refused
Failed to connect to /10.24.204.229:38621
```

Spark executor 无法连接到 driver 节点，导致 `customer-data-cleansing` job 失败。

**根本原因**:
1. 网络超时设置过短（300s）
2. VPC 配置缺失
3. RPC 重试机制不足（仅 5 次）
4. 资源分配不匹配

**解决方案**:
- 增加网络超时: 300s → 600s
- 增加心跳间隔: 60s → 120s
- 增加 RPC 重试: 5 → 10
- 添加 VPC 和安全组配置
- 优化内存和容错设置

**修改文件**:
- `infra/modules/glue/variables.tf` - 添加 VPC 变量
- `infra/modules/glue/security.tf` - 新增安全组配置
- `infra/modules/glue/jobs.tf` - 添加 VPC 支持
- `infra/main.tf` - 添加 VPC 参数
- `glue_scripts/1_data_cleansing.py` - 优化 Spark 配置
- `glue_scripts/2_feature_engineering.py` - 优化 Spark 配置

**详细文档**: [Spark 连接失败问题详解](./01_SPARK_CONNECTION_FAILURE.md)

**部署状态**: ✅ 已验证，可部署

---

## 快速参考

| 问题 | 状态 | 修复日期 | 文档 |
|------|------|---------|------|
| Spark 连接失败 | ✅ 已解决 | 2025-12-06 | [详见](./01_SPARK_CONNECTION_FAILURE.md) |

## 部署指南

### 快速部署 (3 步)

```bash
# 1. 查看修复详情
cat 01_SPARK_CONNECTION_FAILURE.md

# 2. 应用 Terraform 配置
cd infra
terraform apply

# 3. 运行 Job 验证
aws glue start-job-run --job-name customer-data-cleansing
```

### 完整部署

详见 [Spark 连接失败问题详解](./01_SPARK_CONNECTION_FAILURE.md) 中的"部署步骤"部分。

## 相关文档

- [Glue 快速开始](../00_QUICK_START.md)
- [Glue 操作指南](../operations/01_OPERATIONS_GUIDE.md)
- [Terraform 部署指南](../../terraform/02_DEPLOYMENT_GUIDE.md)

---

**最后更新**: 2025-12-10
