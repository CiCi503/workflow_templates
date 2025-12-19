# 国内镜像使用指南

## 🌏 问题说明

在国内访问 Hugging Face 可能会遇到网络问题。使用国内镜像 `https://hf-mirror.com` 可以解决这个问题。

## ✅ 解决方案（推荐）

### 方法 1: 配置到 shell（最方便）⭐

**脚本已自动支持从 shell 配置文件加载环境变量！**

只需在 `~/.bashrc`（或 `~/.zshrc`）中添加：

```bash
echo 'export HF_ENDPOINT="https://hf-mirror.com"' >> ~/.bashrc
source ~/.bashrc
```

然后直接运行脚本：

```bash
./download_with_hf.sh --dirs loras --target-dir /root/dehui/models
```

**优点**：
- ✅ 一次配置，所有脚本和命令都生效
- ✅ 无需修改脚本文件
- ✅ 脚本会自动加载 shell 配置

**注意**：脚本已经在开头添加了加载 shell 配置的代码，会自动从以下文件加载环境变量：
- `~/.bashrc`
- `~/.bash_profile`
- `~/.zshrc`

### 方法 2: 直接修改脚本（永久生效）

编辑 `download_with_hf.sh`，找到第 45-47 行（大约）：

```bash
# 设置 Hugging Face 镜像（国内用户）
# 如果需要使用国内镜像，取消下面一行的注释:
# export HF_ENDPOINT="https://hf-mirror.com"
```

**将第 38 行的注释去掉**（删除开头的 `#` 和空格）：

```bash
# 设置 Hugging Face 镜像（国内用户）
# 如果需要使用国内镜像，取消下面一行的注释:
export HF_ENDPOINT="https://hf-mirror.com"
```

保存后直接运行：

```bash
./download_with_hf.sh --dirs loras --target-dir /root/dehui/models
```

**优点**：
- ✅ 环境变量永久生效，不会在进程中失效
- ✅ 无需每次设置，一次修改永久有效
- ✅ 最稳定可靠

### 方法 3: 使用 sed 快速取消注释

如果不想手动编辑，可以用这个命令：

```bash
sed -i.bak '38s/# export HF_ENDPOINT=/export HF_ENDPOINT=/' download_with_hf.sh
```

然后运行：

```bash
./download_with_hf.sh --dirs loras --target-dir /root/dehui/models
```

### 方法 4: 单次命令设置（不推荐）

```bash
HF_ENDPOINT="https://hf-mirror.com" ./download_with_hf.sh --dirs loras --target-dir /root/dehui/models
```

**注意**：这种方式在某些情况下可能会在子进程中失效，导致后面的下载失败。

## ⚠️ 为什么配置了 ~/.bashrc 但脚本还是失败？

**问题原因**：
1. `~/.bashrc` 只在**交互式 shell** 中自动加载
2. 脚本执行时是**非交互式**的，默认不会读取 `~/.bashrc`
3. 所以你在终端里手动运行 `hf download` 成功，但脚本里失败

**解决方案**：
- ✅ **现在已修复**：脚本已自动添加加载 shell 配置的代码
- ✅ 直接运行脚本即可，会自动从 `~/.bashrc`、`~/.bash_profile` 或 `~/.zshrc` 加载环境变量

如果你已经在 `~/.bashrc` 中配置了 `HF_ENDPOINT`，现在可以直接使用脚本，无需其他操作！

## 🔧 快速配置脚本（一键启用镜像）

创建一个配置脚本：

```bash
cat > enable_china_mirror.sh << 'EOF'
#!/bin/bash
# 一键启用国内镜像

if [ ! -f download_with_hf.sh ]; then
    echo "错误: 找不到 download_with_hf.sh"
    exit 1
fi

# 备份原文件
cp download_with_hf.sh download_with_hf.sh.bak

# 取消注释 HF_ENDPOINT
sed -i 's/# export HF_ENDPOINT=/export HF_ENDPOINT=/' download_with_hf.sh

echo "✓ 已启用国内镜像"
echo "✓ 原文件备份为: download_with_hf.sh.bak"
echo ""
echo "现在可以直接运行:"
echo "  ./download_with_hf.sh --dirs loras --target-dir /root/dehui/models"
EOF

chmod +x enable_china_mirror.sh
```

