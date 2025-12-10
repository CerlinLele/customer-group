# customer-data-cleansing 快速修复摘要

## 问题
```
java.net.ConnectException: Connection refused
Failed to connect to /10.24.204.229:38621
```
Spark executor 无法连接到 driver 节点。

## 快速修复（3步）

### 1️⃣ 如果使用私有 VPC
编辑 `infra/main.tf`，取消注释并填入你的 VPC 信息：
```hcl
# 获取这些值：
vpc_id            = "vpc-xxxxx"
subnet_ids        = ["subnet-xxxxx", "subnet-yyyyy"]
```

### 2️⃣ 应用 Terraform 改动
```bash
cd infra
terraform apply
```

### 3️⃣ 重新运行 Job
```bash
aws glue start-job-run --job-name customer-data-cleansing
```

## 如果问题持续

增加 Spark 超时值在脚本中（这已经是默认值）：
```python
spark_conf.set("spark.network.timeout", "600s")
spark_conf.set("spark.executor.heartbeatInterval", "120s")
```

## 文件变更

✅ `infra/modules/glue/variables.tf` - VPC 变量
✅ `infra/modules/glue/security.tf` - 新建，安全组配置
✅ `infra/modules/glue/jobs.tf` - VPC 配置块
✅ `infra/main.tf` - VPC 参数
✅ `glue_scripts/1_data_cleansing.py` - 网络配置优化
✅ `glue_scripts/2_feature_engineering.py` - 网络配置优化

详见：[GLUE_CONNECTION_FIX.md](GLUE_CONNECTION_FIX.md)
