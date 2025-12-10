# VPC Quick Reference

## VPC已创建完成

你的项目现在有了一个专门的VPC，配置如下：

### 核心资源
| 资源 | 值 |
|------|-----|
| VPC CIDR | 10.0.0.0/16 |
| VPC 名称 | case-customer-group-{env}-vpc |
| 公共子网 | 10.0.1.0/24, 10.0.2.0/24 |
| 私有子网 | 10.0.11.0/24, 10.0.12.0/24 |
| NAT 网关 | 1个 (在公共子网) |
| 安全组 | case-customer-group-{env}-glue-sg |

### 快速命令

#### 1. 初始化并验证
```bash
cd infra
terraform init
terraform validate
```

#### 2. 查看将要创建的资源
```bash
terraform plan -out=tfplan
```

#### 3. 部署VPC和Glue
```bash
terraform apply tfplan
```

#### 4. 查看部署结果
```bash
terraform output vpc_id
terraform output private_subnet_ids
terraform output glue_security_group_id
```

#### 5. 完全查看所有输出
```bash
terraform output
```

### 关键变更

1. **创建新的VPC模块**: `infra/modules/vpc/`
   - 包含VPC、子网、NAT网关、安全组

2. **更新main.tf**
   - 添加VPC模块
   - 连接VPC到Glue管道

3. **更新Glue配置**
   - Glue现在运行在私有子网中
   - 自动应用安全组
   - VPC参数通过default_arguments传递

4. **更新outputs.tf**
   - 添加VPC相关的输出信息

### 网络通信

**Glue → S3/AWS服务流向**:
- Glue在私有子网 → NAT网关 → 互联网网关 → AWS API

**安全组规则**:
- 入站: 自身通信(TCP 0-65535) + Spark端口
- 出站: 所有流量 (0.0.0.0/0)

### 修改VPC配置

要改变VPC的CIDR或子网，编辑 `infra/main.tf`:

```hcl
module "vpc" {
  source = "./modules/vpc"

  # ... 其他配置 ...

  vpc_cidr              = "10.0.0.0/16"        # 修改VPC CIDR
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24"]
}
```

### 清理资源

要删除VPC及所有资源:
```bash
cd infra
terraform destroy
```

---

详细文档见 `VPC_SETUP_SUMMARY.md`
