# 🛠️ 工具总览

本目录提供了一套完整的工具，用于管理 ComfyUI 工作流模板所需的模型文件。

## 📦 核心工具

### 1. 模型下载工具

| 工具 | 说明 | 推荐度 | 依赖 |
|------|------|--------|------|
| `download_models_simple.py` | 简化版下载脚本 | ⭐⭐⭐⭐⭐ | 无（仅标准库） |
| `download_with_hf.sh` | Bash 下载脚本 | ⭐⭐⭐⭐ | huggingface_hub |

**快速开始:**
```bash
# 简化版（推荐）
python3 download_models_simple.py --dirs loras

# Shell 脚本版
./download_with_hf.sh --dirs loras
```

**文档:** [quick-start.md](quick-start.md), [SHELL_SCRIPT_USAGE.md](SHELL_SCRIPT_USAGE.md)

---

### 2. SHA256 验证工具 🆕

| 工具 | 说明 | 依赖 |
|------|------|------|
| `verify_models_sha256.py` | 验证模型文件完整性 | huggingface_hub, colorama(可选) |

**功能:**
- ✅ 计算本地文件 SHA256
- ✅ 从 Hugging Face 获取官方 SHA256
- ✅ 对比并报告不一致的文件
- ✅ 支持彩色输出和 JSON 导出

**快速开始:**
```bash
# 安装依赖
pip install huggingface_hub colorama

# 验证所有模型
python3 verify_models_sha256.py /path/to/models

# 验证特定目录
python3 verify_models_sha256.py /path/to/models --dir unet --verbose
```

**文档:** [VERIFY_SHA256.md](VERIFY_SHA256.md)

---

### 3. 模型查询工具

| 工具 | 说明 | 依赖 |
|------|------|------|
| `query_models.py` | 查询模型信息 | 无 |

**功能:**
- 查询特定模板所需的模型
- 查询特定目录下的所有模型
- 查询特定模型的详细信息

**快速开始:**
```bash
# 查询模板所需模型
python3 query_models.py template flux_schnell

# 查询目录下的模型
python3 query_models.py dir unet

# 查询特定模型
python3 query_models.py model flux1-dev
```

---

### 4. 模型信息提取工具

| 工具 | 说明 | 用途 |
|------|------|------|
| `extract_model_details.py` | 从模板提取模型信息 | 开发/维护 |

**功能:**
- 分析所有模板文件
- 提取模型下载地址和存储路径
- 生成 `models_data.json` 和 `MODELS_TABLE.md`

**使用:**
```bash
python3 extract_model_details.py
```

---

## 📚 数据文件

| 文件 | 说明 | 格式 |
|------|------|------|
| `models_data.json` | 模型详细信息（JSON格式） | JSON |
| `models_table.csv` | 模型列表（CSV格式） | CSV |
| `MODELS_TABLE.md` | 模型列表（Markdown格式） | Markdown |

---

## 🔧 辅助工具

| 工具 | 说明 |
|------|------|
| `generate_hf_download_script.py` | 生成下载脚本 |
| `generate_hf_download_script_filtered.py` | 生成过滤后的下载脚本 |
| `enable_china_mirror.sh` | 启用中国镜像 |

---

## 📖 文档索引

### 快速入门

- [quick-start.md](quick-start.md) - 快速开始指南 ⭐
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - 命令速查卡 ⭐
- [verify_example.sh](verify_example.sh) - SHA256 验证示例

### 详细文档

- [VERIFY_SHA256.md](VERIFY_SHA256.md) - SHA256 验证工具文档 🆕
- [SHELL_SCRIPT_USAGE.md](SHELL_SCRIPT_USAGE.md) - Shell 脚本使用说明
- [CHINA_MIRROR_GUIDE.md](CHINA_MIRROR_GUIDE.md) - 中国镜像使用指南
- [RETRY_GUIDE.md](RETRY_GUIDE.md) - 重试和错误处理指南
- [ENVIRONMENT_FIX.md](ENVIRONMENT_FIX.md) - 环境问题修复
- [UPDATE_NOTES.md](UPDATE_NOTES.md) - 更新日志

---

## 🚀 典型工作流

### 工作流 1: 首次下载并验证

```bash
# 1. 预览将要下载的内容
python3 download_models_simple.py --dry-run --dirs unet

# 2. 下载模型
python3 download_models_simple.py --dirs unet

# 3. 验证完整性
python3 verify_models_sha256.py ./models --dir unet

# 4. 如有损坏，重新下载
python3 download_models_simple.py --dirs unet
```

### 工作流 2: 查询并下载特定模板所需模型

```bash
# 1. 查询模板所需模型
python3 query_models.py template flux_schnell

# 2. 根据输出，下载对应目录
python3 download_models_simple.py --dirs checkpoints clip vae

# 3. 验证下载的模型
python3 verify_models_sha256.py ./models
```

### 工作流 3: 定期验证和维护

```bash
# 1. 定期运行验证
python3 verify_models_sha256.py /path/to/models --output weekly_check.json

# 2. 如发现损坏文件，删除并重新下载
rm /path/to/models/loras/damaged_file.safetensors
python3 download_models_simple.py --dirs loras
```

---

## 💡 使用建议

### 下载策略

1. **按需下载** - 只下载需要的模型（推荐）
   ```bash
   python3 query_models.py template <你的模板>
   python3 download_models_simple.py --dirs <需要的目录>
   ```

2. **分批下载** - 从小到大逐步下载（稳定）
   ```bash
   python3 download_models_simple.py --dirs audio clip_vision  # 小文件
   python3 download_models_simple.py --dirs loras controlnet   # 中文件
   python3 download_models_simple.py --dirs unet               # 大文件
   ```

3. **一次性下载** - 下载所有模型（简单但耗时）
   ```bash
   python3 download_models_simple.py
   ```

### 验证时机

- ✅ **下载完成后** - 立即验证
- ✅ **定期检查** - 每周或每月验证一次
- ✅ **出现问题时** - 模型加载失败时验证
- ✅ **迁移后** - 复制或移动文件后验证

### 性能优化

- 大文件下载建议使用串行模式（稳定）
- 小文件下载可使用并发模式（快速）
  ```bash
  python3 download_models_simple.py --parallel --workers 5 --dirs loras
  ```
- 验证大量文件时使用 `--dir` 参数分批验证

---

## ❓ 常见问题

### Q: 应该先用哪个工具？

**A:** 建议顺序：
1. `query_models.py` - 查询需要哪些模型
2. `download_models_simple.py` - 下载模型
3. `verify_models_sha256.py` - 验证完整性

### Q: 如何知道我需要下载哪些模型？

**A:** 使用查询工具：
```bash
python3 query_models.py template <模板名>
```

### Q: 下载中断了怎么办？

**A:** 直接重新运行相同命令，会自动跳过已下载的文件。

### Q: 如何确认文件下载正确？

**A:** 使用 SHA256 验证工具：
```bash
python3 verify_models_sha256.py /path/to/models
```

### Q: 某个文件损坏了怎么办？

**A:**
```bash
# 1. 删除损坏的文件
rm /path/to/damaged_file.safetensors

# 2. 重新下载该目录
python3 download_models_simple.py --dirs <目录名>

# 3. 再次验证
python3 verify_models_sha256.py /path/to/models --dir <目录名>
```

---

## 🔗 相关链接

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- [Hugging Face](https://huggingface.co/)
- [模板仓库根目录](../)

---

## 📝 贡献

如果你发现问题或有改进建议：

1. 提交 Issue
2. 发起 Pull Request
3. 在讨论区分享经验

---

**最后更新:** 2024年12月20日

