# 🔄 自动重试机制使用指南

## ✨ 新功能

脚本现在支持**自动重试机制**，当下载因网络问题失败时，会自动重试，大大提高下载成功率！

---

## 🎯 核心特性

### 1. **自动重试**
- 默认重试 **3 次**
- 每次重试间隔 **5 秒**
- 智能显示重试进度

### 2. **可配置**
- 可通过命令行参数自定义重试次数
- 适应不同网络环境

### 3. **友好提示**
```bash
  [1/17] 下载: Qwen-Image-Lightning-4steps-V1.0.safetensors
      🔄 重试 2/3...
      ✓ 下载完成
```

---

## 📖 使用方法

### 基础使用（使用默认重试次数）

```bash
# 下载所有模型，失败时自动重试3次
./download_with_hf.sh

# 只下载指定目录
./download_with_hf.sh --dirs loras controlnet
```

### 自定义重试次数

```bash
# 重试5次（适合网络特别不稳定的情况）
./download_with_hf.sh --retry 5

# 只重试1次（网络较好，快速失败）
./download_with_hf.sh --retry 1

# 重试10次（网络极差，需要多次尝试）
./download_with_hf.sh --retry 10
```

### 组合使用

```bash
# 下载 loras 目录，重试5次
./download_with_hf.sh --dirs loras --retry 5

# 下载到自定义目录，重试10次
./download_with_hf.sh \
  --target-dir /root/dehui/models \
  --dirs loras unet \
  --retry 10
```

---

## 🔧 工作原理

### 重试流程

```
下载尝试 1
    ↓
  失败？ → 是 → 等待 5 秒
    ↓           ↓
   否        下载尝试 2
    ↓           ↓
  成功！     失败？ → 是 → 等待 5 秒
                ↓           ↓
               否        下载尝试 3
                ↓           ↓
              成功！     失败？ → 是
                           ↓
                          标记为失败
```

### 代码示例

```bash
# 重试循环
DOWNLOAD_SUCCESS=false
for ((attempt=1; attempt<=MAX_RETRIES; attempt++)); do
    if [ $attempt -gt 1 ]; then
        echo "      🔄 重试 $attempt/$MAX_RETRIES..."
        sleep $RETRY_DELAY
    fi
    
    HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}" hf download ...
    
    if [ $? -eq 0 ]; then
        echo "      ✓ 下载完成"
        DOWNLOAD_SUCCESS=true
        break
    else
        if [ $attempt -eq $MAX_RETRIES ]; then
            echo "      ✗ 下载失败（已重试 $MAX_RETRIES 次）"
        fi
    fi
done
```

---

## 💡 推荐配置

| 网络状况 | 推荐重试次数 | 命令示例 |
|---------|------------|---------|
| 🟢 **网络稳定** | 3（默认） | `./download_with_hf.sh` |
| 🟡 **偶尔波动** | 5 | `./download_with_hf.sh --retry 5` |
| 🟠 **经常失败** | 10 | `./download_with_hf.sh --retry 10` |
| 🔴 **极度不稳定** | 20 | `./download_with_hf.sh --retry 20` |

---

## 📊 实际效果

### 案例 1：网络波动

```bash
$ ./download_with_hf.sh --dirs loras --retry 5

==================== loras ====================
下载 loras 目录的模型 (17 个)...

  [1/17] 下载: Qwen-Image-Lightning-4steps-V1.0.safetensors
      🔄 重试 2/5...
      ✓ 下载完成
  
  [2/17] 下载: Qwen-Image-Lightning-8steps-V1.0.safetensors
      ✓ 下载完成
  
  [3/17] 下载: flux1-depth-dev-lora.safetensors
      🔄 重试 2/5...
      🔄 重试 3/5...
      ✓ 下载完成
```

### 案例 2：多次重试后成功

```bash
  [5/17] 下载: lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors
      🔄 重试 2/10...
      🔄 重试 3/10...
      🔄 重试 4/10...
      🔄 重试 5/10...
      ✓ 下载完成
```

### 案例 3：最终失败

```bash
  [8/17] 下载: flux2_berthe_morisot.safetensors
      🔄 重试 2/5...
      🔄 重试 3/5...
      🔄 重试 4/5...
      🔄 重试 5/5...
      ✗ 下载失败（已重试 5 次）
```

---

## 🎯 最佳实践

### 1. **根据网络调整**
```bash
# 测试网络
ping -c 5 hf-mirror.com

# 如果丢包率 > 10%，使用更多重试
./download_with_hf.sh --retry 10
```

