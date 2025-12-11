# Windows 环境变量配置指南

## 什么是环境变量?

环境变量是 Windows 系统中存储的配置信息，应用程序可以读取这些变量来了解系统配置。对于 Java 和 Spark 开发，关键的环境变量是 `JAVA_HOME`。

---

## 方式 1: 临时设置 (当前命令行会话)

### 设置命令

```batch
$env:JAVA_HOME = "C:\Program Files\Java\jdk-11"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
java -version

python -c "import pyspark, os; print('pyspark =', pyspark.__version__); print('JAVA_HOME =', os.environ.get('JAVA_HOME')); print('SPARK_HOME =', os.environ.get('SPARK_HOME'))"
```

### 使用场景

- 快速测试
- 不需要永久保存
- 当前命令行关闭后失效

---

## 方式 2: 永久设置 (系统环境变量)

### 步骤 1: 打开系统设置

**方法 A: 控制面板**

1. 打开 `控制面板`
2. 点击 `系统和安全`
3. 点击 `系统`
4. 点击左侧 `高级系统设置`

**方法 B: 直接搜索**

1. 按 `Win + R` 打开运行对话框
2. 输入 `SystemPropertiesAdvanced` 按回车

**方法 C: 搜索应用**

1. 点击 Windows 搜索图标
2. 搜索 `环境变量`
3. 点击 `编辑系统环境变量`

### 步骤 2: 添加环境变量

1. 在 `系统属性` 窗口中，点击 `环境变量` 按钮
2. 在 `系统变量` 部分，点击 `新建`
3. 填写以下内容:
   - 变量名: `JAVA_HOME`
   - 变量值: `C:\Program Files\Java\jdk-11` (根据实际安装路径修改)
4. 点击 `确定` → `确定` → `确定`

### 步骤 3: 验证设置

1. **关闭并重新打开** 命令行
2. 运行验证命令:

```batch
echo %JAVA_HOME%
java -version
```

应该显示 Java 11 的信息。

---

## 方式 3: 在 Jupyter 笔记本中动态设置

### Python 代码

在笔记本的第一个单元格中运行:

```python
import os

# 设置 JAVA_HOME
os.environ['JAVA_HOME'] = r'C:\Program Files\Java\jdk-11'

# 设置 Spark 相关环境变量
os.environ['PYSPARK_PYTHON'] = os.environ.get('PYTHON_PATH', 'python')
os.environ['_JAVA_OPTIONS'] = '-Djavax.security.auth.useSubjectCredsOnly=false'

# 验证
print("JAVA_HOME:", os.environ.get('JAVA_HOME'))
print("_JAVA_OPTIONS:", os.environ.get('_JAVA_OPTIONS'))
```

### 使用场景

- Jupyter 笔记本中临时设置
- 不需要修改系统配置
- 特定项目特定配置

---

## 常见 Java 安装路径

### Java 11

```
C:\Program Files\Java\jdk-11
C:\Program Files\Java\jdk-11.0.20
C:\Program Files\Java\jdk-11.0.19
```

### Java 8

```
C:\Program Files\Java\jdk1.8.0_202
C:\Program Files\Java\jdk1.8.0_191
```

### Java 17

```
C:\Program Files\Java\jdk-17
C:\Program Files\Java\jdk-17.0.1
```

### Java 24

```
C:\Program Files\Java\jdk-24
```

### 如何查找 Java 安装路径?

#### 方法 1: 通过命令行

```batch
java -version
where java
```

#### 方法 2: 文件浏览器

1. 打开文件浏览器
2. 导航到 `C:\Program Files\Java\`
3. 查看已安装的 Java 目录

#### 方法 3: 注册表

1. 按 `Win + R`
2. 输入 `regedit` 打开注册表编辑器
3. 导航到 `HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft\Java Development Kit`

---

## 快速设置脚本

### 自动设置脚本 (setup_java_env.bat)

```batch
@echo off
REM 自动配置 Java 环境变量

setlocal enabledelayedexpansion

REM 检查 Java 11 是否存在
if exist "C:\Program Files\Java\jdk-11" (
    set "JAVA_HOME=C:\Program Files\Java\jdk-11"
    echo Found Java 11: !JAVA_HOME!
) else if exist "C:\Program Files\Java\jdk-11.0.20" (
    set "JAVA_HOME=C:\Program Files\Java\jdk-11.0.20"
    echo Found Java 11.0.20: !JAVA_HOME!
) else if exist "C:\Program Files\Java\jdk-1.8.0_202" (
    set "JAVA_HOME=C:\Program Files\Java\jdk-1.8.0_202"
    echo Found Java 8: !JAVA_HOME!
) else (
    echo ERROR: Java not found!
    echo Please install Java 11 from: https://www.oracle.com/java/technologies/downloads/
    pause
    exit /b 1
)

