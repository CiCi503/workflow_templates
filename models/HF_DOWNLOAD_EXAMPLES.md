# huggingface-cli 下载示例

## 🎯 按目录下载模型

### 方法 1: 使用过滤脚本生成器（推荐）

```bash
# 只下载 loras 和 controlnet
python3 generate_hf_download_script_filtered.py \
  --dirs loras controlnet \
  -o download_loras_controlnet.sh

chmod +x download_loras_controlnet.sh
./download_loras_controlnet.sh
```

### 方法 2: 单个命令直接下载

如果你只想下载几个模型，可以直接使用 `huggingface-cli` 命令：

```bash
# 下载单个文件
huggingface-cli download "Comfy-Org/flux1-dev" \
  "flux1-dev.safetensors" \
  --local-dir /root/dehui/models/unet \
  --local-dir-use-symlinks False
```

## 📋 常用目录组合

### 小文件组合（约 10GB）

```bash
# 生成脚本
python3 generate_hf_download_script_filtered.py \
  --dirs audio clip_vision controlnet loras \
  -o download_small_files.sh

# 运行
chmod +x download_small_files.sh
./download_small_files.sh
```

### FLUX 完整套件

```bash
# FLUX 需要的所有模型
python3 generate_hf_download_script_filtered.py \
  --dirs unet clip vae \
  -o download_flux.sh

./download_flux.sh
```

### 只下载 LoRA

```bash
python3 generate_hf_download_script_filtered.py \
  --dirs loras \
  -o download_loras_only.sh

./download_loras_only.sh
```

### 只下载 UNET（大文件）

```bash
python3 generate_hf_download_script_filtered.py \
  --dirs unet \
  -o download_unet_only.sh

./download_unet_only.sh
```

## 🔧 高级选项

### 自定义目标目录

```bash
python3 generate_hf_download_script_filtered.py \
  --dirs loras \
  --target-dir /custom/path \
  -o download_custom.sh
```

### 查看可用目录

```bash
# 查看 CSV 中有哪些目录
cut -d',' -f1 models_table.csv | sort -u
```

输出：
```
audio
checkpoints
clip
clip_vision
controlnet
loras
sams
style_models
unet
unknown
upscale_models
vae
目录
```

## 📊 各目录模型统计

| 目录 | HF 模型数 | 大小估算 | 推荐场景 |
|------|-----------|----------|----------|
| **audio** | 2 | ~1 GB | 音频生成 |
| **checkpoints** | 15 | ~50 GB | 完整模型 |
| **clip** | 15 | ~20 GB | 文本编码 |
| **clip_vision** | 3 | ~2 GB | 视觉编码 |
| **controlnet** | 7 | ~3 GB | 控制生成 |
| **loras** | 19 | ~5 GB | 微调模型 |
| **unet** | 43 | ~100 GB | 核心模型 |
| **vae** | 9 | ~5 GB | 编解码器 |
| **其他** | 少量 | 少量 | - |

## 💡 实用组合建议

### 1. 初学者套装（约 30GB）

```bash
python3 generate_hf_download_script_filtered.py \
  --dirs clip vae loras controlnet \
  -o download_starter.sh
```

包含：文本编码器、VAE、LoRA、ControlNet

### 2. 完整 FLUX 开发环境（约 150GB）

```bash
python3 generate_hf_download_script_filtered.py \
  --dirs unet clip vae loras \
  -o download_flux_full.sh
```

### 3. 轻量级套装（约 10GB）

```bash
python3 generate_hf_download_script_filtered.py \
  --dirs loras controlnet clip_vision \
  -o download_lightweight.sh
```

### 4. 视频生成套装

```bash
python3 generate_hf_download_script_filtered.py \
  --dirs unet vae audio \
  -o download_video.sh
```

## 🚀 完整工作流示例

### 场景 1: 只想玩 LoRA

```bash
# 1. 生成 LoRA 专用脚本
python3 generate_hf_download_script_filtered.py \
  --dirs loras \
  --target-dir /root/dehui/models \
  -o download_loras.sh

# 2. 登录 HF
huggingface-cli login

# 3. 下载
chmod +x download_loras.sh
./download_loras.sh

# 结果：下载 19 个 LoRA 模型到 /root/dehui/models/loras/
```

### 场景 2: 分批下载节省时间

```bash
# 第一批：小文件（并发效果好）
python3 generate_hf_download_script_filtered.py \
  --dirs loras controlnet clip_vision \
  -o step1.sh
./step1.sh

# 第二批：中等文件
python3 generate_hf_download_script_filtered.py \
  --dirs clip vae \
  -o step2.sh
./step2.sh

# 第三批：大文件（需要时间）
python3 generate_hf_download_script_filtered.py \
  --dirs unet checkpoints \
  -o step3.sh
./step3.sh
```

### 场景 3: 快速测试环境

```bash
# 只下载必需的小文件测试
python3 generate_hf_download_script_filtered.py \
  --dirs clip_vision \
  -o test_download.sh

./test_download.sh
# 大约 1-2 分钟完成，可以测试脚本是否正常工作
```

## 🔄 与 Python 脚本对比

### huggingface-cli 方式（本方法）

```bash
# 优点：
✓ 官方工具，稳定快速
✓ 可以灵活指定目录
✓ 原生断点续传

# 使用：
python3 generate_hf_download_script_filtered.py --dirs loras controlnet
./download_xxx.sh
```

### Python 脚本方式

```bash
# 优点：
✓ 无需额外依赖
✓ 支持所有来源（HF + Civitai）
✓ 一条命令搞定

# 使用：
python3 download_models_simple.py \
  -o /root/dehui/models \
  --dirs loras controlnet \
  --parallel
```

## 📝 常见问题

### Q: 如何查看某个目录有哪些模型？

```bash
grep '"loras"' models_table.csv | cut -d',' -f2
```

### Q: 如何只下载单个模型？

```bash
# 从 CSV 中找到模型信息，然后：
huggingface-cli download "repo_id" "file_path" \
  --local-dir /target/dir \
  --local-dir-use-symlinks False
```

### Q: 下载中断了怎么办？

直接重新运行脚本，会自动跳过已下载的文件。

### Q: 如何修改下载目录？

编辑生成的 `.sh` 脚本，修改 `TARGET_DIR` 变量，或使用 `--target-dir` 参数重新生成。

## 🎨 自定义目录组合速查

```bash
# 只要文本相关
--dirs clip

# 只要视觉相关  
--dirs clip_vision unet

# 只要轻量级模型
--dirs loras controlnet

# 只要核心大模型
--dirs unet checkpoints

# FLUX 最小集
--dirs unet clip vae

# 全套（除了 unknown）
--dirs audio checkpoints clip clip_vision controlnet loras unet vae
```

---

**提示**: 
- 使用 `--dirs` 可以大大减少下载时间和存储空间
- 小文件目录（loras, controlnet）下载很快，适合先测试
- 大文件目录（unet, checkpoints）下载很慢，建议分开下载

