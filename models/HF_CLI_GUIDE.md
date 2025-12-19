# 使用 hf download 批量下载模型

## 🚀 快速开始

### 1. 安装 Hugging Face CLI

```bash
pip install huggingface_hub
```

### 2. 登录 Hugging Face（推荐）

```bash
huggingface-cli login
```

或设置环境变量：

```bash
export HF_TOKEN=your_huggingface_token
```

### 3. 运行下载脚本

```bash
# 赋予执行权限
chmod +x download_with_hf.sh

# 下载所有模型
./download_with_hf.sh

# 只下载指定目录
./download_with_hf.sh --dirs loras controlnet
```

## 📋 脚本说明

- **自动生成**: 脚本由 `generate_hf_download_script.py` 自动生成
- **使用命令**: `hf download`（最新的 Hugging Face CLI 命令）
- **默认目录**: `/root/dehui/models`（可通过参数修改）
- **模型数量**: 112 个 Hugging Face 模型 + 4 个其他来源模型
- **智能跳过**: 自动跳过已存在的文件
- **参数支持**: 支持通过命令行参数指定目录和路径
- **统计信息**: 显示成功/跳过/失败的数量

## 📝 命令行参数

### 基本语法

```bash
./download_with_hf.sh [选项]
```

### 可用参数

| 参数 | 简写 | 说明 | 示例 |
|------|------|------|------|
| `--dirs` | `-d` | 指定要下载的目录 | `--dirs loras controlnet` |
| `--target-dir` | `-t` | 指定下载目标目录 | `--target-dir /custom/path` |
| `--help` | `-h` | 显示帮助信息 | `--help` |

### 使用示例

```bash
# 查看帮助
./download_with_hf.sh --help

# 下载所有模型到默认目录
./download_with_hf.sh

# 只下载 loras
./download_with_hf.sh --dirs loras

# 下载多个目录
./download_with_hf.sh --dirs loras controlnet clip_vision

# 下载到自定义目录
./download_with_hf.sh --target-dir /mnt/storage/models

# 组合使用
./download_with_hf.sh \
  --dirs loras controlnet \
  --target-dir /root/dehui/models
```

## 🗂️ 可用目录

| 目录 | 模型数 | 大小估算 | 说明 |
|------|--------|----------|------|
| `audio` | 2 | ~1 GB | 音频编码器 |
| `checkpoints` | 15 | ~50 GB | 完整检查点模型 |
| `clip` | 15 | ~20 GB | CLIP 文本编码器 |
| `clip_vision` | 3 | ~2 GB | CLIP 视觉编码器 |
| `controlnet` | 7 | ~3 GB | ControlNet 模型 |
| `loras` | 19 | ~5 GB | LoRA 微调模型 |
| `style_models` | 1 | ~100 MB | 风格迁移模型 |
| `unet` | 43 | ~100 GB | UNet 核心模型 |
| `unknown` | 1 | ~100 MB | 其他模型 |
| `vae` | 9 | ~5 GB | VAE 编解码器 |

## 💡 使用场景

### 场景 1: 快速测试

```bash
# 只下载小文件验证环境（3个文件，2GB，约3分钟）
./download_with_hf.sh --dirs clip_vision
```

### 场景 2: 只下载 LoRA

```bash
# 下载 19 个 LoRA 模型（约 5GB，8分钟）
./download_with_hf.sh --dirs loras
```

### 场景 3: FLUX 完整套件

```bash
# 下载 FLUX 必需组件（约 125GB，2-3小时）
./download_with_hf.sh --dirs unet clip vae
```

### 场景 4: 轻量级组合

```bash
# 适合资源有限的环境（约 10GB）
./download_with_hf.sh --dirs loras controlnet clip_vision
```

### 场景 5: 分批下载

```bash
# 第一批：小文件（10-15 分钟）
./download_with_hf.sh --dirs loras controlnet clip_vision

# 第二批：中等文件（30-40 分钟）
./download_with_hf.sh --dirs clip vae

# 第三批：大文件（按需，2-3 小时）
./download_with_hf.sh --dirs unet checkpoints
```

## 🔧 高级功能

### 断点续传

脚本会自动检查文件是否已存在，如果存在则跳过。这意味着：

- 可以安全中断和重启下载
- 可以多次运行脚本补充新模型
- 不会重复下载已有文件

### 文件重命名

