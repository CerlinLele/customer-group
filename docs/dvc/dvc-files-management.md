# DVC 文件管理

## 问题背景

项目中存在两个 DVC 配置文件：
- `customer_base.csv.dvc`
- `customer_behavior_assets.csv.dvc`

## 第一问：这俩是什么时候产生的？

### 答案

这两个 `.dvc` 文件是 **DVC（Data Version Control）的配置文件**，用于追踪大数据文件的版本。

根据 git 历史记录，时间线如下：

1. **c48963a** - `dvc 初始化` 时生成了 DVC 初始化配置
2. **6b9a2c9** - `move DVC 实施计划` 时可能开始相关工作
3. **之后** - 通过 `dvc add` 命令添加这两个数据文件

### 文件信息

| 文件 | 大小 | MD5 哈希 |
|------|------|---------|
| customer_base.csv | 1.68 MB | 43dc1fc03d919018d4940e2085283df7 |
| customer_behavior_assets.csv | 25.78 MB | cd877d138572be0f3cf775c988cc74df |

### 工作原理

这些 `.dvc` 文件存储了：
- 文件的 MD5 哈希值（用于版本控制）
- 文件的实际路径
- 文件大小

如果配置了 DVC 远程存储，实际的 CSV 文件被存储在远程（比如 `.dvc-storage` 目录），而 git 只追踪这些 `.dvc` 配置文件，不追踪大 CSV 文件本身。

## 第二问：能删除吗？

### 答案

可以删除，但有不同的删除方式取决于你的需求。

### 三种删除方式

#### 方式 1：只删除 DVC 配置，保留 CSV 文件

```bash
dvc remove customer_base.csv.dvc --keep-local
dvc remove customer_behavior_assets.csv.dvc --keep-local
```

**效果：**
- ✅ 删除 `.dvc` 配置文件
- ✅ 保留本地的 CSV 文件不动
- ✅ 如果有远程存储，数据仍在远程备份中

**适用场景：** 不再需要 DVC 版本控制，但想保留数据文件

#### 方式 2：删除 DVC 配置和本地 CSV 文件

```bash
dvc remove customer_base.csv.dvc --outs
dvc remove customer_behavior_assets.csv.dvc --outs
```

**效果：**
- ✅ 删除 `.dvc` 配置文件
- ✅ 删除本地的 CSV 文件
- ℹ️ 远程存储中的数据仍然保留

#### 方式 3：完全删除 DVC

```bash
dvc destroy
rm -rf .dvc
```

**效果：** 删除整个 DVC 配置和本地缓存

### 恢复方式

如果以后需要恢复数据：

1. **恢复 DVC 追踪：**
   - 从 git 历史恢复 `.dvc` 文件
   - 运行 `dvc pull` 从远程重新获取数据

2. **安全备份方案：**
   ```bash
   # 先备份 CSV 文件到其他地方
   cp customer_base.csv customer_base.csv.backup
   cp customer_behavior_assets.csv customer_behavior_assets.csv.backup

   # 再删除 DVC 追踪
   dvc remove customer_base.csv.dvc --keep-local
   dvc remove customer_behavior_assets.csv.dvc --keep-local
   ```

## 第三问：只删除 .dvc 文件但保留 CSV 数据的最佳实践

### 推荐方案

```bash
dvc remove customer_base.csv.dvc --keep-local
dvc remove customer_behavior_assets.csv.dvc --keep-local
```

这样可以：
- ✅ 删除 `.dvc` 配置文件
- ✅ 保留本地的 CSV 文件
- ✅ 远程存储中的数据备份仍然存在
- ✅ 需要时可以从 git 历史恢复 DVC 配置并重新拉取数据

### 后续操作

执行删除后，需要提交改动到 git：

```bash
git add .gitignore  # DVC 会更新 gitignore
git commit -m "Remove DVC tracking for CSV files"
git push
```
