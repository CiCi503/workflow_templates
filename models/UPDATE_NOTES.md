# 更新说明

## 🎉 重要更新：使用 `hf download` 替代 `huggingface-cli download`

### 更新日期

2024年12月

### 更新内容

所有脚本已从过时的 `huggingface-cli download` 命令更新为最新的 `hf download` 命令。

### 主要变更

#### 1. 命令更新

**旧命令**（已过时）：
```bash
huggingface-cli download "repo_id" "file_path" \
  --local-dir /path \
  --local-dir-use-symlinks False \
  --revision main
```

**新命令**（推荐）：
```bash
hf download "repo_id" "file_path" \
  --local-dir /path \
  --revision main
```

**主要变化**：
- ✅ 命令从 `huggingface-cli` 改为 `hf`（更短）
- ✅ 移除 `--local-dir-use-symlinks False` 参数（默认不使用符号链接）
- ✅ 保留 `--local-dir` 和 `--revision` 参数

#### 2. 脚本文件重命名

| 旧文件名 | 新文件名 |
|---------|---------|
| `download_with_hf_cli.sh` | `download_with_hf.sh` |

#### 3. 文档更新

所有文档已更新，反映新的命令和脚本名称：
- ✅ `SHELL_SCRIPT_USAGE.md`
- ✅ `QUICK_REFERENCE.md`
- ✅ `HF_DOWNLOAD_EXAMPLES.md`
- ✅ `HF_CLI_GUIDE.md`

### 影响范围

- **生成脚本**: `generate_hf_download_script.py`
- **过滤脚本**: `generate_hf_download_script_filtered.py`
- **下载脚本**: `download_with_hf.sh`
- **所有相关文档**

### 兼容性

- ✅ 需要 `huggingface_hub` 库（通过 `pip install huggingface_hub` 安装）
- ✅ 所有参数保持不变
- ✅ 功能完全兼容
- ✅ 现有的 Token 认证方式不变

### 迁移指南

#### 如果你之前使用旧脚本

**步骤 1**: 删除旧脚本（可选）
```bash
rm -f download_with_hf_cli.sh
```

**步骤 2**: 重新生成脚本
```bash
python3 generate_hf_download_script.py
```

**步骤 3**: 使用新脚本
```bash
chmod +x download_with_hf.sh
./download_with_hf.sh --help
```

#### 如果你在其他地方使用了命令

只需将 `huggingface-cli download` 替换为 `hf download`，其他参数完全相同。

### 为什么要更新？

1. **官方推荐**: `hf download` 是 Hugging Face 官方推荐的新命令
2. **更简洁**: 命令更短，更易记
3. **更现代**: 遵循最新的 CLI 设计规范
4. **功能相同**: 保持所有功能和参数不变

### 验证更新

检查脚本是否使用新命令：

```bash
# 查看脚本头部
head -5 download_with_hf.sh
# 应该显示: 使用 hf download 批量下载 ComfyUI 模型

# 检查命令
grep "^[[:space:]]*hf download" download_with_hf.sh | head -1
# 应该显示: hf download "..." 格式的命令
```

### 常见问题

#### Q: 旧脚本还能用吗？

可以，但不推荐。`huggingface-cli download` 仍然可用，但已被标记为过时。

#### Q: 需要重新安装依赖吗？

不需要。`hf download` 和 `huggingface-cli download` 使用相同的库（`huggingface_hub`）。

#### Q: Token 认证有变化吗？

没有变化，仍然可以使用：
- `huggingface-cli login`
- 或 `export HF_TOKEN=your_token`

#### Q: 参数有变化吗？

完全没有。所有参数（`--local-dir`、`--local-dir-use-symlinks`、`--revision` 等）保持不变。

#### Q: 性能有提升吗？

命令本身性能相同，但 `hf download` 可能会获得 Hugging Face 的未来性能优化。

### 技术细节

#### 检测命令可用性

脚本现在检测 `hf` 命令而不是 `huggingface-cli`：

```bash
# 新检测逻辑
if ! command -v hf &> /dev/null; then
    echo "错误: 未找到 hf 命令"
    echo "请运行: pip install huggingface_hub"
    exit 1
fi
```

#### 生成的命令格式

```bash
# 新格式
hf download "Comfy-Org/flux1-dev" \
  "flux1-dev.safetensors" \
  --local-dir "$TARGET_DIR/unet" \
  --local-dir-use-symlinks False \
  --revision main
```

### 更新历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2024-12 | 2.0 | 更新为 `hf download` |
| 2024-12 | 1.1 | 添加命令行参数支持 |
| 2024-12 | 1.0 | 初始版本（使用 `huggingface-cli`）|

### 相关链接

- [Hugging Face Hub 文档](https://huggingface.co/docs/huggingface_hub)
- [hf download 命令文档](https://huggingface.co/docs/huggingface_hub/guides/download)

---

**注意**: 如果你遇到任何问题，请参考 `HF_CLI_GUIDE.md` 中的故障排查部分。

