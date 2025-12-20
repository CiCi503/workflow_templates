#!/bin/bash
#
# SHA256 验证工具使用示例
#

echo "================================"
echo "SHA256 验证工具使用示例"
echo "================================"
echo ""

# 检查依赖
echo "1️⃣  检查依赖..."
if ! python3 -c "import huggingface_hub" 2>/dev/null; then
    echo "   ❌ huggingface_hub 未安装"
    echo "   📦 安装命令: pip install huggingface_hub colorama"
    echo ""
    echo "   或者只安装必需依赖:"
    echo "   pip install huggingface_hub"
    exit 1
else
    echo "   ✅ 依赖已安装"
fi

echo ""
echo "2️⃣  使用方法:"
echo ""

# 设置模型目录（请修改为你的实际路径）
MODEL_DIR="/root/dehui/models"

echo "   假设你的模型在: $MODEL_DIR"
echo ""

echo "   基本使用:"
echo "   ---------"
echo "   # 验证所有模型"
echo "   python3 verify_models_sha256.py $MODEL_DIR"
echo ""

echo "   验证特定目录:"
echo "   -----------"
echo "   # 只验证 unet 目录"
echo "   python3 verify_models_sha256.py $MODEL_DIR --dir unet"
echo ""
echo "   # 只验证 loras 目录"
echo "   python3 verify_models_sha256.py $MODEL_DIR --dir loras"
echo ""

echo "   显示详细信息:"
echo "   -----------"
echo "   python3 verify_models_sha256.py $MODEL_DIR --verbose"
echo ""

echo "   导出验证报告:"
echo "   -----------"
echo "   python3 verify_models_sha256.py $MODEL_DIR --output verification_report.json"
echo ""

echo "   组合使用:"
echo "   --------"
echo "   python3 verify_models_sha256.py $MODEL_DIR --dir unet --verbose --output unet_report.json"
echo ""

echo "3️⃣  验证流程:"
echo ""
echo "   步骤 1: 验证所有模型"
echo "   → python3 verify_models_sha256.py $MODEL_DIR"
echo ""
echo "   步骤 2: 查看验证结果，找出损坏的文件"
echo "   → 脚本会自动列出 SHA256 不一致的文件"
echo ""
echo "   步骤 3: 删除损坏的文件"
echo "   → rm $MODEL_DIR/loras/damaged_model.safetensors"
echo ""
echo "   步骤 4: 重新下载"
echo "   → ./download_with_hf.sh --dirs loras"
echo ""

echo "4️⃣  常见场景:"
echo ""
echo "   场景 1: 下载后验证"
echo "   -----------------"
echo "   ./download_with_hf.sh --dirs unet"
echo "   python3 verify_models_sha256.py $MODEL_DIR --dir unet"
echo ""

echo "   场景 2: 定期检查"
echo "   --------------"
echo "   # 每周运行一次，确保文件没有损坏"
echo "   python3 verify_models_sha256.py $MODEL_DIR --output weekly_check.json"
echo ""

echo "   场景 3: 批量验证"
echo "   --------------"
echo "   # 验证多个目录"
echo "   for dir in unet loras vae clip; do"
echo "       python3 verify_models_sha256.py $MODEL_DIR --dir \$dir"
echo "   done"
echo ""

echo "================================"
echo "✅ 准备完成！"
echo "================================"
echo ""
echo "现在你可以运行验证命令了。"
echo "建议先测试一个小目录:"
echo ""
echo "python3 verify_models_sha256.py $MODEL_DIR --dir clip_vision --verbose"
echo ""