REM 设置环境变量
setx JAVA_HOME "!JAVA_HOME!"

REM 验证
echo.
echo JAVA_HOME set to: !JAVA_HOME!
java -version

echo.
echo Restart your terminal for changes to take effect.
pause
```

### 验证脚本 (verify_java.bat)

```batch
@echo off
echo ============================================
echo Java Environment Verification
echo ============================================
echo.

REM 检查 Java 是否可用
java -version 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Java not found!
    exit /b 1
)

echo.
echo JAVA_HOME: %JAVA_HOME%

REM 检查 Spark
echo.
echo Python:
python --version

echo.
echo PySpark:
python -c "import pyspark; print('PySpark version:', pyspark.__version__)" 2>&1

echo.
echo ============================================
echo Verification Complete!
echo ============================================
```

---

## 问题排查

### Q: 设置了 JAVA_HOME 但仍然显示 "not found"

**解决方案:**
1. 确认 JAVA_HOME 指向的目录存在: `dir %JAVA_HOME%`
2. 重新启动命令行 (临时设置需要新开命令行)
3. 检查路径中是否有空格 (用引号括起来)
4. 验证目录中有 `bin` 文件夹: `dir %JAVA_HOME%\bin`

### Q: 系统显示 "Access Denied" 设置环境变量

**解决方案:**
1. 以管理员身份运行命令行
2. 右键点击命令行 → `以管理员身份运行`
3. 然后运行 `setx` 命令

### Q: 修改了环境变量后仍然没有生效

**解决方案:**
1. **关闭当前命令行**，打开新的命令行
2. 检查是否真的设置成功: `echo %JAVA_HOME%`
3. 某些应用 (IDE) 需要重启才能读取新的环境变量

### Q: 有多个 Java 版本，不知道用哪个

**解决方案:**
```batch
REM 查看所有可用的 Java 版本
dir "C:\Program Files\Java"

REM 设置为 Java 11 (推荐用于 PySpark)
set JAVA_HOME=C:\Program Files\Java\jdk-11
```

---

## PATH 环境变量 (高级)

如果需要在任何目录下直接运行 Java 命令，可以将 Java 的 bin 目录添加到 PATH:

### 通过命令行 (临时)

```batch
set PATH=%JAVA_HOME%\bin;%PATH%
```

### 通过系统设置 (永久)

1. 打开 `环境变量` 设置
2. 在 `系统变量` 中找到 `Path`
3. 点击 `编辑`
4. 点击 `新建`
5. 输入: `%JAVA_HOME%\bin`
6. 点击 `确定`
7. 重启命令行

---

## Python 虚拟环境中的环境变量

对于项目特定的环境变量，可以在虚拟环境的激活脚本中设置:

### Windows 虚拟环境 (.venv\Scripts\activate.bat)

```batch
@echo off
REM 原有内容...

REM 在底部添加:
set JAVA_HOME=C:\Program Files\Java\jdk-11
set _JAVA_OPTIONS=-Djavax.security.auth.useSubjectCredsOnly=false
```

这样每次激活虚拟环境时都会自动设置这些变量。

---

## 最佳实践

### ✓ 推荐做法

1. **使用 Java 11** - 与 PySpark 最兼容
2. **全系统设置** - 一次设置，处处可用
3. **验证安装** - 设置后立即验证
4. **文档记录** - 保存安装路径和设置信息

### ✗ 避免做法

1. **混用多个 Java 版本** - 容易出现冲突
2. **使用包含空格的路径** - 使用时需要引号
3. **忘记重启应用** - IDE 需要重启才能读取新变量
4. **使用过旧的 Java** - Java 8 可能不兼容新版 Spark

---

## 快速参考卡

```
查看 Java 位置:
  where java

查看 Java 版本:
  java -version

临时设置 JAVA_HOME:
  set JAVA_HOME=C:\Program Files\Java\jdk-11

验证设置:
  echo %JAVA_HOME%
  java -version

在 Python 中设置:
  import os
  os.environ['JAVA_HOME'] = r'C:\Program Files\Java\jdk-11'
```

---

## 相关资源

- [Oracle Java 下载](https://www.oracle.com/java/technologies/downloads/)
- [Windows 环境变量官方文档](https://docs.microsoft.com/windows/deployment/usmt/usmt-recognized-environment-variables)
- [PySpark 文档](https://spark.apache.org/docs/latest/api/python/)

---

*需要帮助? 查看 [WINDOWS_SPARK_SETUP.md](WINDOWS_SPARK_SETUP.md) 获取完整指南。*
