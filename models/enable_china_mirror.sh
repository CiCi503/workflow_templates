#!/bin/bash
# 一键启用国内 Hugging Face 镜像

set -e

echo "======================================"
echo "启用 Hugging Face 国内镜像"
echo "======================================"
echo ""

# 检查文件是否存在
if [ ! -f download_with_hf.sh ]; then
    echo "❌ 错误: 找不到 download_with_hf.sh"
    echo "请确保在正确的目录下运行此脚本"
    exit 1
fi

# 备份原文件
echo "📦 备份原文件..."
cp download_with_hf.sh download_with_hf.sh.bak
echo "✓ 已备份为: download_with_hf.sh.bak"
echo ""

# 检查是否已经启用
if grep -q "^export HF_ENDPOINT=" download_with_hf.sh; then
    echo "ℹ️  镜像已经启用"
    current_endpoint=$(grep "^export HF_ENDPOINT=" download_with_hf.sh | cut -d'"' -f2)
    echo "   当前镜像: $current_endpoint"
    echo ""
    read -p "是否要重新设置？(y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "✓ 保持当前设置"
        exit 0
    fi
fi

# 取消注释 HF_ENDPOINT
echo "🔧 启用镜像设置..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' 's/# export HF_ENDPOINT=/export HF_ENDPOINT=/' download_with_hf.sh
else
    # Linux
    sed -i 's/# export HF_ENDPOINT=/export HF_ENDPOINT=/' download_with_hf.sh
fi

# 验证修改
if grep -q "^export HF_ENDPOINT=" download_with_hf.sh; then
    echo "✓ 镜像设置已启用"
    endpoint=$(grep "^export HF_ENDPOINT=" download_with_hf.sh | cut -d'"' -f2)
    echo "✓ 镜像地址: $endpoint"
else
    echo "❌ 启用失败，请手动编辑 download_with_hf.sh"
    exit 1
fi

echo ""
echo "======================================"
echo "✅ 配置完成！"
echo "======================================"
echo ""
echo "现在可以直接运行下载脚本："
echo ""
echo "  # 下载 LoRA 模型"
echo "  ./download_with_hf.sh --dirs loras --target-dir /root/dehui/models"
echo ""
echo "  # 下载多个目录"
echo "  ./download_with_hf.sh --dirs loras controlnet --target-dir /root/dehui/models"
echo ""
echo "运行时应该会看到："
echo "  使用 Hugging Face 镜像: https://hf-mirror.com"
echo ""
echo "如需恢复默认设置，运行："
echo "  cp download_with_hf.sh.bak download_with_hf.sh"
echo ""

