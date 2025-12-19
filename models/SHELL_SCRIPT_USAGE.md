# Shell 脚本使用指南

## 🎯 新功能

`download_with_hf_cli.sh` 现在支持通过命令行参数指定要下载的目录！

## 📋 基本用法

### 1. 下载所有模型（默认行为）

```bash
./download_with_hf_cli.sh
```

这会下载所有 112 个 Hugging Face 模型到 `/root/dehui/models`。

### 2. 只下载指定目录

```bash
# 只下载 loras 和 controlnet
./download_with_hf_cli.sh --dirs loras controlnet

# 使用短选项
./download_with_hf_cli.sh -d loras controlnet

# 只下载 FLUX 核心组件
./download_with_hf_cli.sh --dirs unet clip vae
```

### 3. 自定义目标目录

```bash
# 下载到自定义路径
./download_with_hf_cli.sh --target-dir /custom/path

# 组合使用：指定目录和目标路径
./download_with_hf_cli.sh \
  --dirs loras controlnet \
  --target-dir /root/dehui/models
```

### 4. 查看帮助

```bash
./download_with_hf_cli.sh --help
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

## 💡 实用示例

### 场景 1: 快速开始（小文件测试）

```bash
# 下载小文件，快速验证环境（约 10GB，15 分钟）
./download_with_hf_cli.sh --dirs loras controlnet clip_vision
```

### 场景 2: FLUX 开发环境

```bash
# 下载 FLUX 必需组件（约 125GB，3-4 小时）
./download_with_hf_cli.sh --dirs unet clip vae
```

### 场景 3: 只要 LoRA

```bash
# 只下载 LoRA 模型（19 个，约 5GB，8 分钟）
./download_with_hf_cli.sh --dirs loras
```

### 场景 4: 轻量级套装

```bash
# 适合资源有限的环境（约 10GB）
./download_with_hf_cli.sh --dirs loras controlnet clip_vision
```

### 场景 5: 分批下载

```bash
# 第一批：小文件（快速测试）
./download_with_hf_cli.sh --dirs loras controlnet clip_vision

# 第二批：中等文件
./download_with_hf_cli.sh --dirs clip vae

# 第三批：大文件（需要时间）
./download_with_hf_cli.sh --dirs unet checkpoints
```

### 场景 6: 自定义安装路径

```bash
# 下载到自定义路径
./download_with_hf_cli.sh \
  --dirs loras controlnet \
  --target-dir /mnt/storage/comfyui/models
```

## 🔧 高级选项

### 组合多个参数

```bash
# 完整示例：指定目录和目标路径
./download_with_hf_cli.sh \
  --dirs loras controlnet unet \
  --target-dir /custom/models
```

### 使用短选项

```bash
# -d 代替 --dirs，-t 代替 --target-dir
./download_with_hf_cli.sh -d loras controlnet -t /custom/path
```

## ⚠️ 注意事项

### 1. 目录名称必须完全匹配

```bash
# ✓ 正确
./download_with_hf_cli.sh --dirs loras controlnet

# ✗ 错误（会提示错误）
./download_with_hf_cli.sh --dirs lora control_net
```

### 2. 自动跳过已存在的文件

脚本会自动检查目标文件是否存在，如果存在则跳过下载。这意味着：
- 可以安全地中断和重启下载
- 可以多次运行脚本补充新模型
- 不会重复下载已有文件

### 3. 需要先设置 HF Token

```bash
# 方式 1: 登录
huggingface-cli login

# 方式 2: 环境变量
export HF_TOKEN=your_token_here
./download_with_hf_cli.sh --dirs loras
```

## 📊 参数对比

| 功能 | 命令 |
|------|------|
| 下载所有模型 | `./download_with_hf_cli.sh` |
| 下载单个目录 | `./download_with_hf_cli.sh --dirs loras` |
| 下载多个目录 | `./download_with_hf_cli.sh --dirs loras controlnet` |
| 自定义路径 | `./download_with_hf_cli.sh --target-dir /path` |
| 查看帮助 | `./download_with_hf_cli.sh --help` |

## 🚀 推荐下载策略

### 策略 1: 按大小分批（推荐）

```bash
# 阶段 1: 小文件（10-15 分钟）
./download_with_hf_cli.sh --dirs loras controlnet clip_vision

