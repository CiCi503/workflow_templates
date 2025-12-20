# 🚀 快速开始 - 下载模型

## 📌 推荐使用简化版脚本（无需安装依赖）

我们提供了 **两个版本** 的下载脚本：

1. **download_models_simple.py** ⭐ 推荐 - 只使用 Python 标准库，无需安装任何依赖
2. **download_models.py** - 功能更丰富，需要安装 requests 和 tqdm

## ⚡ 超快速上手（4 步）

### 步骤 0: 设置 Hugging Face Token

```bash
# 设置环境变量
export HF_TOKEN=your_huggingface_token_here

# 或者在运行时设置
HF_TOKEN=your_token python3 download_models_simple.py --dry-run
```

> 💡 如何获取 Token: 登录 [Hugging Face](https://huggingface.co/settings/tokens) → Settings → Access Tokens → 创建新 Token

### 步骤 1: 预览将要下载什么

```bash
python3 download_models_simple.py --dry-run
```

这会显示所有 116 个有下载链接的模型。

### 步骤 2: 先下载小文件测试（约 1GB）

```bash
python3 download_models_simple.py --dirs audio clip_vision
```

下载 5 个较小的模型文件，测试脚本是否正常工作。

### 步骤 3: 下载所有模型

```bash
python3 download_models_simple.py
```

会下载所有 116 个模型到当前目录的各个子目录中。

## 📋 常用命令

### 下载特定类型的模型

```bash
# 只下载 FLUX 相关模型（最常用）
python3 download_models_simple.py --dirs unet clip vae

# 只下载 LoRA 模型
python3 download_models_simple.py --dirs loras

# 只下载 ControlNet
python3 download_models_simple.py --dirs controlnet

# 下载多个目录
python3 download_models_simple.py --dirs unet clip vae loras
```

### 下载到 ComfyUI 目录

```bash
# 假设 ComfyUI 安装在 ~/ComfyUI
python3 download_models_simple.py --output ~/ComfyUI/models

# 或者指定完整路径
python3 download_models_simple.py --output /path/to/ComfyUI/models
```

### 断点续传

如果下载中断，直接再次运行相同命令即可：

```bash
# 会自动从中断的地方继续下载
python3 download_models_simple.py
```

### ⚡ 并发下载（加速）

启用并发下载可以显著提升下载速度，特别是下载多个小文件时：

```bash
# 使用默认3个线程并发下载
python3 download_models_simple.py --parallel

# 指定5个线程并发下载
python3 download_models_simple.py --parallel --workers 5

# 并发下载特定目录
python3 download_models_simple.py --parallel --dirs loras controlnet

# 推荐：下载小文件时使用更多线程
python3 download_models_simple.py --parallel --workers 8 --dirs loras clip
```

**⚠️ 注意事项：**
- 下载大文件（如 UNET 模型）时，并发优势不明显，建议使用默认串行模式
- 线程数不宜过多（建议 3-8 个），过多可能导致网络拥塞或触发服务器限流
- 并发下载会同时进行多个文件的下载，进度显示可能交错

**推荐配置：**
- 小文件（LoRA、ControlNet）：`--parallel --workers 5-8`
- 中等文件（CLIP、VAE）：`--parallel --workers 3-5`
- 大文件（UNET、Checkpoint）：不使用 `--parallel`（串行更稳定）

## 📊 预期下载量

根据你选择的目录不同，下载量也不同：

| 目录组合 | 大小估算 | 用途 |
|----------|----------|------|
| `audio clip_vision` | ~1 GB | 测试下载 |
| `loras controlnet` | ~5 GB | 轻量级模型 |
| `clip vae` | ~30 GB | 中等大小 |
| `checkpoints` | ~50 GB | 检查点模型 |
| `unet` | ~100+ GB | 大型模型 |
| 所有目录 | ~200+ GB | 全部模型 |

## ⏱️ 预计下载时间

以 10 MB/s 网速为例：

- 小型测试（1GB）: ~2 分钟
- 轻量级（5GB）: ~10 分钟
- 中等（30GB）: ~50 分钟
- 大型（50GB）: ~1.5 小时
- 完整（200GB）: ~5-6 小时

## 🎯 推荐下载策略

### 策略 1: 按需下载（最省空间）

只下载你要使用的工作流需要的模型：

```bash
# 查询特定工作流需要的模型
python3 query_models.py template flux_schnell

# 然后只下载对应目录的模型
python3 download_models_simple.py --dirs checkpoints
```

### 策略 2: 分批下载（最稳定）

从小到大逐步下载：

```bash
# 第1批: 小文件（1GB）
python3 download_models_simple.py --dirs audio clip_vision controlnet

# 第2批: 中等文件（30GB）
python3 download_models_simple.py --dirs clip loras vae

# 第3批: 大文件（50GB）
python3 download_models_simple.py --dirs checkpoints

# 第4批: 超大文件（100GB）
python3 download_models_simple.py --dirs unet
```

### 策略 3: 一次性下载（最简单）

如果磁盘空间足够（200GB+）且网络稳定：

```bash
python3 download_models_simple.py
```

## 💡 使用技巧

### 1. 查看将要下载的具体文件

```bash
python3 download_models_simple.py --dry-run --dirs unet
```

### 2. 中途暂停

按 `Ctrl+C` 停止下载，已下载的部分会保留。

### 3. 恢复下载

直接运行相同的命令，会自动跳过已下载的文件，继续下载剩余的。

### 4. 强制重新下载某个文件

```bash
# 删除该文件，然后重新下载
rm unet/flux1-dev-fp8.safetensors
python3 download_models_simple.py --dirs unet
```

## ⚠️ 重要提示

### ✅ 下载前检查

- [ ] 磁盘空间是否充足（至少 200GB）
- [ ] 网络连接是否稳定
- [ ] 是否有足够的下载时间

### 🌐 网络问题

如果 Hugging Face 访问慢或无法访问，可以：

1. **使用代理**:
   ```bash
   export HTTP_PROXY=http://127.0.0.1:7890
   export HTTPS_PROXY=http://127.0.0.1:7890
   python3 download_models_simple.py
   ```

2. **使用 Hugging Face 镜像**（需要修改脚本中的 URL）

3. **手动下载**重要文件，查看 `MODELS_TABLE.md` 获取下载链接

### 📁 目录结构

下载后会在当前目录创建以下结构：

```
./
├── audio/
│   ├── wav2vec2_large_english_fp16.safetensors
│   └── whisper_large_v3_fp16.safetensors
├── checkpoints/
│   ├── 512-inpainting-ema.safetensors
│   └── ...
├── clip/
│   ├── clip_l.safetensors
│   └── ...
├── clip_vision/
├── controlnet/
├── loras/
├── unet/
│   ├── flux1-dev-fp8.safetensors
│   └── ...
└── vae/
```

## 🔄 更新模型

如果 CSV 文件更新了（添加了新模型），只需重新运行：

```bash
python3 download_models_simple.py
```

已存在的文件会自动跳过，只下载新增的模型。

## 📞 获取帮助

```bash
# 查看所有命令选项
python3 download_models_simple.py --help

# 查询特定模板需要的模型
python3 query_models.py template <模板名>

# 查看特定目录的模型列表
python3 query_models.py dir unet
```

## ✅ 验证模型完整性（重要！）

下载完成后，强烈建议验证文件的 SHA256 哈希值，确保文件没有损坏或下载不完整。

### 安装验证工具依赖

```bash
pip install huggingface_hub colorama
```

### 验证所有模型

```bash
python3 verify_models_sha256.py /path/to/models
```

### 验证特定目录

```bash
# 只验证 unet 目录
python3 verify_models_sha256.py /path/to/models --dir unet

# 验证多个目录
python3 verify_models_sha256.py /path/to/models --dir loras --verbose
```

### 验证输出示例

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

### 重新下载损坏的文件

如果发现文件损坏：

```bash
# 删除损坏的文件
rm /path/to/models/loras/damaged_file.safetensors

# 重新下载该目录
python3 download_models_simple.py --dirs loras
```

**💡 建议流程：**

1. 下载模型 → `python3 download_models_simple.py --dirs unet`
2. 验证完整性 → `python3 verify_models_sha256.py /path/to/models --dir unet`
3. 如有损坏，重新下载 → `python3 download_models_simple.py --dirs unet`

详细说明请查看: [VERIFY_SHA256.md](VERIFY_SHA256.md)

## 🎉 下载完成后

1. **验证文件**: 运行 SHA256 验证（见上方）
2. **移动文件**: 如果需要，移动到 ComfyUI 的 models 目录
3. **测试工作流**: 在 ComfyUI 中测试相关工作流

---

**提示**: 建议先用 `--dry-run` 预览，确认无误后再开始实际下载！

