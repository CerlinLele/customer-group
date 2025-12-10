# VPC 快速开始

## 什么是 VPC？

Amazon VPC（Virtual Private Cloud）是一个虚拟私有云，允许你在 AWS 中创建隔离的网络环境。

## 核心概念

### VPC
虚拟私有云，是网络的基础。

### 子网 (Subnet)
VPC 内的网络分段，可以是公有或私有。

### 路由表 (Route Table)
定义流量如何在子网之间路由。

### 安全组 (Security Group)
虚拟防火墙，控制入站和出站流量。

### 网络 ACL (NACL)
网络级别的防火墙，控制子网的流量。

## 项目中的 VPC 配置

### VPC 结构

```
VPC (10.0.0.0/16)
├── 公有子网 (10.0.1.0/24)
│   ├── NAT Gateway
│   └── 互联网网关
├── 私有子网 (10.0.2.0/24)
│   └── Glue Jobs
└── 私有子网 (10.0.3.0/24)
    └── 数据库
```

### 安全组

#### Glue 安全组
- 允许 Spark 通信（端口 7077-7078, 38600-38700）
- 允许出站到 S3、Glue 等 AWS 服务

#### 数据库安全组
- 允许来自 Glue 的连接（端口 3306 for MySQL）

## 快速配置

### 使用 Terraform 创建 VPC

编辑 `infra/main.tf`：

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr = "10.0.0.0/16"

  public_subnets = [
    {
      cidr = "10.0.1.0/24"
      az   = "us-east-1a"
    }
  ]

  private_subnets = [
    {
      cidr = "10.0.2.0/24"
      az   = "us-east-1a"
    },
    {
      cidr = "10.0.3.0/24"
      az   = "us-east-1b"
    }
  ]
}
```

然后部署：

```bash
cd infra
terraform apply
```

### 使用 AWS CLI 创建 VPC

```bash
# 创建 VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)

# 创建子网
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --query 'Subnet.SubnetId' --output text)

# 创建互联网网关
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)

# 附加互联网网关到 VPC
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

# 创建路由表
RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)

# 添加路由
aws ec2 create-route --route-table-id $RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

# 关联子网和路由表
aws ec2 associate-route-table --subnet-id $SUBNET_ID --route-table-id $RT_ID
```

## 配置 Glue 使用 VPC

### 步骤 1: 获取 VPC 信息

```bash
# 获取 VPC ID
aws ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text

# 获取子网 ID
aws ec2 describe-subnets --query 'Subnets[*].[SubnetId,AvailabilityZone]' --output table

# 获取安全组 ID
aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupId,GroupName]' --output table
```

### 步骤 2: 更新 Terraform 配置

编辑 `infra/main.tf`：

```hcl
module "glue" {
  source = "./modules/glue"

  # VPC 配置
  vpc_id             = "vpc-xxxxx"
  subnet_ids         = ["subnet-xxxxx", "subnet-yyyyy"]
  security_group_ids = ["sg-xxxxx"]
}
```

### 步骤 3: 部署

```bash
cd infra
terraform apply
```

## 安全最佳实践

### 1. 最小权限原则

```hcl
# 只允许必要的端口
resource "aws_security_group" "glue" {
  ingress {
    from_port   = 7077
    to_port     = 7078
    protocol    = "tcp"
    self        = true
  }
}
```

### 2. 使用私有子网

```hcl
# Glue Jobs 应该在私有子网中
resource "aws_glue_job" "job" {
  vpc_config {
    subnet_ids = [aws_subnet.private.id]
  }
}
```

### 3. 使用 VPC 端点

```hcl
# 创建 S3 VPC 端点，避免通过互联网访问
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.s3"
}
```

### 4. 启用 VPC Flow Logs

```bash
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids vpc-xxxxx \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name /aws/vpc/flowlogs
```

## 常见问题

### Q: 如何连接到私有子网中的资源？

**A**: 使用 Bastion Host 或 AWS Systems Manager Session Manager：

```bash
# 使用 Session Manager
aws ssm start-session --target i-xxxxx
```

### Q: 如何从 Glue 访问 RDS 数据库？

**A**:
1. 将 RDS 放在私有子网
2. 创建安全组允许 Glue 访问
3. 在 Glue Job 中配置 VPC

```hcl
resource "aws_glue_job" "job" {
  vpc_config {
    subnet_ids         = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.glue.id]
  }
}
```

### Q: VPC 会增加成本吗？

**A**: VPC 本身免费，但以下服务可能产生费用：
- NAT Gateway: $0.045/小时
- VPC Endpoint: $0.01/小时
- 数据传输: $0.02/GB

## 相关文档

- [VPC 部署检查清单](./02_DEPLOYMENT_CHECKLIST.md)
- [VPC 快速参考](./03_QUICK_REFERENCE.md)
- [Glue 快速开始](../glue/00_QUICK_START.md)
- [Spark 连接失败问题](../glue/issues/01_SPARK_CONNECTION_FAILURE.md)

---

**最后更新**: 2025-12-10
