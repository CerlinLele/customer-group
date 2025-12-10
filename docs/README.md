# 项目文档索引

本项目文档按功能模块组织，包含特征工程、AWS Glue 数据处理、Terraform 基础设施和 VPC 网络配置。

## 📚 文档结构

### 1. [特征工程 (feature-engineering/)](./feature-engineering/)
特征工程的计划、实现指南和数据处理方案。

- **[特征工程计划](./feature-engineering/01_PLAN.md)** - 特征工程的整体规划和目标
- **[AWS 云端处理方案](./feature-engineering/02_AWS_SOLUTION.md)** - 基于 AWS 的实现方案
- **[增量数据处理指南](./feature-engineering/03_INCREMENTAL_PROCESSING.md)** - 增量数据处理的最佳实践

### 2. [AWS Glue (glue/)](./glue/)
AWS Glue 数据处理平台的完整文档。

#### 快速开始
- **[Glue 快速开始](./glue/00_QUICK_START.md)** - 5 分钟快速入门指南

#### 核心概念
- **[数据目录 (Data Catalog)](./glue/concepts/01_DATA_CATALOG.md)** - Glue 数据目录的概念和使用
- **[数据库和表](./glue/concepts/02_DATABASES_AND_TABLES.md)** - 数据库和表的管理
- **[爬虫和连接](./glue/concepts/03_CRAWLERS_AND_CONNECTIONS.md)** - 数据爬虫和连接配置

#### 操作指南
- **[Glue 操作指南](./glue/operations/01_OPERATIONS_GUIDE.md)** - 日常操作和管理
- **[Job 执行指南](./glue/operations/02_JOB_EXECUTION.md)** - Job 的创建、配置和执行

#### 问题修复历程
按时间顺序记录遇到的问题和解决方案。

- **[问题修复总览](./glue/issues/00_OVERVIEW.md)** - 所有问题的总体概览
- **[问题 #1: Spark 连接失败 (2025-12-06)](./glue/issues/01_SPARK_CONNECTION_FAILURE.md)** - Executor 无法连接到 Driver
  - 根本原因分析
  - 修复方案（网络超时、VPC 配置、重试机制）
  - 部署步骤和验证

### 3. [Terraform 基础设施 (terraform/)](./terraform/)
基础设施即代码的配置和部署指南。

- **[Terraform 快速参考](./terraform/01_QUICK_REFERENCE.md)** - 常用命令和配置
- **[部署指南](./terraform/02_DEPLOYMENT_GUIDE.md)** - 完整的部署流程
- **[迁移指南](./terraform/03_MIGRATION_GUIDE.md)** - 从其他工具迁移到 Terraform

### 4. [VPC 网络配置 (vpc/)](./vpc/)
虚拟私有云的配置和管理。

- **[VPC 快速开始](./vpc/01_QUICK_START.md)** - VPC 的基本配置
- **[VPC 部署检查清单](./vpc/02_DEPLOYMENT_CHECKLIST.md)** - 部署前的检查项
- **[VPC 快速参考](./vpc/03_QUICK_REFERENCE.md)** - 常用命令和配置

## 🎯 快速导航

### 我想...

- **快速开始项目** → 查看 [Glue 快速开始](./glue/00_QUICK_START.md)
- **了解特征工程** → 查看 [特征工程计划](./feature-engineering/01_PLAN.md)
- **部署基础设施** → 查看 [Terraform 部署指南](./terraform/02_DEPLOYMENT_GUIDE.md)
- **配置网络** → 查看 [VPC 快速开始](./vpc/01_QUICK_START.md)
- **解决 Glue 问题** → 查看 [问题修复总览](./glue/issues/00_OVERVIEW.md)

## 📋 文档维护

- 所有文档按模块组织，避免重复
- 问题修复按时间顺序记录，便于追踪
- 每个文档都有明确的用途和目标读者
- 使用相对链接便于导航

---

**最后更新**: 2025-12-10
