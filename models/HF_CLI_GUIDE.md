# 使用 huggingface-cli 下载模型

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
chmod +x download_with_hf_cli.sh

# 执行下载
./download_with_hf_cli.sh
```

## 📋 脚本说明

- **自动生成**: 脚本由 `generate_hf_download_script.py` 自动生成
- **目标目录**: `/root/dehui/models`（可在脚本开头修改 `TARGET_DIR`）
- **模型数量**: 112 个 Hugging Face 模型 + 4 个其他来源模型
- **智能跳过**: 自动跳过已存在的文件
- **统计信息**: 显示成功/跳过/失败的数量

## 🔄 修改目标目录

编辑脚本开头的 `TARGET_DIR` 变量：

```bash
# 修改这一行
TARGET_DIR="/your/custom/path"
```

或在运行时覆盖：

```bash
TARGET_DIR="/custom/path" ./download_with_hf_cli.sh
```

## 📊 下载统计

| 来源 | 数量 | 说明 |
|------|------|------|
| **Hugging Face** | 112 | 使用 huggingface-cli 下载 |
| **Civitai** | 4 | 需要手动下载 |
| **无链接** | 14 | 需要查找来源 |
| **总计** | 130 | - |

## ⚠️ 其他来源模型

以下 4 个模型来自 Civitai，需要手动下载：

1. **architecturerealmix_v11.safetensors** (checkpoints)
   ```
   https://civitai.com/api/download/models/431755?type=Model&format=SafeTensor&size=full&fp=fp16
   ```

2. **dreamshaper_8.safetensors** (checkpoints)
   ```
   https://civitai.com/api/download/models/128713?type=Model&format=SafeTensor&size=pruned&fp=fp16
   ```

3. **MoXinV1.safetensors** (loras)
   ```
   https://civitai.com/api/download/models/14856?type=Model&format=SafeTensor&size=full&fp=fp16
   ```

4. **blindbox_v1_mix.safetensors** (loras)
   ```
   https://civitai.com/api/download/models/32988?type=Model&format=SafeTensor&size=full&fp=fp16
   ```

手动下载后放到对应目录：
```bash
# 示例
wget -O /root/dehui/models/checkpoints/architecturerealmix_v11.safetensors \
  "https://civitai.com/api/download/models/431755?type=Model&format=SafeTensor&size=full&fp=fp16"
```

## 💡 优势对比

### huggingface-cli 的优势

| 特性 | huggingface-cli | download_models_simple.py |
|------|-----------------|---------------------------|
| **依赖** | 需要 huggingface_hub | 只需 Python 标准库 |
| **速度** | 较快，官方工具优化 | 中等 |
| **断点续传** | ✅ 原生支持 | ✅ 手动实现 |
| **并发下载** | ✅ 自动优化 | ✅ 可选（--parallel） |
| **进度显示** | ✅ 详细 | ✅ 基础 |
| **缓存管理** | ✅ 自动管理 | ❌ 无 |
| **适用范围** | 仅 Hugging Face | 所有来源 |

### 推荐使用场景

- **使用 huggingface-cli**: 
  - 只需要 Hugging Face 模型
  - 追求下载速度
  - 需要官方工具的稳定性

- **使用 download_models_simple.py**:
  - 需要下载所有来源的模型
  - 不想安装额外依赖
  - 需要自定义下载逻辑

## 🔧 高级用法

### 只下载特定目录

编辑脚本，注释掉不需要的部分：

```bash
# 例如只下载 audio 和 clip
# 注释掉其他目录的部分
```

### 并发下载（使用 xargs）

```bash
# 提取所有 huggingface-cli 命令
grep "^    huggingface-cli" download_with_hf_cli.sh > commands.txt

# 并发执行（4个任务）
cat commands.txt | xargs -P 4 -I {} bash -c "{}"
```

### 使用镜像站点

```bash
# 设置 Hugging Face 镜像
export HF_ENDPOINT=https://hf-mirror.com

./download_with_hf_cli.sh
```

## 🆚 两种方式对比

### 方式 1: huggingface-cli（本脚本）

```bash
# 优点
✓ 官方工具，稳定性好
✓ 下载速度快
✓ 自动管理缓存
✓ 原生断点续传

# 缺点
✗ 需要安装 huggingface_hub
✗ 仅支持 Hugging Face
✗ 4 个 Civitai 模型需要手动下载
```

### 方式 2: download_models_simple.py

```bash
# 优点
✓ 无需额外依赖
✓ 支持所有来源（HF + Civitai）
✓ 可选并发下载
✓ 自定义控制更灵活

# 缺点
✗ 速度相对较慢
✗ 需要手动实现一些功能
```

## 📝 重新生成脚本

如果 `models_table.csv` 更新了，重新生成脚本：

```bash
python3 generate_hf_download_script.py
```

可以修改脚本中的 `target_dir` 参数：

```python
# 在 generate_hf_download_script.py 中修改
generate_bash_script(csv_file, output_file, target_dir='/your/path')
```

## 🎯 推荐流程

1. **大部分模型用 huggingface-cli** (快速)
   ```bash
   ./download_with_hf_cli.sh
   ```

2. **Civitai 模型单独下载**
   ```bash
   cd /root/dehui/models
   # 下载 4 个 Civitai 模型（见上面列表）
   ```

3. **或者全用 Python 脚本** (一键全搞定)
   ```bash
   python3 download_models_simple.py -o /root/dehui/models --parallel
   ```

## ✅ 验证下载

```bash
# 检查文件数量
find /root/dehui/models -name "*.safetensors" | wc -l

# 应该有 116 个文件（112 HF + 4 Civitai）
```

---

**提示**: 两种方法都支持断点续传，可以随时中断和恢复下载。