### 2. **批量下载建议**
```bash
# 下载大量模型时，使用较多重试
./download_with_hf.sh --retry 10

# 避免因个别文件失败而中断整个流程
```

### 3. **时间规划**
```bash
# 每次重试间隔 5 秒
# 重试 10 次，单个文件最多额外等待: 10 × 5 = 50 秒
# 合理安排下载时间
```

---

## 🔍 故障排查

### 问题 1：所有下载都失败

**可能原因**：
- 镜像服务器不可访问
- 网络完全中断
- `HF_ENDPOINT` 设置错误

**解决方案**：
```bash
# 1. 检查镜像可访问性
curl -I https://hf-mirror.com

# 2. 测试 hf download 命令
export HF_ENDPOINT="https://hf-mirror.com"
hf download --help

# 3. 尝试使用官方地址（如果可访问）
unset HF_ENDPOINT
./download_with_hf.sh --retry 5
```

### 问题 2：重试多次后仍失败

**可能原因**：
- 文件太大，下载超时
- 特定文件在服务器上不存在
- 磁盘空间不足

**解决方案**：
```bash
# 1. 检查磁盘空间
df -h /root/dehui/models

# 2. 增加重试次数和超时时间
./download_with_hf.sh --retry 20

# 3. 单独下载失败的文件
hf download "repo_id" "file_path" --local-dir /path
```

### 问题 3：重试过程中脚本卡住

**可能原因**：
- 下载进程未正常退出
- 网络连接挂起

**解决方案**：
```bash
# 1. 查看进程
ps aux | grep "hf download"

# 2. 终止卡住的进程
kill -9 <PID>

# 3. 重新运行脚本
./download_with_hf.sh --retry 5
```

---

## 📝 技术细节

### 重试间隔

```bash
RETRY_DELAY=5  # 默认 5 秒
```

**为什么是 5 秒？**
- ✅ 给网络一些恢复时间
- ✅ 避免频繁请求被限流
- ✅ 不会等待太久

### 退出状态码

```bash
# 下载成功
$? = 0  → break（退出重试循环）

# 下载失败
$? ≠ 0  → 继续下一次重试
```

### 统计计数

```bash
DOWNLOAD_SUCCESS=true   → ((SUCCESS++))
DOWNLOAD_SUCCESS=false  → ((FAILED++))
```

---

## 🚀 快速开始

### 第一次使用（推荐）

```bash
# 1. 给脚本添加执行权限
chmod +x download_with_hf.sh

# 2. 测试下载少量模型
./download_with_hf.sh --dirs loras --retry 5

# 3. 观察重试效果，调整重试次数
# 如果大部分文件都需要重试 > 3 次，增加重试次数

# 4. 下载所有模型
./download_with_hf.sh --retry 10
```

### 日常使用

```bash
# 网络好时
./download_with_hf.sh

# 网络差时
./download_with_hf.sh --retry 10

# 只下载新增的模型（会自动跳过已存在的）
./download_with_hf.sh
```

---

## ⚙️ 高级配置

### 修改重试间隔

如果需要修改重试间隔（默认 5 秒），编辑脚本：

```bash
# 第 47 行
RETRY_DELAY=5  # 改成你需要的秒数，如 10
```

### 修改默认重试次数

```bash
# 第 46 行
MAX_RETRIES=3  # 改成你需要的次数，如 5
```

---

## 📚 相关文档

- [HF_CLI_GUIDE.md](./HF_CLI_GUIDE.md) - 完整使用指南
- [CHINA_MIRROR_GUIDE.md](./CHINA_MIRROR_GUIDE.md) - 国内镜像配置
- [SHELL_SCRIPT_USAGE.md](./SHELL_SCRIPT_USAGE.md) - Shell 脚本用法
- [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - 快速参考

---

## 💬 常见问题

**Q: 重试会不会浪费时间？**
A: 不会。成功的下载不会重试，只有失败的才重试。而且重试避免了手动重新运行整个脚本。

**Q: 可以设置无限重试吗？**
A: 不建议。可以设置较大的值如 `--retry 100`，但建议检查根本原因。

**Q: 重试会重新下载整个文件吗？**
A: 取决于 `hf download` 的实现。通常支持断点续传，不会完全重新下载。

**Q: 怎么知道重试是否生效？**
A: 看到 `🔄 重试 X/Y...` 的提示就说明正在重试。

---

## 🎉 总结

✅ **自动重试** - 无需手动干预
✅ **灵活配置** - 根据网络调整
✅ **友好提示** - 清晰的进度显示
✅ **高成功率** - 大幅提高下载成功率

现在就试试吧！

```bash
./download_with_hf.sh --dirs loras --retry 5
```

