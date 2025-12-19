# 快速参考卡

## 命令速查

```bash
# 查看帮助
./download_with_hf_cli.sh --help

# 下载所有模型
./download_with_hf_cli.sh

# 下载指定目录
./download_with_hf_cli.sh --dirs loras controlnet

# 自定义路径
./download_with_hf_cli.sh --target-dir /root/dehui/models

# 组合使用
./download_with_hf_cli.sh --dirs loras --target-dir /root/dehui/models
```

## 可用目录

```
audio          checkpoints      clip             clip_vision      controlnet
loras          style_models     unet             unknown          vae
```

## 常用组合

| 用途 | 命令 | 模型数 | 大小 | 时间 |
|------|------|--------|------|------|
| 测试 | `--dirs clip_vision` | 3 | 2GB | 3分钟 |
| LoRA | `--dirs loras` | 19 | 5GB | 8分钟 |
| 控制 | `--dirs controlnet` | 7 | 3GB | 5分钟 |
| FLUX | `--dirs unet clip vae` | 67 | 125GB | 3小时 |
| 全部 | 不加参数 | 112 | 180GB | 5小时 |

## 参数说明

| 参数 | 简写 | 说明 | 示例 |
|------|------|------|------|
| `--dirs` | `-d` | 指定目录 | `--dirs loras` |
| `--target-dir` | `-t` | 目标路径 | `--target-dir /path` |
| `--help` | `-h` | 显示帮助 | `--help` |

## 下载到 /root/dehui/models 的示例

```bash
# 只下载 loras
./download_with_hf_cli.sh --dirs loras --target-dir /root/dehui/models

# 下载多个目录
./download_with_hf_cli.sh --dirs loras controlnet --target-dir /root/dehui/models

# FLUX 套件
./download_with_hf_cli.sh --dirs unet clip vae --target-dir /root/dehui/models
```

## 错误处理

- **无效目录**: 脚本会提示可用目录列表
- **已存在文件**: 自动跳过，不会重复下载
- **下载中断**: 重新运行相同命令即可继续
- **权限不足**: 确保对目标目录有写权限

## 前置要求

```bash
# 1. 安装 huggingface-cli
pip install huggingface_hub

# 2. 登录（二选一）
huggingface-cli login
# 或
export HF_TOKEN=your_token_here
```

