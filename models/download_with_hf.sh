#!/bin/bash
#
# 使用 hf download 批量下载 ComfyUI 模型
#
# 安装依赖:
#   pip install huggingface_hub
#
# 设置 Token:
#   export HF_TOKEN=your_token_here
#   或: huggingface-cli login
#
# 使用国内镜像（可选）:
#   export HF_ENDPOINT="https://hf-mirror.com"
#   或在脚本内设置（见下方 HF_ENDPOINT 变量）
#
# 使用方法:
#   下载所有模型:
#     ./download_with_hf.sh
#
#   只下载指定目录:
#     ./download_with_hf.sh --dirs loras controlnet
#     ./download_with_hf.sh -d unet clip vae
#
#   自定义目标目录:
#     ./download_with_hf.sh --target-dir /custom/path
#
#   查看帮助:
#     ./download_with_hf.sh --help
#

# 加载用户的 shell 配置（包含环境变量）
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
if [ -f ~/.bash_profile ]; then
    source ~/.bash_profile
fi
if [ -f ~/.zshrc ]; then
    source ~/.zshrc
fi

DEFAULT_TARGET_DIR="/root/dehui/models"
TARGET_DIR="$DEFAULT_TARGET_DIR"
ALL_DIRS=(audio checkpoints clip clip_vision controlnet loras style_models unet unknown vae)
SELECTED_DIRS=()

# 设置 Hugging Face 镜像（国内用户）
# 如果需要使用国内镜像，取消下面一行的注释:
# export HF_ENDPOINT="https://hf-mirror.com"
# 或者从环境变量继承（如果已设置）
if [ -n "$HF_ENDPOINT" ]; then
    echo "使用 Hugging Face 镜像: $HF_ENDPOINT"
fi

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dirs)
            shift
            while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                SELECTED_DIRS+=("$1")
                shift
            done
            ;;
        -t|--target-dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "使用方法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  -d, --dirs <目录...>     只下载指定目录的模型"
            echo "  -t, --target-dir <路径>  指定下载目标目录（默认: $DEFAULT_TARGET_DIR）"
            echo "  -h, --help              显示此帮助信息"
            echo ""
            echo "可用目录:"
            echo "  audio checkpoints clip clip_vision controlnet loras style_models unet unknown vae"
            echo ""
            echo "示例:"
            echo "  $0                              # 下载所有模型"
            echo "  $0 --dirs loras controlnet      # 只下载 loras 和 controlnet"
            echo "  $0 -d unet clip vae             # 只下载 unet、clip 和 vae"
            echo "  $0 --target-dir /custom/path    # 下载到自定义目录"
            echo ""
            echo "国内镜像设置:"
            echo "  编辑脚本，取消注释: export HF_ENDPOINT=\"https://hf-mirror.com\""
            echo "  或运行: HF_ENDPOINT=\"https://hf-mirror.com\" $0 --dirs loras"
            exit 0
            ;;
        *)
            echo "错误: 未知参数 $1"
            echo "运行 $0 --help 查看帮助"
            exit 1
            ;;
    esac
done