运行配置脚本：

```bash
./enable_china_mirror.sh
```

## 📊 验证镜像是否生效

运行脚本时，应该会看到：

```
======================================
开始下载 ComfyUI 模型
======================================
使用 Hugging Face 镜像: https://hf-mirror.com
目标目录: /root/dehui/models
选择目录: loras
```

如果看到 "使用 Hugging Face 镜像" 这一行，说明镜像已启用。

## 🚀 完整使用流程（推荐）

### 首次设置

```bash
# 1. 取消注释镜像设置（任选其一）
# 方法 A: 手动编辑 download_with_hf.sh，取消第 38 行注释
# 方法 B: 使用 sed 自动修改
sed -i.bak '38s/# export HF_ENDPOINT=/export HF_ENDPOINT=/' download_with_hf.sh

# 2. 验证修改
grep "^export HF_ENDPOINT" download_with_hf.sh
# 应该输出: export HF_ENDPOINT="https://hf-mirror.com"

# 3. 确保脚本可执行
chmod +x download_with_hf.sh
```

### 日常使用

```bash
# 直接运行，无需每次设置环境变量
./download_with_hf.sh --dirs loras --target-dir /root/dehui/models
```

## 💡 故障排查

### 问题 1: 前几个下载成功，后面失败

**原因**: 环境变量在子进程中失效

**解决**: 使用方法 1 或方法 3，在脚本内部或 shell 配置中设置

### 问题 2: 仍然很慢或失败

**可能原因**:
1. 镜像站点暂时不可用
2. 本地网络问题

**解决**:
```bash
# 测试镜像连接
curl -I https://hf-mirror.com

# 如果镜像不可用，可以尝试其他镜像或 VPN
```

### 问题 3: 看不到 "使用 Hugging Face 镜像" 提示

**原因**: 环境变量未设置

**解决**:
```bash
# 检查脚本中的设置
grep -A2 "HF_ENDPOINT" download_with_hf.sh

# 确保第 38 行没有 # 注释符号
sed -n '38p' download_with_hf.sh
```

## 📋 其他可用的国内镜像

如果 `hf-mirror.com` 不可用，可以尝试其他镜像：

```bash
# 方式 1: 编辑脚本，修改第 38 行为:
export HF_ENDPOINT="https://hf-mirror.com"

# 如果有其他镜像站点，可以替换 URL
```

## 🔄 恢复默认设置

如果需要恢复使用官方 Hugging Face 地址：

```bash
# 方法 1: 注释掉镜像设置
sed -i.bak '38s/^export HF_ENDPOINT=/# export HF_ENDPOINT=/' download_with_hf.sh

# 方法 2: 从备份恢复
cp download_with_hf.sh.bak download_with_hf.sh

# 方法 3: 重新生成脚本
python3 generate_hf_download_script.py
```

## 📝 最佳实践总结

1. **最推荐**: 配置到 shell（方法 1）⭐✅
   - 一次配置，永久生效
   - 所有脚本和命令都能用
   - 脚本会自动加载配置

2. **次推荐**: 直接修改脚本（方法 2）✅
   - 不依赖 shell 配置
   - 脚本独立运行

3. **避免使用**: 命令行临时设置（方法 4）❌
   - 环境变量可能失效
   - 不稳定

**原因**：脚本现在会自动加载 shell 配置文件，所以配置到 `~/.bashrc` 是最方便的方式！

---

**提示**: 如果遇到其他问题，请检查：
- 网络连接是否正常
- 镜像站点是否可访问
- `hf` 命令是否是最新版本（`pip install --upgrade huggingface_hub`）

