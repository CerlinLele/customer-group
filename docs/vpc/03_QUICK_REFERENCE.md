# VPC 快速参考

## 常用命令

### VPC 操作

```bash
# 创建 VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# 列出 VPC
aws ec2 describe-vpcs

# 查看 VPC 详情
aws ec2 describe-vpcs --vpc-ids vpc-xxxxx

# 删除 VPC
aws ec2 delete-vpc --vpc-id vpc-xxxxx

# 添加标签
aws ec2 create-tags --resources vpc-xxxxx --tags Key=Name,Value=my-vpc
```

### 子网操作

```bash
# 创建子网
aws ec2 create-subnet --vpc-id vpc-xxxxx --cidr-block 10.0.1.0/24 --availability-zone us-east-1a

# 列出子网
aws ec2 describe-subnets

# 查看子网详情
aws ec2 describe-subnets --subnet-ids subnet-xxxxx

# 删除子网
aws ec2 delete-subnet --subnet-id subnet-xxxxx

# 添加标签
aws ec2 create-tags --resources subnet-xxxxx --tags Key=Name,Value=my-subnet
```

### 互联网网关操作

```bash
# 创建互联网网关
aws ec2 create-internet-gateway

# 列出互联网网关
aws ec2 describe-internet-gateways

# 附加到 VPC
aws ec2 attach-internet-gateway --internet-gateway-id igw-xxxxx --vpc-id vpc-xxxxx

# 分离 VPC
aws ec2 detach-internet-gateway --internet-gateway-id igw-xxxxx --vpc-id vpc-xxxxx

# 删除互联网网关
aws ec2 delete-internet-gateway --internet-gateway-id igw-xxxxx
```

### 路由表操作

```bash
# 创建路由表
aws ec2 create-route-table --vpc-id vpc-xxxxx

# 列出路由表
aws ec2 describe-route-tables

# 添加路由
aws ec2 create-route --route-table-id rtb-xxxxx --destination-cidr-block 0.0.0.0/0 --gateway-id igw-xxxxx

# 关联子网
aws ec2 associate-route-table --route-table-id rtb-xxxxx --subnet-id subnet-xxxxx

# 删除路由
aws ec2 delete-route --route-table-id rtb-xxxxx --destination-cidr-block 0.0.0.0/0

# 删除路由表
aws ec2 delete-route-table --route-table-id rtb-xxxxx
```

### 安全组操作

```bash
# 创建安全组
aws ec2 create-security-group --group-name my-sg --description "My security group" --vpc-id vpc-xxxxx

# 列出安全组
aws ec2 describe-security-groups

# 添加入站规则
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 7077 \
  --cidr 10.0.0.0/16

# 添加出站规则
aws ec2 authorize-security-group-egress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# 删除入站规则
aws ec2 revoke-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 7077 \
  --cidr 10.0.0.0/16

# 删除安全组
aws ec2 delete-security-group --group-id sg-xxxxx
```

### NAT Gateway 操作

```bash
# 分配 Elastic IP
aws ec2 allocate-address --domain vpc

# 创建 NAT Gateway
aws ec2 create-nat-gateway --subnet-id subnet-xxxxx --allocation-id eipalloc-xxxxx

# 列出 NAT Gateway
aws ec2 describe-nat-gateways

# 删除 NAT Gateway
aws ec2 delete-nat-gateway --nat-gateway-id natgw-xxxxx

# 释放 Elastic IP
aws ec2 release-address --allocation-id eipalloc-xxxxx
```

### VPC 端点操作

```bash
# 创建 S3 VPC 端点
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxxxx \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids rtb-xxxxx

# 列出 VPC 端点
aws ec2 describe-vpc-endpoints

# 删除 VPC 端点
aws ec2 delete-vpc-endpoints --vpc-endpoint-ids vpce-xxxxx
```

## 常见配置

### 基础 VPC 配置