# 如果没有指定目录，下载所有目录
if [ ${#SELECTED_DIRS[@]} -eq 0 ]; then
    SELECTED_DIRS=("${ALL_DIRS[@]}")
fi

# 验证选择的目录
for dir in "${SELECTED_DIRS[@]}"; do
    if [[ ! " ${ALL_DIRS[@]} " =~ " ${dir} " ]]; then
        echo "错误: 无效的目录 '$dir'"
        echo "可用目录: ${ALL_DIRS[@]}"
        exit 1
    fi
done

# 检查是否安装了 hf
if ! command -v hf &> /dev/null; then
    echo "错误: 未找到 hf 命令"
    echo "请运行: pip install huggingface_hub"
    exit 1
fi

echo "======================================"
echo "开始下载 ComfyUI 模型"
echo "======================================"
echo "目标目录: $TARGET_DIR"
echo "选择目录: ${SELECTED_DIRS[@]}"
echo ""

# 统计
SUCCESS=0
FAILED=0
SKIPPED=0

# 下载函数: audio
download_audio() {
    echo "==================== audio ===================="
    echo "下载 audio 目录的模型 (2 个)..."
    mkdir -p "$TARGET_DIR/audio"
    echo ""

    # [1/2] wav2vec2_large_english_fp16.safetensors
    echo "  [1/2] 下载: wav2vec2_large_english_fp16.safetensors"
    if [ -f "$TARGET_DIR/audio/wav2vec2_large_english_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/audio_encoders/wav2vec2_large_english_fp16.safetensors" --local-dir "$TARGET_DIR/audio" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/audio/split_files/audio_encoders/wav2vec2_large_english_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/audio/wav2vec2_large_english_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [2/2] whisper_large_v3_fp16.safetensors
    echo "  [2/2] 下载: whisper_large_v3_fp16.safetensors"
    if [ -f "$TARGET_DIR/audio/whisper_large_v3_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/HuMo_ComfyUI" "split_files/audio_encoders/whisper_large_v3_fp16.safetensors" --local-dir "$TARGET_DIR/audio" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/audio/split_files/audio_encoders/whisper_large_v3_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/audio/whisper_large_v3_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    echo ""
}

# 下载函数: checkpoints
download_checkpoints() {
    echo "==================== checkpoints ===================="
    echo "下载 checkpoints 目录的模型 (13 个)..."
    mkdir -p "$TARGET_DIR/checkpoints"
    echo ""

    # [1/13] 512-inpainting-ema.safetensors
    echo "  [1/13] 下载: 512-inpainting-ema.safetensors"
    if [ -f "$TARGET_DIR/checkpoints/512-inpainting-ema.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/stable_diffusion_2.1_repackaged" "512-inpainting-ema.safetensors" --local-dir "$TARGET_DIR/checkpoints" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/checkpoints/512-inpainting-ema.safetensors"
            TARGET_FILE="$TARGET_DIR/checkpoints/512-inpainting-ema.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [2/13] DreamShaper_8_pruned.safetensors
    echo "  [2/13] 下载: DreamShaper_8_pruned.safetensors"
    if [ -f "$TARGET_DIR/checkpoints/DreamShaper_8_pruned.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Lykon/DreamShaper" "DreamShaper_8_pruned.safetensors" --local-dir "$TARGET_DIR/checkpoints" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/checkpoints/DreamShaper_8_pruned.safetensors"
            TARGET_FILE="$TARGET_DIR/checkpoints/DreamShaper_8_pruned.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [3/13] NetaYumev35_pretrained_all_in_one.safetensors
    echo "  [3/13] 下载: NetaYumev35_pretrained_all_in_one.safetensors"
    if [ -f "$TARGET_DIR/checkpoints/NetaYumev35_pretrained_all_in_one.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "duongve/NetaYume-Lumina-Image-2.0" "NetaYumev35_pretrained_all_in_one.safetensors" --local-dir "$TARGET_DIR/checkpoints" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/checkpoints/NetaYumev35_pretrained_all_in_one.safetensors"
            TARGET_FILE="$TARGET_DIR/checkpoints/NetaYumev35_pretrained_all_in_one.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [4/13] ace_step_v1_3.5b.safetensors
    echo "  [4/13] 下载: ace_step_v1_3.5b.safetensors"
    if [ -f "$TARGET_DIR/checkpoints/ace_step_v1_3.5b.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/ACE-Step_ComfyUI_repackaged" "all_in_one/ace_step_v1_3.5b.safetensors" --local-dir "$TARGET_DIR/checkpoints" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/checkpoints/all_in_one/ace_step_v1_3.5b.safetensors"
            TARGET_FILE="$TARGET_DIR/checkpoints/ace_step_v1_3.5b.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [5/13] hunyuan3d-dit-v2-mv-turbo_fp16.safetensors
    echo "  [5/13] 下载: hunyuan3d-dit-v2-mv-turbo_fp16.safetensors"
    if [ -f "$TARGET_DIR/checkpoints/hunyuan3d-dit-v2-mv-turbo_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/hunyuan3D_2.0_repackaged" "split_files/hunyuan3d-dit-v2-mv-turbo_fp16.safetensors" --local-dir "$TARGET_DIR/checkpoints" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/checkpoints/split_files/hunyuan3d-dit-v2-mv-turbo_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/checkpoints/hunyuan3d-dit-v2-mv-turbo_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [6/13] hunyuan3d-dit-v2-mv_fp16.safetensors
    echo "  [6/13] 下载: hunyuan3d-dit-v2-mv_fp16.safetensors"
    if [ -f "$TARGET_DIR/checkpoints/hunyuan3d-dit-v2-mv_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/hunyuan3D_2.0_repackaged" "split_files/hunyuan3d-dit-v2-mv_fp16.safetensors" --local-dir "$TARGET_DIR/checkpoints" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/checkpoints/split_files/hunyuan3d-dit-v2-mv_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/checkpoints/hunyuan3d-dit-v2-mv_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [7/13] hunyuan3d-dit-v2_fp16.safetensors
    echo "  [7/13] 下载: hunyuan3d-dit-v2_fp16.safetensors"
    if [ -f "$TARGET_DIR/checkpoints/hunyuan3d-dit-v2_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/hunyuan3D_2.0_repackaged" "split_files/hunyuan3d-dit-v2_fp16.safetensors" --local-dir "$TARGET_DIR/checkpoints" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/checkpoints/split_files/hunyuan3d-dit-v2_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/checkpoints/hunyuan3d-dit-v2_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [8/13] hunyuan_3d_v2.1.safetensors
    echo "  [8/13] 下载: hunyuan_3d_v2.1.safetensors"
    if [ -f "$TARGET_DIR/checkpoints/hunyuan_3d_v2.1.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/hunyuan3D_2.1_repackaged" "hunyuan_3d_v2.1.safetensors" --local-dir "$TARGET_DIR/checkpoints" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/checkpoints/hunyuan_3d_v2.1.safetensors"
            TARGET_FILE="$TARGET_DIR/checkpoints/hunyuan_3d_v2.1.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [9/13] ltx-video-2b-v0.9.5.safetensors
    echo "  [9/13] 下载: ltx-video-2b-v0.9.5.safetensors"
    if [ -f "$TARGET_DIR/checkpoints/ltx-video-2b-v0.9.5.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Lightricks/LTX-Video" "ltx-video-2b-v0.9.5.safetensors" --local-dir "$TARGET_DIR/checkpoints" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/checkpoints/ltx-video-2b-v0.9.5.safetensors"
            TARGET_FILE="$TARGET_DIR/checkpoints/ltx-video-2b-v0.9.5.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [10/13] sd3.5_large_fp8_scaled.safetensors
    echo "  [10/13] 下载: sd3.5_large_fp8_scaled.safetensors"
    if [ -f "$TARGET_DIR/checkpoints/sd3.5_large_fp8_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/stable-diffusion-3.5-fp8" "sd3.5_large_fp8_scaled.safetensors" --local-dir "$TARGET_DIR/checkpoints" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/checkpoints/sd3.5_large_fp8_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/checkpoints/sd3.5_large_fp8_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [11/13] sd_xl_base_1.0.safetensors
    echo "  [11/13] 下载: sd_xl_base_1.0.safetensors"
    if [ -f "$TARGET_DIR/checkpoints/sd_xl_base_1.0.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "stabilityai/stable-diffusion-xl-base-1.0" "sd_xl_base_1.0.safetensors" --local-dir "$TARGET_DIR/checkpoints" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/checkpoints/sd_xl_base_1.0.safetensors"
            TARGET_FILE="$TARGET_DIR/checkpoints/sd_xl_base_1.0.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [12/13] stable-audio-open-1.0.safetensors
    echo "  [12/13] 下载: stable-audio-open-1.0.safetensors"
    if [ -f "$TARGET_DIR/checkpoints/stable-audio-open-1.0.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/stable-audio-open-1.0_repackaged" "stable-audio-open-1.0.safetensors" --local-dir "$TARGET_DIR/checkpoints" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/checkpoints/stable-audio-open-1.0.safetensors"
            TARGET_FILE="$TARGET_DIR/checkpoints/stable-audio-open-1.0.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [13/13] v1-5-pruned-emaonly-fp16.safetensors
    echo "  [13/13] 下载: v1-5-pruned-emaonly-fp16.safetensors"
    if [ -f "$TARGET_DIR/checkpoints/v1-5-pruned-emaonly-fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/stable-diffusion-v1-5-archive" "v1-5-pruned-emaonly-fp16.safetensors" --local-dir "$TARGET_DIR/checkpoints" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/checkpoints/v1-5-pruned-emaonly-fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/checkpoints/v1-5-pruned-emaonly-fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    echo ""
}

# 下载函数: clip
download_clip() {
    echo "==================== clip ===================="
    echo "下载 clip 目录的模型 (15 个)..."
    mkdir -p "$TARGET_DIR/clip"
    echo ""

    # [1/15] byt5_small_glyphxl_fp16.safetensors
    echo "  [1/15] 下载: byt5_small_glyphxl_fp16.safetensors"
    if [ -f "$TARGET_DIR/clip/byt5_small_glyphxl_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/HunyuanVideo_1.5_repackaged" "split_files/text_encoders/byt5_small_glyphxl_fp16.safetensors" --local-dir "$TARGET_DIR/clip" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip/split_files/text_encoders/byt5_small_glyphxl_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/clip/byt5_small_glyphxl_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [2/15] clip_g_hidream.safetensors
    echo "  [2/15] 下载: clip_g_hidream.safetensors"
    if [ -f "$TARGET_DIR/clip/clip_g_hidream.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/HiDream-I1_ComfyUI" "split_files/text_encoders/clip_g_hidream.safetensors" --local-dir "$TARGET_DIR/clip" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip/split_files/text_encoders/clip_g_hidream.safetensors"
            TARGET_FILE="$TARGET_DIR/clip/clip_g_hidream.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [3/15] clip_l.safetensors
    echo "  [3/15] 下载: clip_l.safetensors"
    if [ -f "$TARGET_DIR/clip/clip_l.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "comfyanonymous/flux_text_encoders" "clip_l.safetensors" --local-dir "$TARGET_DIR/clip" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip/clip_l.safetensors"
            TARGET_FILE="$TARGET_DIR/clip/clip_l.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [4/15] clip_l_hidream.safetensors
    echo "  [4/15] 下载: clip_l_hidream.safetensors"
    if [ -f "$TARGET_DIR/clip/clip_l_hidream.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/HiDream-I1_ComfyUI" "split_files/text_encoders/clip_l_hidream.safetensors" --local-dir "$TARGET_DIR/clip" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip/split_files/text_encoders/clip_l_hidream.safetensors"
            TARGET_FILE="$TARGET_DIR/clip/clip_l_hidream.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [5/15] llama_3.1_8b_instruct_fp8_scaled.safetensors
    echo "  [5/15] 下载: llama_3.1_8b_instruct_fp8_scaled.safetensors"
    if [ -f "$TARGET_DIR/clip/llama_3.1_8b_instruct_fp8_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/HiDream-I1_ComfyUI" "split_files/text_encoders/llama_3.1_8b_instruct_fp8_scaled.safetensors" --local-dir "$TARGET_DIR/clip" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip/split_files/text_encoders/llama_3.1_8b_instruct_fp8_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/clip/llama_3.1_8b_instruct_fp8_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [6/15] mistral_3_small_flux2_bf16.safetensors
    echo "  [6/15] 下载: mistral_3_small_flux2_bf16.safetensors"
    if [ -f "$TARGET_DIR/clip/mistral_3_small_flux2_bf16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/flux2-dev" "split_files/text_encoders/mistral_3_small_flux2_bf16.safetensors" --local-dir "$TARGET_DIR/clip" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip/split_files/text_encoders/mistral_3_small_flux2_bf16.safetensors"
            TARGET_FILE="$TARGET_DIR/clip/mistral_3_small_flux2_bf16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [7/15] mistral_3_small_flux2_fp8.safetensors
    echo "  [7/15] 下载: mistral_3_small_flux2_fp8.safetensors"
    if [ -f "$TARGET_DIR/clip/mistral_3_small_flux2_fp8.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/flux2-dev" "split_files/text_encoders/mistral_3_small_flux2_fp8.safetensors" --local-dir "$TARGET_DIR/clip" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip/split_files/text_encoders/mistral_3_small_flux2_fp8.safetensors"
            TARGET_FILE="$TARGET_DIR/clip/mistral_3_small_flux2_fp8.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [8/15] qwen_2.5_vl_7b_fp8_scaled.safetensors
    echo "  [8/15] 下载: qwen_2.5_vl_7b_fp8_scaled.safetensors"
    if [ -f "$TARGET_DIR/clip/qwen_2.5_vl_7b_fp8_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/HunyuanVideo_1.5_repackaged" "split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors" --local-dir "$TARGET_DIR/clip" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/clip/qwen_2.5_vl_7b_fp8_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [9/15] qwen_2.5_vl_fp16.safetensors
    echo "  [9/15] 下载: qwen_2.5_vl_fp16.safetensors"
    if [ -f "$TARGET_DIR/clip/qwen_2.5_vl_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Omnigen2_ComfyUI_repackaged" "split_files/text_encoders/qwen_2.5_vl_fp16.safetensors" --local-dir "$TARGET_DIR/clip" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip/split_files/text_encoders/qwen_2.5_vl_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/clip/qwen_2.5_vl_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [10/15] qwen_3_4b.safetensors
    echo "  [10/15] 下载: qwen_3_4b.safetensors"
    if [ -f "$TARGET_DIR/clip/qwen_3_4b.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/z_image_turbo" "split_files/text_encoders/qwen_3_4b.safetensors" --local-dir "$TARGET_DIR/clip" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip/split_files/text_encoders/qwen_3_4b.safetensors"
            TARGET_FILE="$TARGET_DIR/clip/qwen_3_4b.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [11/15] t5-base.safetensors
    echo "  [11/15] 下载: t5-base.safetensors"
    if [ -f "$TARGET_DIR/clip/t5-base.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "ComfyUI-Wiki/t5-base" "t5-base.safetensors" --local-dir "$TARGET_DIR/clip" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip/t5-base.safetensors"
            TARGET_FILE="$TARGET_DIR/clip/t5-base.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [12/15] t5xxl_fp16.safetensors
    echo "  [12/15] 下载: t5xxl_fp16.safetensors"
    if [ -f "$TARGET_DIR/clip/t5xxl_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "comfyanonymous/flux_text_encoders" "t5xxl_fp16.safetensors" --local-dir "$TARGET_DIR/clip" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip/t5xxl_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/clip/t5xxl_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [13/15] t5xxl_fp8_e4m3fn_scaled.safetensors
    echo "  [13/15] 下载: t5xxl_fp8_e4m3fn_scaled.safetensors"
    if [ -f "$TARGET_DIR/clip/t5xxl_fp8_e4m3fn_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "comfyanonymous/flux_text_encoders" "t5xxl_fp8_e4m3fn_scaled.safetensors" --local-dir "$TARGET_DIR/clip" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip/t5xxl_fp8_e4m3fn_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/clip/t5xxl_fp8_e4m3fn_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [14/15] umt5_xxl_fp16.safetensors
    echo "  [14/15] 下载: umt5_xxl_fp16.safetensors"
    if [ -f "$TARGET_DIR/clip/umt5_xxl_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/text_encoders/umt5_xxl_fp16.safetensors" --local-dir "$TARGET_DIR/clip" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip/split_files/text_encoders/umt5_xxl_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/clip/umt5_xxl_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [15/15] umt5_xxl_fp8_e4m3fn_scaled.safetensors
    echo "  [15/15] 下载: umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    if [ -f "$TARGET_DIR/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" --local-dir "$TARGET_DIR/clip" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    echo ""
}

# 下载函数: clip_vision
download_clip_vision() {
    echo "==================== clip_vision ===================="
    echo "下载 clip_vision 目录的模型 (3 个)..."
    mkdir -p "$TARGET_DIR/clip_vision"
    echo ""

    # [1/3] clip_vision_g.safetensors
    echo "  [1/3] 下载: clip_vision_g.safetensors"
    if [ -f "$TARGET_DIR/clip_vision/clip_vision_g.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "comfyanonymous/clip_vision_g" "clip_vision_g.safetensors" --local-dir "$TARGET_DIR/clip_vision" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip_vision/clip_vision_g.safetensors"
            TARGET_FILE="$TARGET_DIR/clip_vision/clip_vision_g.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [2/3] clip_vision_h.safetensors
    echo "  [2/3] 下载: clip_vision_h.safetensors"
    if [ -f "$TARGET_DIR/clip_vision/clip_vision_h.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/clip_vision/clip_vision_h.safetensors" --local-dir "$TARGET_DIR/clip_vision" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip_vision/split_files/clip_vision/clip_vision_h.safetensors"
            TARGET_FILE="$TARGET_DIR/clip_vision/clip_vision_h.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [3/3] sigclip_vision_patch14_384.safetensors
    echo "  [3/3] 下载: sigclip_vision_patch14_384.safetensors"
    if [ -f "$TARGET_DIR/clip_vision/sigclip_vision_patch14_384.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/sigclip_vision_384" "sigclip_vision_patch14_384.safetensors" --local-dir "$TARGET_DIR/clip_vision" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/clip_vision/sigclip_vision_patch14_384.safetensors"
            TARGET_FILE="$TARGET_DIR/clip_vision/sigclip_vision_patch14_384.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    echo ""
}

# 下载函数: controlnet
download_controlnet() {
    echo "==================== controlnet ===================="
    echo "下载 controlnet 目录的模型 (7 个)..."
    mkdir -p "$TARGET_DIR/controlnet"
    echo ""

    # [1/7] Qwen-Image-InstantX-ControlNet-Inpainting.safetensors
    echo "  [1/7] 下载: Qwen-Image-InstantX-ControlNet-Inpainting.safetensors"
    if [ -f "$TARGET_DIR/controlnet/Qwen-Image-InstantX-ControlNet-Inpainting.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Qwen-Image-InstantX-ControlNets" "split_files/controlnet/Qwen-Image-InstantX-ControlNet-Inpainting.safetensors" --local-dir "$TARGET_DIR/controlnet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/controlnet/split_files/controlnet/Qwen-Image-InstantX-ControlNet-Inpainting.safetensors"
            TARGET_FILE="$TARGET_DIR/controlnet/Qwen-Image-InstantX-ControlNet-Inpainting.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [2/7] control_v11f1p_sd15_depth_fp16.safetensors
    echo "  [2/7] 下载: control_v11f1p_sd15_depth_fp16.safetensors"
    if [ -f "$TARGET_DIR/controlnet/control_v11f1p_sd15_depth_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "comfyanonymous/ControlNet-v1-1_fp16_safetensors" "control_v11f1p_sd15_depth_fp16.safetensors" --local-dir "$TARGET_DIR/controlnet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/controlnet/control_v11f1p_sd15_depth_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/controlnet/control_v11f1p_sd15_depth_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [3/7] control_v11p_sd15_scribble_fp16.safetensors
    echo "  [3/7] 下载: control_v11p_sd15_scribble_fp16.safetensors"
    if [ -f "$TARGET_DIR/controlnet/control_v11p_sd15_scribble_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "comfyanonymous/ControlNet-v1-1_fp16_safetensors" "control_v11p_sd15_scribble_fp16.safetensors" --local-dir "$TARGET_DIR/controlnet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/controlnet/control_v11p_sd15_scribble_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/controlnet/control_v11p_sd15_scribble_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [4/7] qwen_image_canny_diffsynth_controlnet.safetensors
    echo "  [4/7] 下载: qwen_image_canny_diffsynth_controlnet.safetensors"
    if [ -f "$TARGET_DIR/controlnet/qwen_image_canny_diffsynth_controlnet.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Qwen-Image-DiffSynth-ControlNets" "split_files/model_patches/qwen_image_canny_diffsynth_controlnet.safetensors" --local-dir "$TARGET_DIR/controlnet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/controlnet/split_files/model_patches/qwen_image_canny_diffsynth_controlnet.safetensors"
            TARGET_FILE="$TARGET_DIR/controlnet/qwen_image_canny_diffsynth_controlnet.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [5/7] sd3.5_large_controlnet_blur.safetensors
    echo "  [5/7] 下载: sd3.5_large_controlnet_blur.safetensors"
    if [ -f "$TARGET_DIR/controlnet/sd3.5_large_controlnet_blur.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/stable-diffusion-3.5-controlnets_ComfyUI_repackaged" "split_files/controlnet/sd3.5_large_controlnet_blur.safetensors" --local-dir "$TARGET_DIR/controlnet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/controlnet/split_files/controlnet/sd3.5_large_controlnet_blur.safetensors"
            TARGET_FILE="$TARGET_DIR/controlnet/sd3.5_large_controlnet_blur.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [6/7] sd3.5_large_controlnet_canny.safetensors
    echo "  [6/7] 下载: sd3.5_large_controlnet_canny.safetensors"
    if [ -f "$TARGET_DIR/controlnet/sd3.5_large_controlnet_canny.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/stable-diffusion-3.5-controlnets_ComfyUI_repackaged" "split_files/controlnet/sd3.5_large_controlnet_canny.safetensors" --local-dir "$TARGET_DIR/controlnet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/controlnet/split_files/controlnet/sd3.5_large_controlnet_canny.safetensors"
            TARGET_FILE="$TARGET_DIR/controlnet/sd3.5_large_controlnet_canny.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [7/7] sd3.5_large_controlnet_depth.safetensors
    echo "  [7/7] 下载: sd3.5_large_controlnet_depth.safetensors"
    if [ -f "$TARGET_DIR/controlnet/sd3.5_large_controlnet_depth.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/stable-diffusion-3.5-controlnets_ComfyUI_repackaged" "split_files/controlnet/sd3.5_large_controlnet_depth.safetensors" --local-dir "$TARGET_DIR/controlnet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/controlnet/split_files/controlnet/sd3.5_large_controlnet_depth.safetensors"
            TARGET_FILE="$TARGET_DIR/controlnet/sd3.5_large_controlnet_depth.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    echo ""
}

# 下载函数: loras
download_loras() {
    echo "==================== loras ===================="
    echo "下载 loras 目录的模型 (17 个)..."
    mkdir -p "$TARGET_DIR/loras"
    echo ""

    # [1/17] Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors
    echo "  [1/17] 下载: Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors"
    if [ -f "$TARGET_DIR/loras/Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "lightx2v/Qwen-Image-Lightning" "Qwen-Image-Edit-2509/Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/Qwen-Image-Edit-2509/Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [2/17] Qwen-Image-Lightning-4steps-V1.0.safetensors
    echo "  [2/17] 下载: Qwen-Image-Lightning-4steps-V1.0.safetensors"
    if [ -f "$TARGET_DIR/loras/Qwen-Image-Lightning-4steps-V1.0.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "lightx2v/Qwen-Image-Lightning" "Qwen-Image-Lightning-4steps-V1.0.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/Qwen-Image-Lightning-4steps-V1.0.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/Qwen-Image-Lightning-4steps-V1.0.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [3/17] Qwen-Image-Lightning-8steps-V1.0.safetensors
    echo "  [3/17] 下载: Qwen-Image-Lightning-8steps-V1.0.safetensors"
    if [ -f "$TARGET_DIR/loras/Qwen-Image-Lightning-8steps-V1.0.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "lightx2v/Qwen-Image-Lightning" "Qwen-Image-Lightning-8steps-V1.0.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/Qwen-Image-Lightning-8steps-V1.0.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/Qwen-Image-Lightning-8steps-V1.0.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [4/17] Wan21_CausVid_14B_T2V_lora_rank32.safetensors
    echo "  [4/17] 下载: Wan21_CausVid_14B_T2V_lora_rank32.safetensors"
    if [ -f "$TARGET_DIR/loras/Wan21_CausVid_14B_T2V_lora_rank32.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Kijai/WanVideo_comfy" "Wan21_CausVid_14B_T2V_lora_rank32.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/Wan21_CausVid_14B_T2V_lora_rank32.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/Wan21_CausVid_14B_T2V_lora_rank32.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [5/17] Wan21_CausVid_bidirect2_T2V_1_3B_lora_rank32.safetensors
    echo "  [5/17] 下载: Wan21_CausVid_bidirect2_T2V_1_3B_lora_rank32.safetensors"
    if [ -f "$TARGET_DIR/loras/Wan21_CausVid_bidirect2_T2V_1_3B_lora_rank32.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Kijai/WanVideo_comfy" "Wan21_CausVid_bidirect2_T2V_1_3B_lora_rank32.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/Wan21_CausVid_bidirect2_T2V_1_3B_lora_rank32.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/Wan21_CausVid_bidirect2_T2V_1_3B_lora_rank32.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [6/17] WanAnimate_relight_lora_fp16.safetensors
    echo "  [6/17] 下载: WanAnimate_relight_lora_fp16.safetensors"
    if [ -f "$TARGET_DIR/loras/WanAnimate_relight_lora_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Kijai/WanVideo_comfy" "LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/WanAnimate_relight_lora_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [7/17] flux1-depth-dev-lora.safetensors
    echo "  [7/17] 下载: flux1-depth-dev-lora.safetensors"
    if [ -f "$TARGET_DIR/loras/flux1-depth-dev-lora.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/flux1-dev" "split_files/loras/flux1-depth-dev-lora.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/split_files/loras/flux1-depth-dev-lora.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/flux1-depth-dev-lora.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [8/17] flux2_berthe_morisot.safetensors
    echo "  [8/17] 下载: flux2_berthe_morisot.safetensors"
    if [ -f "$TARGET_DIR/loras/flux2_berthe_morisot.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "ostris/flux2_berthe_morisot" "flux2_berthe_morisot.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/flux2_berthe_morisot.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/flux2_berthe_morisot.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [9/17] lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors
    echo "  [9/17] 下载: lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"
    if [ -f "$TARGET_DIR/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Kijai/WanVideo_comfy" "Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [10/17] lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors
    echo "  [10/17] 下载: lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors"
    if [ -f "$TARGET_DIR/loras/lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Kijai/WanVideo_comfy" "Lightx2v/lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/Lightx2v/lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [11/17] pixel_art_style_z_image_turbo.safetensors
    echo "  [11/17] 下载: pixel_art_style_z_image_turbo.safetensors"
    if [ -f "$TARGET_DIR/loras/pixel_art_style_z_image_turbo.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "tarn59/pixel_art_style_lora_z_image_turbo" "pixel_art_style_z_image_turbo.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/pixel_art_style_z_image_turbo.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/pixel_art_style_z_image_turbo.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [12/17] qwen_image_union_diffsynth_lora.safetensors
    echo "  [12/17] 下载: qwen_image_union_diffsynth_lora.safetensors"
    if [ -f "$TARGET_DIR/loras/qwen_image_union_diffsynth_lora.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Qwen-Image-DiffSynth-ControlNets" "split_files/loras/qwen_image_union_diffsynth_lora.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/split_files/loras/qwen_image_union_diffsynth_lora.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/qwen_image_union_diffsynth_lora.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [13/17] wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors
    echo "  [13/17] 下载: wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
    if [ -f "$TARGET_DIR/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [14/17] wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors
    echo "  [14/17] 下载: wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"
    if [ -f "$TARGET_DIR/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [15/17] wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors
    echo "  [15/17] 下载: wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors"
    if [ -f "$TARGET_DIR/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [16/17] wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors
    echo "  [16/17] 下载: wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors"
    if [ -f "$TARGET_DIR/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [17/17] wan_alpha_2.1_rgba_lora.safetensors
    echo "  [17/17] 下载: wan_alpha_2.1_rgba_lora.safetensors"
    if [ -f "$TARGET_DIR/loras/wan_alpha_2.1_rgba_lora.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/loras/wan_alpha_2.1_rgba_lora.safetensors" --local-dir "$TARGET_DIR/loras" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/loras/split_files/loras/wan_alpha_2.1_rgba_lora.safetensors"
            TARGET_FILE="$TARGET_DIR/loras/wan_alpha_2.1_rgba_lora.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    echo ""
}

# 下载函数: style_models
download_style_models() {
    echo "==================== style_models ===================="
    echo "下载 style_models 目录的模型 (1 个)..."
    mkdir -p "$TARGET_DIR/style_models"
    echo ""

    # [1/1] flux1-redux-dev.safetensors
    echo "  [1/1] 下载: flux1-redux-dev.safetensors"
    if [ -f "$TARGET_DIR/style_models/flux1-redux-dev.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Flux1-Redux-Dev" "flux1-redux-dev.safetensors" --local-dir "$TARGET_DIR/style_models" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/style_models/flux1-redux-dev.safetensors"
            TARGET_FILE="$TARGET_DIR/style_models/flux1-redux-dev.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    echo ""
}

# 下载函数: unet
download_unet() {
    echo "==================== unet ===================="
    echo "下载 unet 目录的模型 (43 个)..."
    mkdir -p "$TARGET_DIR/unet"
    echo ""

    # [1/43] Chroma1-HD-fp8_scaled_rev2.safetensors
    echo "  [1/43] 下载: Chroma1-HD-fp8_scaled_rev2.safetensors"
    if [ -f "$TARGET_DIR/unet/Chroma1-HD-fp8_scaled_rev2.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "silveroxides/Chroma1-HD-fp8-scaled" "Chroma1-HD-fp8_scaled_rev2.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/Chroma1-HD-fp8_scaled_rev2.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/Chroma1-HD-fp8_scaled_rev2.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [2/43] Wan21-WanMove_fp8_scaled_e4m3fn_KJ.safetensors
    echo "  [2/43] 下载: Wan21-WanMove_fp8_scaled_e4m3fn_KJ.safetensors"
    if [ -f "$TARGET_DIR/unet/Wan21-WanMove_fp8_scaled_e4m3fn_KJ.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Kijai/WanVideo_comfy_fp8_scaled" "WanMove/Wan21-WanMove_fp8_scaled_e4m3fn_KJ.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/WanMove/Wan21-WanMove_fp8_scaled_e4m3fn_KJ.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/Wan21-WanMove_fp8_scaled_e4m3fn_KJ.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [3/43] Wan2_1-I2V-ATI-14B_fp8_e4m3fn.safetensors
    echo "  [3/43] 下载: Wan2_1-I2V-ATI-14B_fp8_e4m3fn.safetensors"
    if [ -f "$TARGET_DIR/unet/Wan2_1-I2V-ATI-14B_fp8_e4m3fn.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Kijai/WanVideo_comfy" "Wan2_1-I2V-ATI-14B_fp8_e4m3fn.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/Wan2_1-I2V-ATI-14B_fp8_e4m3fn.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/Wan2_1-I2V-ATI-14B_fp8_e4m3fn.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [4/43] Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors
    echo "  [4/43] 下载: Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors"
    if [ -f "$TARGET_DIR/unet/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Kijai/WanVideo_comfy_fp8_scaled" "Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [5/43] flux1-canny-dev.safetensors
    echo "  [5/43] 下载: flux1-canny-dev.safetensors"
    if [ -f "$TARGET_DIR/unet/flux1-canny-dev.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/flux1-dev" "split_files/diffusion_models/flux1-canny-dev.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/flux1-canny-dev.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/flux1-canny-dev.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [6/43] flux1-dev-fp8.safetensors
    echo "  [6/43] 下载: flux1-dev-fp8.safetensors"
    if [ -f "$TARGET_DIR/unet/flux1-dev-fp8.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/flux1-dev" "flux1-dev-fp8.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/flux1-dev-fp8.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/flux1-dev-fp8.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [7/43] flux1-dev.safetensors
    echo "  [7/43] 下载: flux1-dev.safetensors"
    if [ -f "$TARGET_DIR/unet/flux1-dev.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/flux1-dev" "flux1-dev.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/flux1-dev.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/flux1-dev.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [8/43] flux1-fill-dev.safetensors
    echo "  [8/43] 下载: flux1-fill-dev.safetensors"
    if [ -f "$TARGET_DIR/unet/flux1-fill-dev.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/flux1-dev" "split_files/diffusion_models/flux1-fill-dev.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/flux1-fill-dev.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/flux1-fill-dev.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [9/43] flux1-schnell.safetensors
    echo "  [9/43] 下载: flux1-schnell.safetensors"
    if [ -f "$TARGET_DIR/unet/flux1-schnell.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/flux1-schnell" "flux1-schnell.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/flux1-schnell.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/flux1-schnell.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [10/43] flux2_dev_fp8mixed.safetensors
    echo "  [10/43] 下载: flux2_dev_fp8mixed.safetensors"
    if [ -f "$TARGET_DIR/unet/flux2_dev_fp8mixed.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/flux2-dev" "split_files/diffusion_models/flux2_dev_fp8mixed.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/flux2_dev_fp8mixed.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/flux2_dev_fp8mixed.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [11/43] hidream_e1_full_bf16.safetensors
    echo "  [11/43] 下载: hidream_e1_full_bf16.safetensors"
    if [ -f "$TARGET_DIR/unet/hidream_e1_full_bf16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/HiDream-I1_ComfyUI" "split_files/diffusion_models/hidream_e1_full_bf16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/hidream_e1_full_bf16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/hidream_e1_full_bf16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [12/43] hidream_i1_fast_fp8.safetensors
    echo "  [12/43] 下载: hidream_i1_fast_fp8.safetensors"
    if [ -f "$TARGET_DIR/unet/hidream_i1_fast_fp8.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/HiDream-I1_ComfyUI" "split_files/diffusion_models/hidream_i1_fast_fp8.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/hidream_i1_fast_fp8.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/hidream_i1_fast_fp8.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [13/43] hidream_i1_full_fp8.safetensors
    echo "  [13/43] 下载: hidream_i1_full_fp8.safetensors"
    if [ -f "$TARGET_DIR/unet/hidream_i1_full_fp8.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/HiDream-I1_ComfyUI" "split_files/diffusion_models/hidream_i1_full_fp8.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/hidream_i1_full_fp8.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/hidream_i1_full_fp8.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [14/43] humo_17B_fp8_e4m3fn.safetensors
    echo "  [14/43] 下载: humo_17B_fp8_e4m3fn.safetensors"
    if [ -f "$TARGET_DIR/unet/humo_17B_fp8_e4m3fn.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/HuMo_ComfyUI" "split_files/diffusion_models/humo_17B_fp8_e4m3fn.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/humo_17B_fp8_e4m3fn.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/humo_17B_fp8_e4m3fn.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [15/43] hunyuanvideo1.5_1080p_sr_distilled_fp16.safetensors
    echo "  [15/43] 下载: hunyuanvideo1.5_1080p_sr_distilled_fp16.safetensors"
    if [ -f "$TARGET_DIR/unet/hunyuanvideo1.5_1080p_sr_distilled_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/HunyuanVideo_1.5_repackaged" "split_files/diffusion_models/hunyuanvideo1.5_1080p_sr_distilled_fp16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/hunyuanvideo1.5_1080p_sr_distilled_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/hunyuanvideo1.5_1080p_sr_distilled_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [16/43] hunyuanvideo1.5_720p_i2v_fp16.safetensors
    echo "  [16/43] 下载: hunyuanvideo1.5_720p_i2v_fp16.safetensors"
    if [ -f "$TARGET_DIR/unet/hunyuanvideo1.5_720p_i2v_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/HunyuanVideo_1.5_repackaged" "split_files/diffusion_models/hunyuanvideo1.5_720p_i2v_fp16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/hunyuanvideo1.5_720p_i2v_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/hunyuanvideo1.5_720p_i2v_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [17/43] hunyuanvideo1.5_720p_t2v_fp16.safetensors
    echo "  [17/43] 下载: hunyuanvideo1.5_720p_t2v_fp16.safetensors"
    if [ -f "$TARGET_DIR/unet/hunyuanvideo1.5_720p_t2v_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/HunyuanVideo_1.5_repackaged" "split_files/diffusion_models/hunyuanvideo1.5_720p_t2v_fp16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/hunyuanvideo1.5_720p_t2v_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/hunyuanvideo1.5_720p_t2v_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [18/43] omnigen2_fp16.safetensors
    echo "  [18/43] 下载: omnigen2_fp16.safetensors"
    if [ -f "$TARGET_DIR/unet/omnigen2_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Omnigen2_ComfyUI_repackaged" "split_files/diffusion_models/omnigen2_fp16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/omnigen2_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/omnigen2_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [19/43] qwen_image_edit_2509_fp8_e4m3fn.safetensors
    echo "  [19/43] 下载: qwen_image_edit_2509_fp8_e4m3fn.safetensors"
    if [ -f "$TARGET_DIR/unet/qwen_image_edit_2509_fp8_e4m3fn.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Qwen-Image-Edit_ComfyUI" "split_files/diffusion_models/qwen_image_edit_2509_fp8_e4m3fn.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/qwen_image_edit_2509_fp8_e4m3fn.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/qwen_image_edit_2509_fp8_e4m3fn.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [20/43] qwen_image_fp8_e4m3fn.safetensors
    echo "  [20/43] 下载: qwen_image_fp8_e4m3fn.safetensors"
    if [ -f "$TARGET_DIR/unet/qwen_image_fp8_e4m3fn.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Qwen-Image_ComfyUI" "split_files/diffusion_models/qwen_image_fp8_e4m3fn.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/qwen_image_fp8_e4m3fn.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/qwen_image_fp8_e4m3fn.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [21/43] wan2.1_flf2v_720p_14B_fp16.safetensors
    echo "  [21/43] 下载: wan2.1_flf2v_720p_14B_fp16.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.1_flf2v_720p_14B_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/diffusion_models/wan2.1_flf2v_720p_14B_fp16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.1_flf2v_720p_14B_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.1_flf2v_720p_14B_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [22/43] wan2.1_fun_camera_v1.1_1.3B_bf16.safetensors
    echo "  [22/43] 下载: wan2.1_fun_camera_v1.1_1.3B_bf16.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.1_fun_camera_v1.1_1.3B_bf16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/diffusion_models/wan2.1_fun_camera_v1.1_1.3B_bf16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.1_fun_camera_v1.1_1.3B_bf16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.1_fun_camera_v1.1_1.3B_bf16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [23/43] wan2.1_fun_camera_v1.1_14B_bf16.safetensors
    echo "  [23/43] 下载: wan2.1_fun_camera_v1.1_14B_bf16.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.1_fun_camera_v1.1_14B_bf16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/diffusion_models/wan2.1_fun_camera_v1.1_14B_bf16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.1_fun_camera_v1.1_14B_bf16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.1_fun_camera_v1.1_14B_bf16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [24/43] wan2.1_fun_control_1.3B_bf16.safetensors
    echo "  [24/43] 下载: wan2.1_fun_control_1.3B_bf16.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.1_fun_control_1.3B_bf16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/diffusion_models/wan2.1_fun_control_1.3B_bf16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.1_fun_control_1.3B_bf16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.1_fun_control_1.3B_bf16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [25/43] wan2.1_i2v_480p_14B_fp16.safetensors
    echo "  [25/43] 下载: wan2.1_i2v_480p_14B_fp16.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.1_i2v_480p_14B_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/diffusion_models/wan2.1_i2v_480p_14B_fp16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.1_i2v_480p_14B_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.1_i2v_480p_14B_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [26/43] wan2.1_t2v_14B_fp8_scaled.safetensors
    echo "  [26/43] 下载: wan2.1_t2v_14B_fp8_scaled.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.1_t2v_14B_fp8_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/diffusion_models/wan2.1_t2v_14B_fp8_scaled.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.1_t2v_14B_fp8_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.1_t2v_14B_fp8_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [27/43] wan2.1_vace_1.3B_fp16.safetensors
    echo "  [27/43] 下载: wan2.1_vace_1.3B_fp16.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.1_vace_1.3B_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/diffusion_models/wan2.1_vace_1.3B_fp16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.1_vace_1.3B_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.1_vace_1.3B_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [28/43] wan2.1_vace_14B_fp16.safetensors
    echo "  [28/43] 下载: wan2.1_vace_14B_fp16.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.1_vace_14B_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/diffusion_models/wan2.1_vace_14B_fp16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.1_vace_14B_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.1_vace_14B_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [29/43] wan2.2_fun_camera_high_noise_14B_fp8_scaled.safetensors
    echo "  [29/43] 下载: wan2.2_fun_camera_high_noise_14B_fp8_scaled.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.2_fun_camera_high_noise_14B_fp8_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_fun_camera_high_noise_14B_fp8_scaled.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.2_fun_camera_high_noise_14B_fp8_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.2_fun_camera_high_noise_14B_fp8_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [30/43] wan2.2_fun_camera_low_noise_14B_fp8_scaled.safetensors
    echo "  [30/43] 下载: wan2.2_fun_camera_low_noise_14B_fp8_scaled.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.2_fun_camera_low_noise_14B_fp8_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_fun_camera_low_noise_14B_fp8_scaled.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.2_fun_camera_low_noise_14B_fp8_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.2_fun_camera_low_noise_14B_fp8_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [31/43] wan2.2_fun_control_5B_bf16.safetensors
    echo "  [31/43] 下载: wan2.2_fun_control_5B_bf16.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.2_fun_control_5B_bf16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_fun_control_5B_bf16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.2_fun_control_5B_bf16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.2_fun_control_5B_bf16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [32/43] wan2.2_fun_control_high_noise_14B_fp8_scaled.safetensors
    echo "  [32/43] 下载: wan2.2_fun_control_high_noise_14B_fp8_scaled.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.2_fun_control_high_noise_14B_fp8_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_fun_control_high_noise_14B_fp8_scaled.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.2_fun_control_high_noise_14B_fp8_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.2_fun_control_high_noise_14B_fp8_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [33/43] wan2.2_fun_control_low_noise_14B_fp8_scaled.safetensors
    echo "  [33/43] 下载: wan2.2_fun_control_low_noise_14B_fp8_scaled.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.2_fun_control_low_noise_14B_fp8_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_fun_control_low_noise_14B_fp8_scaled.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.2_fun_control_low_noise_14B_fp8_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.2_fun_control_low_noise_14B_fp8_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [34/43] wan2.2_fun_inpaint_5B_bf16.safetensors
    echo "  [34/43] 下载: wan2.2_fun_inpaint_5B_bf16.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.2_fun_inpaint_5B_bf16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_fun_inpaint_5B_bf16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.2_fun_inpaint_5B_bf16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.2_fun_inpaint_5B_bf16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [35/43] wan2.2_fun_inpaint_high_noise_14B_fp8_scaled.safetensors
    echo "  [35/43] 下载: wan2.2_fun_inpaint_high_noise_14B_fp8_scaled.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.2_fun_inpaint_high_noise_14B_fp8_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_fun_inpaint_high_noise_14B_fp8_scaled.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.2_fun_inpaint_high_noise_14B_fp8_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.2_fun_inpaint_high_noise_14B_fp8_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [36/43] wan2.2_fun_inpaint_low_noise_14B_fp8_scaled.safetensors
    echo "  [36/43] 下载: wan2.2_fun_inpaint_low_noise_14B_fp8_scaled.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.2_fun_inpaint_low_noise_14B_fp8_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_fun_inpaint_low_noise_14B_fp8_scaled.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.2_fun_inpaint_low_noise_14B_fp8_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.2_fun_inpaint_low_noise_14B_fp8_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [37/43] wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors
    echo "  [37/43] 下载: wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [38/43] wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors
    echo "  [38/43] 下载: wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [39/43] wan2.2_s2v_14B_fp8_scaled.safetensors
    echo "  [39/43] 下载: wan2.2_s2v_14B_fp8_scaled.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.2_s2v_14B_fp8_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.2_s2v_14B_fp8_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [40/43] wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors
    echo "  [40/43] 下载: wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [41/43] wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors
    echo "  [41/43] 下载: wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [42/43] wan2.2_ti2v_5B_fp16.safetensors
    echo "  [42/43] 下载: wan2.2_ti2v_5B_fp16.safetensors"
    if [ -f "$TARGET_DIR/unet/wan2.2_ti2v_5B_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/diffusion_models/wan2.2_ti2v_5B_fp16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/wan2.2_ti2v_5B_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/wan2.2_ti2v_5B_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [43/43] z_image_turbo_bf16.safetensors
    echo "  [43/43] 下载: z_image_turbo_bf16.safetensors"
    if [ -f "$TARGET_DIR/unet/z_image_turbo_bf16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/z_image_turbo" "split_files/diffusion_models/z_image_turbo_bf16.safetensors" --local-dir "$TARGET_DIR/unet" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unet/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
            TARGET_FILE="$TARGET_DIR/unet/z_image_turbo_bf16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    echo ""
}

# 下载函数: unknown
download_unknown() {
    echo "==================== unknown ===================="
    echo "下载 unknown 目录的模型 (2 个)..."
    mkdir -p "$TARGET_DIR/unknown"
    echo ""

    # [1/2] Qwen-Image-Edit-2509-Relight.safetensors
    echo "  [1/2] 下载: Qwen-Image-Edit-2509-Relight.safetensors"
    if [ -f "$TARGET_DIR/unknown/Qwen-Image-Edit-2509-Relight.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Qwen-Image-Edit_ComfyUI" "split_files/loras/Qwen-Image-Edit-2509-Relight.safetensors" --local-dir "$TARGET_DIR/unknown" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unknown/split_files/loras/Qwen-Image-Edit-2509-Relight.safetensors"
            TARGET_FILE="$TARGET_DIR/unknown/Qwen-Image-Edit-2509-Relight.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [2/2] lotus-depth-d-v1-1.safetensors
    echo "  [2/2] 下载: lotus-depth-d-v1-1.safetensors"
    if [ -f "$TARGET_DIR/unknown/lotus-depth-d-v1-1.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/lotus" "lotus-depth-d-v1-1.safetensors" --local-dir "$TARGET_DIR/unknown" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/unknown/lotus-depth-d-v1-1.safetensors"
            TARGET_FILE="$TARGET_DIR/unknown/lotus-depth-d-v1-1.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    echo ""
}

# 下载函数: vae
download_vae() {
    echo "==================== vae ===================="
    echo "下载 vae 目录的模型 (9 个)..."
    mkdir -p "$TARGET_DIR/vae"
    echo ""

    # [1/9] ae.safetensors
    echo "  [1/9] 下载: ae.safetensors"
    if [ -f "$TARGET_DIR/vae/ae.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/z_image_turbo" "split_files/vae/ae.safetensors" --local-dir "$TARGET_DIR/vae" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/vae/split_files/vae/ae.safetensors"
            TARGET_FILE="$TARGET_DIR/vae/ae.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [2/9] flux2-vae.safetensors
    echo "  [2/9] 下载: flux2-vae.safetensors"
    if [ -f "$TARGET_DIR/vae/flux2-vae.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/flux2-dev" "split_files/vae/flux2-vae.safetensors" --local-dir "$TARGET_DIR/vae" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/vae/split_files/vae/flux2-vae.safetensors"
            TARGET_FILE="$TARGET_DIR/vae/flux2-vae.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [3/9] hunyuanvideo15_vae_fp16.safetensors
    echo "  [3/9] 下载: hunyuanvideo15_vae_fp16.safetensors"
    if [ -f "$TARGET_DIR/vae/hunyuanvideo15_vae_fp16.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/HunyuanVideo_1.5_repackaged" "split_files/vae/hunyuanvideo15_vae_fp16.safetensors" --local-dir "$TARGET_DIR/vae" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/vae/split_files/vae/hunyuanvideo15_vae_fp16.safetensors"
            TARGET_FILE="$TARGET_DIR/vae/hunyuanvideo15_vae_fp16.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [4/9] qwen_image_vae.safetensors
    echo "  [4/9] 下载: qwen_image_vae.safetensors"
    if [ -f "$TARGET_DIR/vae/qwen_image_vae.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Qwen-Image_ComfyUI" "split_files/vae/qwen_image_vae.safetensors" --local-dir "$TARGET_DIR/vae" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/vae/split_files/vae/qwen_image_vae.safetensors"
            TARGET_FILE="$TARGET_DIR/vae/qwen_image_vae.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [5/9] vae-ft-mse-840000-ema-pruned.safetensors
    echo "  [5/9] 下载: vae-ft-mse-840000-ema-pruned.safetensors"
    if [ -f "$TARGET_DIR/vae/vae-ft-mse-840000-ema-pruned.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "stabilityai/sd-vae-ft-mse-original" "vae-ft-mse-840000-ema-pruned.safetensors" --local-dir "$TARGET_DIR/vae" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/vae/vae-ft-mse-840000-ema-pruned.safetensors"
            TARGET_FILE="$TARGET_DIR/vae/vae-ft-mse-840000-ema-pruned.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [6/9] wan2.2_vae.safetensors
    echo "  [6/9] 下载: wan2.2_vae.safetensors"
    if [ -f "$TARGET_DIR/vae/wan2.2_vae.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/vae/wan2.2_vae.safetensors" --local-dir "$TARGET_DIR/vae" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/vae/split_files/vae/wan2.2_vae.safetensors"
            TARGET_FILE="$TARGET_DIR/vae/wan2.2_vae.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [7/9] wan_2.1_vae.safetensors
    echo "  [7/9] 下载: wan_2.1_vae.safetensors"
    if [ -f "$TARGET_DIR/vae/wan_2.1_vae.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/vae/wan_2.1_vae.safetensors" --local-dir "$TARGET_DIR/vae" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/vae/split_files/vae/wan_2.1_vae.safetensors"
            TARGET_FILE="$TARGET_DIR/vae/wan_2.1_vae.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [8/9] wan_alpha_2.1_vae_alpha_channel.safetensors
    echo "  [8/9] 下载: wan_alpha_2.1_vae_alpha_channel.safetensors"
    if [ -f "$TARGET_DIR/vae/wan_alpha_2.1_vae_alpha_channel.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/vae/wan_alpha_2.1_vae_alpha_channel.safetensors" --local-dir "$TARGET_DIR/vae" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/vae/split_files/vae/wan_alpha_2.1_vae_alpha_channel.safetensors"
            TARGET_FILE="$TARGET_DIR/vae/wan_alpha_2.1_vae_alpha_channel.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    # [9/9] wan_alpha_2.1_vae_rgb_channel.safetensors
    echo "  [9/9] 下载: wan_alpha_2.1_vae_rgb_channel.safetensors"
    if [ -f "$TARGET_DIR/vae/wan_alpha_2.1_vae_rgb_channel.safetensors" ]; then
        echo "      ✓ 已存在，跳过"
        ((SKIPPED++))
    else
        hf download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/vae/wan_alpha_2.1_vae_rgb_channel.safetensors" --local-dir "$TARGET_DIR/vae" --revision main
        if [ $? -eq 0 ]; then
            SOURCE_FILE="$TARGET_DIR/vae/split_files/vae/wan_alpha_2.1_vae_rgb_channel.safetensors"
            TARGET_FILE="$TARGET_DIR/vae/wan_alpha_2.1_vae_rgb_channel.safetensors"
            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
            fi
            echo "      ✓ 下载完成"
            ((SUCCESS++))
        else
            echo "      ✗ 下载失败"
            ((FAILED++))
        fi
    fi

    echo ""
}

# 执行下载
for dir in "${SELECTED_DIRS[@]}"; do
    func_name="download_${dir//-/_}"
    if declare -f "$func_name" > /dev/null; then
        $func_name
    fi
done

# ==================== 其他来源 ====================
echo ""
echo "以下模型来自其他来源，需要手动下载:"
echo "  - architecturerealmix_v11.safetensors (checkpoints)"
echo "    URL: https://civitai.com/api/download/models/431755?type=Model&format=SafeTensor&size=full&fp=fp16"
echo "  - dreamshaper_8.safetensors (checkpoints)"
echo "    URL: https://civitai.com/api/download/models/128713?type=Model&format=SafeTensor&size=pruned&fp=fp16"
echo "  - MoXinV1.safetensors (loras)"
echo "    URL: https://civitai.com/api/download/models/14856?type=Model&format=SafeTensor&size=full&fp=fp16"
echo "  - blindbox_v1_mix.safetensors (loras)"
echo "    URL: https://civitai.com/api/download/models/32988?type=Model&format=SafeTensor&size=full&fp=fp16"

# 显示统计
echo ""
echo "======================================"
echo "下载完成!"
echo "======================================"
echo "成功: $SUCCESS"
echo "跳过: $SKIPPED"
echo "失败: $FAILED"
echo "总计: $((SUCCESS + SKIPPED + FAILED))"
echo "======================================"
