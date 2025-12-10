# VPC部署检查清单

## 前置检查 ✓

- [x] VPC模块已创建 (`infra/modules/vpc/`)
- [x] 所有必需的资源已定义
- [x] Terraform验证通过
- [x] 所有文件格式化完成
- [x] 文档已生成

## 部署前准备

- [ ] AWS凭证已配置
- [ ] 有权限创建VPC资源
- [ ] 已备份现有Terraform状态
- [ ] 已查看Terraform计划输出

## 部署步骤

### 第1步: 初始化 Terraform
```bash
cd infra
terraform init
```
预期结果:
```
Initializing modules...
- vpc in modules\vpc
```
- [ ] 初始化成功

### 第2步: 验证配置
```bash
terraform validate
```
预期结果:
```
Success! The configuration is valid.
```
- [ ] 验证通过

### 第3步: 查看部署计划
```bash
terraform plan -out=tfplan
```
预期创建的资源:
- [ ] aws_vpc
- [ ] aws_internet_gateway
- [ ] aws_subnet (4个)
- [ ] aws_nat_gateway
- [ ] aws_eip
- [ ] aws_route_table (2个)
- [ ] aws_route_table_association (4个)
- [ ] aws_security_group
- [ ] aws_glue_job (更新以添加VPC参数)
- [ ] aws_glue_security_configuration (如需)

### 第4步: 部署基础设施
```bash
terraform apply tfplan
```
预期时间: 5-10分钟

- [ ] 所有资源创建成功
- [ ] 无错误信息
- [ ] 输出显示VPC ID等信息

## 部署后验证

### 验证VPC资源
```bash
# 查看VPC ID
terraform output vpc_id

# 查看私有子网IDs
terraform output private_subnet_ids

# 查看安全组ID
terraform output glue_security_group_id
```
- [ ] 获得有效的VPC ID
- [ ] 获得2个私有子网IDs
- [ ] 获得安全组ID

### 在AWS控制台验证
1. **VPC控制台**
   - [ ] VPC已创建 (10.0.0.0/16)
   - [ ] 4个子网已创建
   - [ ] 互联网网关已连接
   - [ ] NAT网关已创建

2. **EC2 > 安全组**
   - [ ] Glue安全组已存在
   - [ ] 规则配置正确

3. **Glue > 作业**
   - [ ] 作业配置更新
   - [ ] VPC配置已应用

## 故障排除

### 如果 `terraform init` 失败
```bash
# 清理.terraform目录
rm -rf .terraform
terraform init
```

### 如果 VPC 创建失败
- 检查AWS凭证有效性
- 检查IAM权限 (VPC、NAT、安全组)
- 查看Terraform错误日志

### 如果 Glue 集成失败
- 验证VPC子网ID有效
- 检查安全组允许出站访问
- 检查IAM角色VPC权限

## 下一步

1. **监控Glue作业**
   - 观察第一个作业运行
   - 检查CloudWatch日志
   - 验证网络连接成功

2. **优化配置**
   - 根据需要调整安全组规则
   - 添加VPC流日志用于调试
   - 配置成本优化

3. **维护**
   - 定期备份Terraform状态
   - 监控NAT网关流量和成本
   - 保持Terraform版本更新

## 重要信息

### VPC配置详情
- VPC CIDR: 10.0.0.0/16
- 公共子网: 10.0.1.0/24, 10.0.2.0/24
- 私有子网: 10.0.11.0/24, 10.0.12.0/24
- 跨AZ: us-east-1a, us-east-1b

### 成本考虑
- NAT网关: 每月约 $32 (1个)
- 数据处理: 按GB计费
- VPC本身: 无成本

### 安全最佳实践
✓ Glue在私有子网中运行
✓ 出站通过NAT网关
✓ 安全组限制流量
✓ 跨AZ高可用

## 需要帮助?

参考文档:
- 详细说明: `VPC_SETUP_SUMMARY.md`
- 快速参考: `VPC_QUICK_REFERENCE.md`
- 创建完成: `VPC_CREATION_COMPLETE.md`

---

**清单状态**: 准备就绪
**创建日期**: 2025-12-06
**最后更新**: 2025-12-06