# 阶段 2: 中等文件（30-40 分钟）
./download_with_hf_cli.sh --dirs clip vae

# 阶段 3: 大文件（按需，2-3 小时）
./download_with_hf_cli.sh --dirs unet checkpoints
```

### 策略 2: 按功能分批

```bash
# 基础组件
./download_with_hf_cli.sh --dirs clip vae

# 扩展功能
./download_with_hf_cli.sh --dirs loras controlnet

# 核心模型
./download_with_hf_cli.sh --dirs unet
```

### 策略 3: 按用途分批

```bash
# 文本生成相关
./download_with_hf_cli.sh --dirs clip unet vae

# 图像控制相关
./download_with_hf_cli.sh --dirs controlnet loras

# 多模态相关
./download_with_hf_cli.sh --dirs clip_vision audio
```

## 🔄 与旧版本对比

### 旧版本（无参数）

```bash
# 只能下载所有模型，或者手动编辑脚本
./download_with_hf_cli.sh
```

### 新版本（支持参数）

```bash
# 灵活指定要下载的目录
./download_with_hf_cli.sh --dirs loras controlnet

# 自定义目标路径
./download_with_hf_cli.sh --target-dir /custom/path

# 查看帮助
./download_with_hf_cli.sh --help
```

## 🆚 两种下载方式对比

### 方式 1: Shell 脚本（本方式）

```bash
./download_with_hf_cli.sh --dirs loras controlnet
```

**优点:**
- ✓ 使用官方 `huggingface-cli` 工具
- ✓ 下载速度快，断点续传
- ✓ 命令行参数灵活方便
- ✓ 无需 Python 依赖

**缺点:**
- ✗ 需要安装 `huggingface_hub`
- ✗ 只支持 Hugging Face 模型

### 方式 2: Python 脚本

```bash
python3 download_models_simple.py -o /root/dehui/models --parallel
```

**优点:**
- ✓ 支持所有来源（HF + Civitai）
- ✓ 无需额外依赖
- ✓ 支持并发下载

**缺点:**
- ✗ 速度相对较慢
- ✗ 不支持按目录过滤（需修改脚本）

## 💬 常见问题

### Q1: 如何只下载单个目录？

```bash
./download_with_hf_cli.sh --dirs loras
```

### Q2: 如何下载多个目录？

```bash
./download_with_hf_cli.sh --dirs loras controlnet clip
```

### Q3: 如何修改下载目录？

```bash
./download_with_hf_cli.sh --target-dir /your/custom/path
```

### Q4: 如何查看所有可用目录？

```bash
./download_with_hf_cli.sh --help
```

### Q5: 下载中断了怎么办？

直接重新运行相同的命令，脚本会自动跳过已下载的文件。

### Q6: 可以同时指定目录和路径吗？

可以！

```bash
./download_with_hf_cli.sh \
  --dirs loras controlnet \
  --target-dir /custom/path
```

### Q7: 目录名称区分大小写吗？

是的，必须使用小写，并且完全匹配：
- ✓ `loras`
- ✗ `Loras` 或 `LORAS`

### Q8: 如何验证参数是否正确？

运行后会立即显示选择的目录：

```
======================================
开始下载 ComfyUI 模型
======================================
目标目录: /root/dehui/models
选择目录: loras controlnet
```

如果参数错误，脚本会提示并退出。

## 🎓 学习路径

### 初学者

```bash
# 1. 先看帮助
./download_with_hf_cli.sh --help

# 2. 测试下载小文件
./download_with_hf_cli.sh --dirs clip_vision

# 3. 下载常用组件
./download_with_hf_cli.sh --dirs loras controlnet
```

### 进阶用户

```bash
# 按需组合目录
./download_with_hf_cli.sh --dirs unet clip vae loras

# 自定义路径
./download_with_hf_cli.sh \
  --dirs loras controlnet \
  --target-dir /mnt/ssd/models
```

### 高级用户

```bash
# 脚本化批量下载
for dir in loras controlnet clip; do
    ./download_with_hf_cli.sh --dirs $dir
    echo "完成: $dir"
done
```

---

**提示**: 建议先下载小文件目录（如 `loras`、`controlnet`）进行测试，确认环境配置正确后再下载大文件。