脚本会自动处理 Hugging Face 的目录结构，将文件移动到正确位置：

```bash
# 下载后的文件路径: split_files/audio_encoders/model.safetensors
# 自动重命名为: model.safetensors
# 并清理空目录
```

### 实时统计

下载完成后显示统计信息：

```
======================================
下载完成!
======================================
成功: 15
跳过: 10
失败: 0
总计: 25
======================================
```

## ⚠️ 其他来源模型

脚本运行后会列出 4 个来自 Civitai 的模型，需要手动下载：

1. **architecturerealmix_v11.safetensors** (checkpoints)
2. **dreamshaper_8.safetensors** (checkpoints)
3. **MoXinV1.safetensors** (loras)
4. **blindbox_v1_mix.safetensors** (loras)

这些模型会在脚本末尾显示下载链接。

## 🔄 重新生成脚本

如果需要修改脚本（如更改默认目录），可以重新生成：

```bash
# 重新生成脚本
python3 generate_hf_download_script.py

# 生成只包含指定目录的脚本
python3 generate_hf_download_script_filtered.py \
  --dirs loras controlnet \
  -o download_custom.sh
```

## 📊 `hf download` vs `huggingface-cli download`

### 为什么使用 `hf download`？

| 特性 | `hf download` | `huggingface-cli download` |
|------|---------------|----------------------------|
| 状态 | ✅ 最新推荐 | ⚠️ 已过时 |
| 命令长度 | 更短 | 更长 |
| 参数 | 更简洁（无需 `--local-dir-use-symlinks`）| 需要额外参数 |
| 功能 | 完整支持 | 功能相同 |

### 命令对比

```bash
# 新命令（推荐）- 更简洁
hf download "repo_id" "file_path" --local-dir /path --revision main

# 旧命令（已过时）- 需要额外参数
huggingface-cli download "repo_id" "file_path" \
  --local-dir /path \
  --local-dir-use-symlinks False \
  --revision main
```

### 主要区别

1. **参数简化**: `hf download` 默认不使用符号链接，无需指定 `--local-dir-use-symlinks False`
2. **命令更短**: 命令名从 `huggingface-cli` 缩短为 `hf`
3. **更现代**: 基于最新的 CLI 设计规范

## 🛠️ 故障排查

### 问题 1: 找不到 `hf` 命令

```bash
# 确保安装了最新版本
pip install --upgrade huggingface_hub
```

### 问题 2: 权限错误

```bash
# 检查目标目录权限
ls -ld /root/dehui/models

# 如果需要，创建目录
mkdir -p /root/dehui/models
```

### 问题 3: Token 认证失败

```bash
# 方式 1: 重新登录
huggingface-cli login

# 方式 2: 设置环境变量
export HF_TOKEN=your_token_here
```

### 问题 4: 下载速度慢

考虑使用镜像或代理：

```bash
# 设置镜像
export HF_ENDPOINT=https://hf-mirror.com

# 然后运行脚本
./download_with_hf.sh --dirs loras
```

### 问题 5: 磁盘空间不足

```bash
# 检查磁盘空间
df -h /root/dehui/models

# 只下载小文件
./download_with_hf.sh --dirs loras controlnet clip_vision
```

## 📖 相关文档

- `SHELL_SCRIPT_USAGE.md` - 详细使用指南
- `QUICK_REFERENCE.md` - 快速参考卡
- `HF_DOWNLOAD_EXAMPLES.md` - 更多使用示例
- `MODELS_TABLE.md` - 完整模型列表

## 💬 常见问题

### Q: 如何只下载单个模型？

使用 `--dirs` 参数指定目录，然后手动停止：

```bash
./download_with_hf.sh --dirs loras
# 等待需要的模型下载完成后按 Ctrl+C
```

### Q: 可以并发下载吗？

当前脚本是串行下载。如果需要并发，可以：

1. 分批运行多个脚本实例（不同目录）
2. 或使用 Python 脚本的并发模式

### Q: 如何查看下载进度？

`hf download` 会显示进度条，包括：
- 当前文件名
- 下载进度百分比
- 下载速度
- 预计剩余时间

### Q: 下载失败会怎样？

- 脚本会记录失败次数
- 继续下载下一个模型
- 最后显示失败统计
- 可以重新运行脚本下载失败的模型

---

**提示**: 建议先下载小文件目录（如 `loras`、`controlnet`）测试环境，确认无误后再下载大文件。