```bash
# 1. 创建 VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)

# 2. 创建公有子网
PUBLIC_SUBNET=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --query 'Subnet.SubnetId' --output text)

# 3. 创建私有子网
PRIVATE_SUBNET=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --query 'Subnet.SubnetId' --output text)

# 4. 创建互联网网关
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)

# 5. 附加互联网网关
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

# 6. 创建公有路由表
PUBLIC_RT=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)

# 7. 添加路由
aws ec2 create-route --route-table-id $PUBLIC_RT --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

# 8. 关联子网
aws ec2 associate-route-table --route-table-id $PUBLIC_RT --subnet-id $PUBLIC_SUBNET
```

### Glue 安全组配置

```bash
# 创建安全组
SG_ID=$(aws ec2 create-security-group \
  --group-name glue-sg \
  --description "Glue security group" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

# 允许 Spark 通信
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 7077-7078 \
  --source-group $SG_ID

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 38600-38700 \
  --source-group $SG_ID

# 允许出站到 AWS 服务
aws ec2 authorize-security-group-egress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0
```

## CIDR 块参考

### 常用 CIDR 块

| CIDR | 范围 | 主机数 | 用途 |
|------|------|--------|------|
| 10.0.0.0/16 | 10.0.0.0 - 10.0.255.255 | 65,536 | VPC |
| 10.0.0.0/24 | 10.0.0.0 - 10.0.0.255 | 256 | 子网 |
| 10.0.1.0/24 | 10.0.1.0 - 10.0.1.255 | 256 | 公有子网 |
| 10.0.2.0/24 | 10.0.2.0 - 10.0.2.255 | 256 | 私有子网 |
| 172.16.0.0/12 | 172.16.0.0 - 172.31.255.255 | 1,048,576 | VPC |
| 192.168.0.0/16 | 192.168.0.0 - 192.168.255.255 | 65,536 | VPC |

### 子网划分示例

```
VPC: 10.0.0.0/16

公有子网:
- 10.0.1.0/24 (us-east-1a)
- 10.0.2.0/24 (us-east-1b)

私有子网:
- 10.0.10.0/24 (us-east-1a)
- 10.0.11.0/24 (us-east-1b)
- 10.0.12.0/24 (us-east-1c)
```

## 安全组规则参考

### Glue 安全组

```
入站规则:
- 协议: TCP
- 端口: 7077-7078
- 源: 安全组本身

- 协议: TCP
- 端口: 38600-38700
- 源: 安全组本身

出站规则:
- 协议: TCP
- 端口: 443
- 目标: 0.0.0.0/0 (HTTPS)

- 协议: TCP
- 端口: 80
- 目标: 0.0.0.0/0 (HTTP)
```

### 数据库安全组

```
入站规则:
- 协议: TCP
- 端口: 3306 (MySQL)
- 源: Glue 安全组

- 协议: TCP
- 端口: 5432 (PostgreSQL)
- 源: Glue 安全组
```

## 故障排除命令

### 检查连接

```bash
# 检查安全组规则
aws ec2 describe-security-groups --group-ids sg-xxxxx

# 检查网络 ACL
aws ec2 describe-network-acls --filters "Name=association.subnet-id,Values=subnet-xxxxx"

# 检查路由表
aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=subnet-xxxxx"

# 检查 VPC 端点
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=vpc-xxxxx"
```

### 检查 VPC Flow Logs

```bash
# 创建 VPC Flow Logs
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids vpc-xxxxx \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name /aws/vpc/flowlogs

# 查看日志
aws logs tail /aws/vpc/flowlogs --follow
```

## 相关文档

- [VPC 快速开始](./01_QUICK_START.md)
- [VPC 部署检查清单](./02_DEPLOYMENT_CHECKLIST.md)
- [Spark 连接失败问题](../glue/issues/01_SPARK_CONNECTION_FAILURE.md)

---

**最后更新**: 2025-12-10
