# SHA256 模型验证工具 - 使用指南

## 🎯 功能

这个工具可以帮你验证下载的 ComfyUI 模型文件是否完整正确，避免因文件损坏导致的各种问题。

## 📋 快速开始（3步）

### 步骤 1: 安装依赖

```bash
pip install huggingface_hub colorama
```

如果不需要彩色输出，可以只安装：
```bash
pip install huggingface_hub
```

### 步骤 2: 运行验证

```bash
# 替换为你的模型目录
python3 verify_models_sha256.py /root/dehui/models
```

### 步骤 3: 处理结果

脚本会自动列出 SHA256 不一致的文件，删除并重新下载即可。

```bash
# 删除损坏的文件
rm /path/to/damaged_file.safetensors

# 重新下载
./download_with_hf.sh --dirs loras
```

---

## 🔍 使用场景

### 场景 1: 下载后验证（推荐）

```bash
# 1. 下载模型
python3 download_models_simple.py --dirs unet

# 2. 立即验证
python3 verify_models_sha256.py ./models --dir unet
```

### 场景 2: 验证特定目录

```bash
# 只验证 loras 目录
python3 verify_models_sha256.py /root/dehui/models --dir loras

# 显示详细信息
python3 verify_models_sha256.py /root/dehui/models --dir loras --verbose
```

### 场景 3: 批量验证并生成报告

```bash
# 验证所有文件并导出报告
python3 verify_models_sha256.py /root/dehui/models --output report.json

# 验证特定目录并导出
python3 verify_models_sha256.py /root/dehui/models --dir unet --output unet_report.json
```

### 场景 4: 定期检查（推荐每周一次）

```bash
# 创建定期检查脚本
cat > weekly_check.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d)
python3 verify_models_sha256.py /root/dehui/models --output check_${DATE}.json
EOF

chmod +x weekly_check.sh
./weekly_check.sh
```

---

## 📊 输出解读

### 成功示例

```
================================================================================
📁 目录: unet
📄 文件: flux1-dev-fp8.safetensors
================================================================================
本地 SHA256:  a8a2c87f2ad5e6a3b9c8d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2
远程 SHA256:  a8a2c87f2ad5e6a3b9c8d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2
✅ 状态: 一致 - 文件完整
```

### 失败示例

```
================================================================================
📁 目录: loras
📄 文件: some_lora.safetensors
================================================================================
本地 SHA256:  1234567890abcdef...
远程 SHA256:  fedcba0987654321...
❌ 状态: 不一致 - 文件可能损坏
```

### 总结报告

```
================================================================================
📊 验证总结
================================================================================
总文件数: 15
✅ 一致:   13
❌ 不一致: 2
⚠️  错误:   0

⚠️  以下文件 SHA256 不一致，建议重新下载:
================================================================================
  • loras/some_lora.safetensors
  • vae/some_vae.safetensors
```

---

## 🛠️ 高级用法

### 批量验证多个目录

```bash
#!/bin/bash
# 依次验证多个目录
for dir in unet loras vae clip; do
    echo "验证 $dir 目录..."
    python3 verify_models_sha256.py /root/dehui/models --dir $dir
done
```

### 自动修复损坏的文件

```bash
#!/bin/bash
# 验证并自动重新下载损坏的文件（仅示例，需根据实际情况修改）

# 1. 验证并保存结果
python3 verify_models_sha256.py /root/dehui/models --output report.json

# 2. 解析 JSON，找出损坏的文件（需要 jq）
# jq -r '.[] | select(.match == false) | .dir' report.json | sort -u

# 3. 手动检查并重新下载对应目录
```

### 与下载脚本集成

```bash
#!/bin/bash
# 下载后自动验证的脚本

DIRS=$1  # 传入要下载的目录，如 "unet"
MODEL_PATH="/root/dehui/models"

# 下载
echo "下载 $DIRS 目录..."
./download_with_hf.sh --dirs $DIRS --target-dir $MODEL_PATH

# 验证
echo "验证 $DIRS 目录..."
python3 verify_models_sha256.py $MODEL_PATH --dir $DIRS

# 检查验证结果
if [ $? -eq 0 ]; then
    echo "✅ 验证通过"
else
    echo "❌ 验证失败，请检查输出"
fi
```

---

## ⚠️ 注意事项

### 1. 验证速度

- **小文件**（几百 MB）: 几秒钟
- **中等文件**（1-5 GB）: 1-3 分钟
- **大文件**（10+ GB）: 5-15 分钟

计算 SHA256 需要读取整个文件，大文件会比较慢，这是正常的。

### 2. 网络要求

脚本需要从 Hugging Face 获取远程 SHA256 信息，确保：
- 可以访问 Hugging Face
- 或配置了 HF 镜像环境变量

```bash
# 使用国内镜像
export HF_ENDPOINT="https://hf-mirror.com"
python3 verify_models_sha256.py /root/dehui/models
```

### 3. 支持的模型

目前只支持验证从 **Hugging Face** 下载的模型。

来自其他平台（如 Civitai）的模型会显示错误信息，但不影响其他文件的验证。

### 4. Token 设置（可选）

某些私有仓库需要 Hugging Face Token：

```bash
export HF_TOKEN=your_token_here
python3 verify_models_sha256.py /root/dehui/models
```

---

## 🐛 常见问题

### Q1: 提示 "未找到下载 URL"

**原因:** 该模型不在 `models_data.json` 中。

**解决:**
1. 确保已运行 `extract_model_details.py` 生成最新的 `models_data.json`
2. 确认文件名与 CSV 中的记录完全一致（包括大小写）

### Q2: 提示 "无法从 Hugging Face 获取 SHA256"

**原因:** 网络问题或文件不在 Hugging Face 上。

**解决:**
1. 检查网络连接
2. 设置 HF_ENDPOINT 环境变量
3. 确认文件确实存在于 Hugging Face

### Q3: 验证很慢

**原因:** 计算大文件的 SHA256 需要时间。

**建议:**
- 使用 `--dir` 参数分批验证
- 在后台运行验证任务
- 验证时避免同时进行其他磁盘密集型操作

### Q4: 如何只验证新下载的文件？

**方法:** 使用 `--dir` 参数只验证特定目录：

```bash
# 只验证刚下载的 loras 目录
python3 verify_models_sha256.py /root/dehui/models --dir loras
```

---

## 📚 相关文档

- [VERIFY_SHA256.md](VERIFY_SHA256.md) - 完整文档
- [TOOLS_OVERVIEW.md](TOOLS_OVERVIEW.md) - 工具总览
- [quick-start.md](quick-start.md) - 快速开始
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - 命令速查

---

## 🎯 推荐工作流

### 完整流程（推荐）

```bash
# 1. 查询需要的模型
python3 query_models.py template your_template

# 2. 下载模型
python3 download_models_simple.py --dirs unet loras

# 3. 验证完整性
python3 verify_models_sha256.py ./models

# 4. 如有损坏，重新下载
python3 download_models_simple.py --dirs <损坏文件所在目录>

# 5. 再次验证
python3 verify_models_sha256.py ./models --dir <目录>
```

### 日常维护

```bash
# 每周运行一次
python3 verify_models_sha256.py /root/dehui/models --output weekly_$(date +%Y%m%d).json
```

---

**提示:** 建议在每次下载完成后立即运行验证，确保文件完整性！

