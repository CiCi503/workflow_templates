# 模型 SHA256 验证工具

这个工具可以帮助你验证下载的 ComfyUI 模型文件是否完整正确。

## 功能特性

✅ 自动扫描指定目录下的所有模型文件  
✅ 计算本地文件的 SHA256 哈希值  
✅ 从 Hugging Face 获取远程文件的 SHA256  
✅ 比较并报告不一致的文件  
✅ 支持彩色输出（需要 colorama）  
✅ 可导出 JSON 格式的验证报告  

## 安装依赖

```bash
pip install huggingface_hub colorama
```

或者只安装必需依赖：

```bash
pip install huggingface_hub
```

## 使用方法

### 1. 验证所有模型文件

```bash
python3 verify_models_sha256.py /path/to/models
```

### 2. 只验证特定子目录

验证 unet 目录：
```bash
python3 verify_models_sha256.py /path/to/models --dir unet
```

验证 loras 目录：
```bash
python3 verify_models_sha256.py /path/to/models --dir loras
```

### 3. 显示详细信息

```bash
python3 verify_models_sha256.py /path/to/models --verbose
```

### 4. 导出验证报告

```bash
python3 verify_models_sha256.py /path/to/models --output report.json
```

### 5. 组合使用

```bash
python3 verify_models_sha256.py /path/to/models --dir unet --verbose --output unet_report.json
```

## 输出示例

```
================================================================================
🔍 ComfyUI 模型 SHA256 验证工具
================================================================================

📋 加载模型映射...
   找到 126 个模型的信息

🔎 扫描目录: /root/dehui/models
   找到 15 个模型文件

[1/15] 验证: unet/flux1-dev-fp8.safetensors

================================================================================
📁 目录: unet
📄 文件: flux1-dev-fp8.safetensors
================================================================================
本地 SHA256:  a8a2c87f2ad5e6a3b9c8d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2
远程 SHA256:  a8a2c87f2ad5e6a3b9c8d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2
✅ 状态: 一致 - 文件完整

...

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

## 常见问题

### Q: 提示"未找到下载 URL"

**A:** 这表示该模型文件在 `models_data.json` 中没有记录。可能原因：
- 模型是手动下载的，不在项目模板中
- 模型文件名与记录不匹配
- 需要先运行 `extract_model_details.py` 生成模型映射

### Q: 提示"无法从 Hugging Face 获取 SHA256"

**A:** 可能原因：
- 网络连接问题
- 需要 Hugging Face Token（某些私有仓库）
- 文件在 Hugging Face 上已删除或移动

解决方法：
```bash
# 设置 HF Token
export HF_TOKEN=your_token_here
# 或
huggingface-cli login

# 使用国内镜像
export HF_ENDPOINT="https://hf-mirror.com"
```

### Q: 验证速度很慢

**A:** 计算大文件的 SHA256 需要时间，这是正常的。对于多 GB 的模型文件，可能需要几分钟。

使用 `--dir` 参数可以只验证特定目录，减少验证时间：
```bash
python3 verify_models_sha256.py /path/to/models --dir unet
```

### Q: 某些文件显示"无法解析 URL (非 Hugging Face 链接)"

**A:** 这个工具目前只支持验证从 Hugging Face 下载的模型。对于来自 Civitai 等其他平台的模型，暂时无法自动验证。

## 目录结构

脚本会扫描以下常见的 ComfyUI 模型目录：

```
models/
├── checkpoints/
├── clip/
├── clip_vision/
├── controlnet/
├── loras/
├── unet/
├── vae/
├── upscale_models/
├── audio/
├── sams/
└── style_models/
```

## 重新下载损坏的模型

验证脚本会列出所有 SHA256 不一致的文件。你可以：

### 方法 1: 使用下载脚本重新下载

```bash
# 删除损坏的文件
rm /path/to/models/loras/some_lora.safetensors

# 重新运行下载脚本
./download_with_hf.sh --dirs loras
```

### 方法 2: 手动下载

根据 `models_table.csv` 或 `models_data.json` 中的 URL，手动重新下载对应的文件。

## 技术细节

### SHA256 计算

脚本使用 Python 的 `hashlib.sha256()` 计算本地文件的哈希值，使用 8MB 缓冲区以提高性能。

### 远程 SHA256 获取

1. 首先尝试通过 Hugging Face API (`/api/models/{repo_id}/tree/{revision}`) 获取 LFS 文件的 SHA256
2. 如果失败，尝试使用 `huggingface_hub` 库的 `get_hf_file_metadata()` 方法
3. 从返回的 metadata 中提取 SHA256 信息

### 支持的文件格式

- `.safetensors`
- `.ckpt`
- `.pt`
- `.pth`
- `.bin`

## 贡献

如果你发现 bug 或有改进建议，欢迎提交 Issue 或 PR。

## 相关工具

- `extract_model_details.py` - 提取模板中的模型信息
- `generate_hf_download_script.py` - 生成下载脚本
- `download_with_hf.sh` - 批量下载脚本
- `query_models.py` - 查询模型信息

