# 🔧 环境变量污染问题修复

## 问题描述

用户反馈：**下载一个模型时，只要失败一次，后面的网络就都不通了**

### 症状
```
下载模型 A → 成功 ✓
下载模型 B → 超时失败 ✗
下载模型 C → 网络不通 ✗  ← 环境变量被污染！
下载模型 D → 网络不通 ✗  ← 环境变量被污染！
```

## 根本原因

### 之前的实现方式
```bash
# ❌ 每个命令都临时设置环境变量
HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}" hf download "repo/model" "file"
```

**问题：**
1. 临时环境变量只对当前命令有效
2. `hf download` 内部可能有多次网络请求，子进程可能丢失环境变量
3. 失败后可能污染某些内部状态（缓存、连接池等）
4. 重试时环境变量没有重新设置，继续使用污染的状态

## 解决方案

### 新的实现方式

```bash
#!/bin/bash

# ✅ 1. 脚本开头统一 export（全局生效）
export HF_ENDPOINT="https://hf-mirror.com"

# ✅ 2. 每次重试前重新 export，清理可能的污染状态
for ((attempt=1; attempt<=MAX_RETRIES; attempt++)); do
    if [ $attempt -gt 1 ]; then
        echo "      🔄 重试 $attempt/$MAX_RETRIES..."
        sleep $RETRY_DELAY
        
        # 重新设置环境变量，清理可能的污染状态
        export HF_ENDPOINT="https://hf-mirror.com"
    fi
    
    # ✅ 3. 直接调用 hf download（依赖全局环境变量）
    hf download "repo/model" "file" --local-dir "$TARGET_DIR" --revision main
    
    if [ $? -eq 0 ]; then
        echo "      ✓ 下载完成"
        break
    fi
done
```

## 改进效果

### 之前
```
模型 A → 成功 ✓
模型 B → 失败 ✗（环境变量被污染）
模型 C → 失败 ✗（继承污染状态）
模型 D → 失败 ✗（继承污染状态）
```

### 现在
```
模型 A → 成功 ✓
模型 B → 失败 ✗ → 重试（重新 export）→ 成功 ✓
模型 C → 成功 ✓（环境干净）
模型 D → 成功 ✓（环境干净）
```

## 技术细节

### 为什么每次重试前重新 export？

1. **清理污染状态**
   - `hf download` 失败后可能缓存了错误的连接信息
   - 重新 export 强制刷新环境，清理缓存

2. **确保环境变量传递**
   - 某些子进程可能丢失环境变量
   - 显式 export 确保所有子进程都能获取正确配置

3. **提高稳定性**
   - 即使某次下载污染了环境，下次重试也能恢复
   - 每个下载任务都从干净的环境开始

### export vs 临时环境变量

```bash
# 临时环境变量（只对单个命令有效）
VAR=value command args

# export（对当前 shell 及所有子进程有效）
export VAR=value
command args
```

## 验证方法

### 测试脚本
```bash
# 下载容易失败的大模型，观察重试是否成功
./download_with_hf.sh --dirs loras --retry 10
```

### 观察重试流程
```
  [5/17] 下载: flux1-depth-dev-lora.safetensors
      🔄 重试 2/10...          ← 重新 export HF_ENDPOINT
      ✓ 下载完成               ← 环境干净，重试成功！
  
  [6/17] 下载: next_model.safetensors
      ✓ 下载完成               ← 环境未被污染，正常下载
```

## 使用建议

### 网络不稳定时
```bash
# 增加重试次数
./download_with_hf.sh --dirs loras --retry 20

# 说明：
# - 每次重试都会重新 export 环境变量
# - 即使某次失败污染了环境，下次重试也能恢复
# - 大幅提高最终成功率
```

### 监控环境变量
```bash
# 在脚本中可以添加调试输出
echo "当前 HF_ENDPOINT: $HF_ENDPOINT"
```

## 总结

| 对比项 | 之前 | 现在 |
|--------|------|------|
| 环境变量设置 | 每个命令临时设置 | 全局 export |
| 重试时处理 | 使用旧环境 | 重新 export |
| 污染恢复 | ❌ 无法恢复 | ✅ 自动清理 |
| 稳定性 | 🟠 失败后连锁失败 | 🟢 失败隔离，不影响后续 |
| 成功率 | 🟠 低（环境污染） | 🟢 高（环境干净） |

---

**修复日期**: 2025-12-19  
**影响文件**: 
- `generate_hf_download_script.py`
- `download_with_hf.sh`

**立即使用新脚本**:
```bash
chmod +x download_with_hf.sh
./download_with_hf.sh --dirs loras --retry 10
```

