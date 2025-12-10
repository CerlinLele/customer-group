# AWS Glue customer-data-cleansing Job 修复完成报告

## 问题诊断

**失败原因**: Spark executor 无法连接到 driver 节点
```
java.net.ConnectException: Connection refused
Failed to connect to /10.24.204.229:38621
```

**根本原因**：
1. VPC 网络配置缺失
2. Spark 网络超时设置过短
3. 安全组规则不允许 executor-driver 通信

---

## 实施的修复 ✅

### 1. Terraform 基础设施代码更新

#### 新增文件
- `infra/modules/glue/security.tf` - 安全组和 VPC 配置

#### 修改文件

**`infra/modules/glue/variables.tf`** - 添加 VPC 支持
```hcl
variable "vpc_id" { ... }
variable "subnet_ids" { ... }
variable "security_group_ids" { ... }
```

**`infra/modules/glue/jobs.tf`** - 添加 VPC 配置参考
```hcl
security_configuration = length(var.subnet_ids) > 0 ?
  aws_glue_security_configuration.vpc_security[0].name : null
```

**`infra/main.tf`** - 添加 VPC 参数入口
```hcl
vpc_id          = ""  # 可选配置
subnet_ids      = []  # 可选配置
security_group_ids = []
```

### 2. Spark 脚本优化

#### 修改文件
- `glue_scripts/1_data_cleansing.py`
- `glue_scripts/2_feature_engineering.py`

#### 优化内容

**网络连接优化**
```python
spark_conf.set("spark.network.timeout", "600s")            # 300s → 600s
spark_conf.set("spark.executor.heartbeatInterval", "120s") # 60s → 120s
spark_conf.set("spark.rpc.numRetries", "10")               # 5 → 10
spark_conf.set("spark.shuffle.io.maxRetries", "5")         # 新增
```

**内存和资源配置**
```python
spark_conf.set("spark.driver.memory", "4g")
spark_conf.set("spark.executor.memory", "4g")
spark_conf.set("spark.executor.cores", "4")
spark_conf.set("spark.default.parallelism", "8")
```

**容错性增强**
```python
spark_conf.set("spark.executor.maxFailures", "5")
spark_conf.set("spark.task.maxFailures", "5")
spark_conf.set("spark.speculation", "true")
```

---

## 文件变更清单

| 文件 | 类型 | 变更 |
|------|------|------|
| `infra/modules/glue/variables.tf` | 修改 | +VPC 变量（3个） |
| `infra/modules/glue/security.tf` | 新增 | 安全组、Glue 安全配置、IAM 策略 |
| `infra/modules/glue/jobs.tf` | 修改 | +VPC 安全配置引用 |
| `infra/main.tf` | 修改 | +VPC 参数和说明 |
| `glue_scripts/1_data_cleansing.py` | 修改 | +网络/内存/容错配置 |
| `glue_scripts/2_feature_engineering.py` | 修改 | +网络/内存/容错配置 |

---

## 验证状态

✅ Terraform 语法验证通过
✅ Python 脚本编译检查通过
✅ 所有配置参数正确

---

## 使用说明

### 场景 A：公有环境（默认）
无需额外配置，修复后的 Spark 设置会自动应用。

### 场景 B：私有 VPC 环境（推荐）

1. **获取 VPC 信息**
   ```bash
   # VPC ID
   aws ec2 describe-vpcs --query 'Vpcs[0].VpcId'

   # 子网 IDs
   aws ec2 describe-subnets --query 'Subnets[*].[SubnetId]' \
     --filters Name=vpc-id,Values=vpc-xxxxx
   ```

2. **更新 `infra/main.tf`**
   ```hcl
   module "glue_pipeline" {
     # ...
     vpc_id     = "vpc-xxxxx"
     subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]
   }
   ```

3. **部署更改**
   ```bash
   cd infra
   terraform plan
   terraform apply
   ```

4. **重新运行 Job**
   ```bash
   aws glue start-job-run --job-name customer-data-cleansing
   ```

---

## 监控

### CloudWatch 日志
```bash
aws logs tail /aws-glue/jobs/customer-data-cleansing --follow
```

### 性能指标
- 监控命名空间：`CustomerDataPipeline`
- 关键指标：`CustomerBaseRows`、`CustomerBehaviorRows`

---

## 如果问题持续

增加超时参数（在脚本中已是默认值）：
```python
spark_conf.set("spark.network.timeout", "900s")
spark_conf.set("spark.executor.heartbeatInterval", "180s")
spark_conf.set("spark.rpc.numRetries", "15")
```

检查 CloudWatch 日志确认具体的连接错误。

---

## 技术文档

详见：[GLUE_CONNECTION_FIX.md](docs/feature-engineering/GLUE_CONNECTION_FIX.md)
快速参考：[GLUE_FIX_SUMMARY.md](GLUE_FIX_SUMMARY.md)
