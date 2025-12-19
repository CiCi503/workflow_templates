#!/bin/bash
#
# 使用 huggingface-cli 批量下载 ComfyUI 模型
#
# 只下载目录: loras, controlnet
#
# 安装依赖:
#   pip install huggingface_hub
#
# 设置 Token:
#   export HF_TOKEN=your_token_here
#   或: huggingface-cli login
#

TARGET_DIR="/root/dehui/models"

# 检查是否安装了 huggingface-cli
if ! command -v huggingface-cli &> /dev/null; then
    echo "错误: 未找到 huggingface-cli"
    echo "请运行: pip install huggingface_hub"
    exit 1
fi

echo "开始下载模型到: $TARGET_DIR"
echo "总计: 24 个 Hugging Face 模型"
echo "目录: loras, controlnet"
echo ""

# 统计
SUCCESS=0
FAILED=0
SKIPPED=0

# ==================== controlnet ====================
echo "下载 controlnet 目录的模型..."
mkdir -p "$TARGET_DIR/controlnet"

# [1/7] Qwen-Image-InstantX-ControlNet-Inpainting.safetensors
echo "  下载: Qwen-Image-InstantX-ControlNet-Inpainting.safetensors"
if [ -f "$TARGET_DIR/controlnet/Qwen-Image-InstantX-ControlNet-Inpainting.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Comfy-Org/Qwen-Image-InstantX-ControlNets" "split_files/controlnet/Qwen-Image-InstantX-ControlNet-Inpainting.safetensors" --local-dir "$TARGET_DIR/controlnet" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/controlnet/split_files/controlnet/Qwen-Image-InstantX-ControlNet-Inpainting.safetensors"
        TARGET_FILE="$TARGET_DIR/controlnet/Qwen-Image-InstantX-ControlNet-Inpainting.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [2/7] control_v11f1p_sd15_depth_fp16.safetensors
echo "  下载: control_v11f1p_sd15_depth_fp16.safetensors"
if [ -f "$TARGET_DIR/controlnet/control_v11f1p_sd15_depth_fp16.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "comfyanonymous/ControlNet-v1-1_fp16_safetensors" "control_v11f1p_sd15_depth_fp16.safetensors" --local-dir "$TARGET_DIR/controlnet" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/controlnet/control_v11f1p_sd15_depth_fp16.safetensors"
        TARGET_FILE="$TARGET_DIR/controlnet/control_v11f1p_sd15_depth_fp16.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [3/7] control_v11p_sd15_scribble_fp16.safetensors
echo "  下载: control_v11p_sd15_scribble_fp16.safetensors"
if [ -f "$TARGET_DIR/controlnet/control_v11p_sd15_scribble_fp16.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "comfyanonymous/ControlNet-v1-1_fp16_safetensors" "control_v11p_sd15_scribble_fp16.safetensors" --local-dir "$TARGET_DIR/controlnet" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/controlnet/control_v11p_sd15_scribble_fp16.safetensors"
        TARGET_FILE="$TARGET_DIR/controlnet/control_v11p_sd15_scribble_fp16.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [4/7] qwen_image_canny_diffsynth_controlnet.safetensors
echo "  下载: qwen_image_canny_diffsynth_controlnet.safetensors"
if [ -f "$TARGET_DIR/controlnet/qwen_image_canny_diffsynth_controlnet.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Comfy-Org/Qwen-Image-DiffSynth-ControlNets" "split_files/model_patches/qwen_image_canny_diffsynth_controlnet.safetensors" --local-dir "$TARGET_DIR/controlnet" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/controlnet/split_files/model_patches/qwen_image_canny_diffsynth_controlnet.safetensors"
        TARGET_FILE="$TARGET_DIR/controlnet/qwen_image_canny_diffsynth_controlnet.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [5/7] sd3.5_large_controlnet_blur.safetensors
echo "  下载: sd3.5_large_controlnet_blur.safetensors"
if [ -f "$TARGET_DIR/controlnet/sd3.5_large_controlnet_blur.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Comfy-Org/stable-diffusion-3.5-controlnets_ComfyUI_repackaged" "split_files/controlnet/sd3.5_large_controlnet_blur.safetensors" --local-dir "$TARGET_DIR/controlnet" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/controlnet/split_files/controlnet/sd3.5_large_controlnet_blur.safetensors"
        TARGET_FILE="$TARGET_DIR/controlnet/sd3.5_large_controlnet_blur.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [6/7] sd3.5_large_controlnet_canny.safetensors
echo "  下载: sd3.5_large_controlnet_canny.safetensors"
if [ -f "$TARGET_DIR/controlnet/sd3.5_large_controlnet_canny.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Comfy-Org/stable-diffusion-3.5-controlnets_ComfyUI_repackaged" "split_files/controlnet/sd3.5_large_controlnet_canny.safetensors" --local-dir "$TARGET_DIR/controlnet" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/controlnet/split_files/controlnet/sd3.5_large_controlnet_canny.safetensors"
        TARGET_FILE="$TARGET_DIR/controlnet/sd3.5_large_controlnet_canny.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [7/7] sd3.5_large_controlnet_depth.safetensors
echo "  下载: sd3.5_large_controlnet_depth.safetensors"
if [ -f "$TARGET_DIR/controlnet/sd3.5_large_controlnet_depth.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Comfy-Org/stable-diffusion-3.5-controlnets_ComfyUI_repackaged" "split_files/controlnet/sd3.5_large_controlnet_depth.safetensors" --local-dir "$TARGET_DIR/controlnet" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/controlnet/split_files/controlnet/sd3.5_large_controlnet_depth.safetensors"
        TARGET_FILE="$TARGET_DIR/controlnet/sd3.5_large_controlnet_depth.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# ==================== loras ====================
echo "下载 loras 目录的模型..."
mkdir -p "$TARGET_DIR/loras"

# [1/17] Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors
echo "  下载: Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors"
if [ -f "$TARGET_DIR/loras/Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "lightx2v/Qwen-Image-Lightning" "Qwen-Image-Edit-2509/Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/Qwen-Image-Edit-2509/Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [2/17] Qwen-Image-Lightning-4steps-V1.0.safetensors
echo "  下载: Qwen-Image-Lightning-4steps-V1.0.safetensors"
if [ -f "$TARGET_DIR/loras/Qwen-Image-Lightning-4steps-V1.0.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "lightx2v/Qwen-Image-Lightning" "Qwen-Image-Lightning-4steps-V1.0.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/Qwen-Image-Lightning-4steps-V1.0.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/Qwen-Image-Lightning-4steps-V1.0.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [3/17] Qwen-Image-Lightning-8steps-V1.0.safetensors
echo "  下载: Qwen-Image-Lightning-8steps-V1.0.safetensors"
if [ -f "$TARGET_DIR/loras/Qwen-Image-Lightning-8steps-V1.0.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "lightx2v/Qwen-Image-Lightning" "Qwen-Image-Lightning-8steps-V1.0.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/Qwen-Image-Lightning-8steps-V1.0.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/Qwen-Image-Lightning-8steps-V1.0.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [4/17] Wan21_CausVid_14B_T2V_lora_rank32.safetensors
echo "  下载: Wan21_CausVid_14B_T2V_lora_rank32.safetensors"
if [ -f "$TARGET_DIR/loras/Wan21_CausVid_14B_T2V_lora_rank32.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Kijai/WanVideo_comfy" "Wan21_CausVid_14B_T2V_lora_rank32.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/Wan21_CausVid_14B_T2V_lora_rank32.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/Wan21_CausVid_14B_T2V_lora_rank32.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [5/17] Wan21_CausVid_bidirect2_T2V_1_3B_lora_rank32.safetensors
echo "  下载: Wan21_CausVid_bidirect2_T2V_1_3B_lora_rank32.safetensors"
if [ -f "$TARGET_DIR/loras/Wan21_CausVid_bidirect2_T2V_1_3B_lora_rank32.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Kijai/WanVideo_comfy" "Wan21_CausVid_bidirect2_T2V_1_3B_lora_rank32.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/Wan21_CausVid_bidirect2_T2V_1_3B_lora_rank32.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/Wan21_CausVid_bidirect2_T2V_1_3B_lora_rank32.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [6/17] WanAnimate_relight_lora_fp16.safetensors
echo "  下载: WanAnimate_relight_lora_fp16.safetensors"
if [ -f "$TARGET_DIR/loras/WanAnimate_relight_lora_fp16.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Kijai/WanVideo_comfy" "LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/WanAnimate_relight_lora_fp16.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [7/17] flux1-depth-dev-lora.safetensors
echo "  下载: flux1-depth-dev-lora.safetensors"
if [ -f "$TARGET_DIR/loras/flux1-depth-dev-lora.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Comfy-Org/flux1-dev" "split_files/loras/flux1-depth-dev-lora.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/split_files/loras/flux1-depth-dev-lora.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/flux1-depth-dev-lora.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [8/17] flux2_berthe_morisot.safetensors
echo "  下载: flux2_berthe_morisot.safetensors"
if [ -f "$TARGET_DIR/loras/flux2_berthe_morisot.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "ostris/flux2_berthe_morisot" "flux2_berthe_morisot.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/flux2_berthe_morisot.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/flux2_berthe_morisot.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [9/17] lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors
echo "  下载: lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"
if [ -f "$TARGET_DIR/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Kijai/WanVideo_comfy" "Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [10/17] lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors
echo "  下载: lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors"
if [ -f "$TARGET_DIR/loras/lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Kijai/WanVideo_comfy" "Lightx2v/lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/Lightx2v/lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/lightx2v_T2V_14B_cfg_step_distill_v2_lora_rank64_bf16.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [11/17] pixel_art_style_z_image_turbo.safetensors
echo "  下载: pixel_art_style_z_image_turbo.safetensors"
if [ -f "$TARGET_DIR/loras/pixel_art_style_z_image_turbo.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "tarn59/pixel_art_style_lora_z_image_turbo" "pixel_art_style_z_image_turbo.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/pixel_art_style_z_image_turbo.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/pixel_art_style_z_image_turbo.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [12/17] qwen_image_union_diffsynth_lora.safetensors
echo "  下载: qwen_image_union_diffsynth_lora.safetensors"
if [ -f "$TARGET_DIR/loras/qwen_image_union_diffsynth_lora.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Comfy-Org/Qwen-Image-DiffSynth-ControlNets" "split_files/loras/qwen_image_union_diffsynth_lora.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/split_files/loras/qwen_image_union_diffsynth_lora.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/qwen_image_union_diffsynth_lora.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [13/17] wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors
echo "  下载: wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
if [ -f "$TARGET_DIR/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [14/17] wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors
echo "  下载: wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"
if [ -f "$TARGET_DIR/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [15/17] wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors
echo "  下载: wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors"
if [ -f "$TARGET_DIR/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [16/17] wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors
echo "  下载: wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors"
if [ -f "$TARGET_DIR/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi

# [17/17] wan_alpha_2.1_rgba_lora.safetensors
echo "  下载: wan_alpha_2.1_rgba_lora.safetensors"
if [ -f "$TARGET_DIR/loras/wan_alpha_2.1_rgba_lora.safetensors" ]; then
    echo "  ✓ 已存在，跳过"
    ((SKIPPED++))
else
    huggingface-cli download "Comfy-Org/Wan_2.1_ComfyUI_repackaged" "split_files/loras/wan_alpha_2.1_rgba_lora.safetensors" --local-dir "$TARGET_DIR/loras" --local-dir-use-symlinks False --revision main
    if [ $? -eq 0 ]; then
        SOURCE_FILE="$TARGET_DIR/loras/split_files/loras/wan_alpha_2.1_rgba_lora.safetensors"
        TARGET_FILE="$TARGET_DIR/loras/wan_alpha_2.1_rgba_lora.safetensors"
        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then
            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true
            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true
        fi
        echo "  ✓ 下载完成"
        ((SUCCESS++))
    else
        echo "  ✗ 下载失败"
        ((FAILED++))
    fi
fi


# ==================== 其他来源 ====================
echo ""
echo "以下模型来自其他来源，需要手动下载:"
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
echo "总计: 24"
echo "======================================"
