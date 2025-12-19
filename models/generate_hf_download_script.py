#!/usr/bin/env python3
"""
生成使用 huggingface-cli 下载模型的脚本（支持命令行参数）
"""

import csv
import re
from pathlib import Path
from urllib.parse import urlparse

def parse_hf_url(url):
    """
    解析 Hugging Face URL，提取 repo_id 和 file_path
    
    URL 格式: https://huggingface.co/{repo_id}/resolve/{revision}/{file_path}
    或: https://huggingface.co/{repo_id}/blob/{revision}/{file_path}
    """
    if not url.startswith('https://huggingface.co/'):
        return None
    
    # 移除 query string
    url = url.split('?')[0]
    
    # 匹配模式
    pattern = r'https://huggingface\.co/([^/]+/[^/]+)/(resolve|blob)/([^/]+)/(.+)'
    match = re.match(pattern, url)
    
    if match:
        repo_id = match.group(1)
        revision = match.group(3)
        file_path = match.group(4)
        return {
            'repo_id': repo_id,
            'revision': revision,
            'file_path': file_path
        }
    
    return None

def generate_bash_script(csv_file, output_file, target_dir='/root/dehui/models'):
    """生成支持命令行参数的 Bash 下载脚本"""
    
    models = []
    other_sources = []
    
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            directory = row['目录']
            model_name = row['模型名称']
            url = row['下载地址']
            
            if not url or url == '⚠️ 未提供':
                continue
            
            if url.startswith('https://huggingface.co/'):
                parsed = parse_hf_url(url)
                if parsed:
                    models.append({
                        'directory': directory,
                        'name': model_name,
                        'repo_id': parsed['repo_id'],
                        'file_path': parsed['file_path'],
                        'revision': parsed['revision']
                    })
            else:
                other_sources.append({
                    'directory': directory,
                    'name': model_name,
                    'url': url
                })
    
    # 按目录分组
    models_by_dir = {}
    for model in models:
        directory = model['directory']
        if directory not in models_by_dir:
            models_by_dir[directory] = []
        models_by_dir[directory].append(model)
    
    all_dirs = sorted(models_by_dir.keys())
    
    # 生成脚本头部
    script_lines = [
        '#!/bin/bash',
        '#',
        '# 使用 hf download 批量下载 ComfyUI 模型',
        '#',
        '# 安装依赖:',
        '#   pip install huggingface_hub',
        '#',
        '# 设置 Token:',
        '#   export HF_TOKEN=your_token_here',
        '#   或: huggingface-cli login',
        '#',
        '# 使用方法:',
        '#   下载所有模型:',
        '#     ./download_with_hf.sh',
        '#',
        '#   只下载指定目录:',
        '#     ./download_with_hf.sh --dirs loras controlnet',
        '#     ./download_with_hf.sh -d unet clip vae',
        '#',
        '#   自定义目标目录:',
        '#     ./download_with_hf.sh --target-dir /custom/path',
        '#',
        '#   查看帮助:',
        '#     ./download_with_hf.sh --help',
        '#',
        '',
        f'DEFAULT_TARGET_DIR="{target_dir}"',
        'TARGET_DIR="$DEFAULT_TARGET_DIR"',
        f'ALL_DIRS=({" ".join(all_dirs)})',
        'SELECTED_DIRS=()',
        '',
        '# 解析命令行参数',
        'while [[ $# -gt 0 ]]; do',
        '    case $1 in',
        '        -d|--dirs)',
        '            shift',
        '            while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do',
        '                SELECTED_DIRS+=("$1")',
        '                shift',
        '            done',
        '            ;;',
        '        -t|--target-dir)',
        '            TARGET_DIR="$2"',
        '            shift 2',
        '            ;;',
        '        -h|--help)',
        '            echo "使用方法: $0 [选项]"',
        '            echo ""',
        '            echo "选项:"',
        '            echo "  -d, --dirs <目录...>     只下载指定目录的模型"',
        '            echo "  -t, --target-dir <路径>  指定下载目标目录（默认: $DEFAULT_TARGET_DIR）"',
        '            echo "  -h, --help              显示此帮助信息"',
        '            echo ""',
        '            echo "可用目录:"',
        f'            echo "  {" ".join(all_dirs)}"',
        '            echo ""',
        '            echo "示例:"',
        '            echo "  $0                              # 下载所有模型"',
        '            echo "  $0 --dirs loras controlnet      # 只下载 loras 和 controlnet"',
        '            echo "  $0 -d unet clip vae             # 只下载 unet、clip 和 vae"',
        '            echo "  $0 --target-dir /custom/path    # 下载到自定义目录"',
        '            exit 0',
        '            ;;',
        '        *)',
        '            echo "错误: 未知参数 $1"',
        '            echo "运行 $0 --help 查看帮助"',
        '            exit 1',
        '            ;;',
        '    esac',
        'done',
        '',
        '# 如果没有指定目录，下载所有目录',
        'if [ ${#SELECTED_DIRS[@]} -eq 0 ]; then',
        '    SELECTED_DIRS=("${ALL_DIRS[@]}")',
        'fi',
        '',
        '# 验证选择的目录',
        'for dir in "${SELECTED_DIRS[@]}"; do',
        '    if [[ ! " ${ALL_DIRS[@]} " =~ " ${dir} " ]]; then',
        '        echo "错误: 无效的目录 \'$dir\'"',
        '        echo "可用目录: ${ALL_DIRS[@]}"',
        '        exit 1',
        '    fi',
        'done',
        '',
        '# 检查是否安装了 hf',
        'if ! command -v hf &> /dev/null; then',
        '    echo "错误: 未找到 hf 命令"',
        '    echo "请运行: pip install huggingface_hub"',
        '    exit 1',
        'fi',
        '',
        'echo "======================================"',
        'echo "开始下载 ComfyUI 模型"',
        'echo "======================================"',
        'echo "目标目录: $TARGET_DIR"',
        'echo "选择目录: ${SELECTED_DIRS[@]}"',
        'echo ""',
        '',
        '# 统计',
        'SUCCESS=0',
        'FAILED=0',
        'SKIPPED=0',
        '',
    ]
    
    # 为每个目录生成下载函数
    for directory in all_dirs:
        dir_models = models_by_dir[directory]
        script_lines.append(f'# 下载函数: {directory}')
        script_lines.append(f'download_{directory.replace("-", "_")}() {{')
        script_lines.append(f'    echo "==================== {directory} ===================="')
        script_lines.append(f'    echo "下载 {directory} 目录的模型 ({len(dir_models)} 个)..."')
        script_lines.append(f'    mkdir -p "$TARGET_DIR/{directory}"')
        script_lines.append(f'    echo ""')
        script_lines.append('')
        
        for i, model in enumerate(dir_models, 1):
            script_lines.append(f'    # [{i}/{len(dir_models)}] {model["name"]}')
            script_lines.append(f'    echo "  [{i}/{len(dir_models)}] 下载: {model["name"]}"')
            
            cmd = (
                f'hf download "{model["repo_id"]}" '
                f'"{model["file_path"]}" '
                f'--local-dir "$TARGET_DIR/{directory}" '
                f'--revision {model["revision"]}'
            )
            
            script_lines.append(f'    if [ -f "$TARGET_DIR/{directory}/{model["name"]}" ]; then')
            script_lines.append(f'        echo "      ✓ 已存在，跳过"')
            script_lines.append(f'        ((SKIPPED++))')
            script_lines.append(f'    else')
            script_lines.append(f'        {cmd}')
            script_lines.append(f'        if [ $? -eq 0 ]; then')
            script_lines.append(f'            SOURCE_FILE="$TARGET_DIR/{directory}/{model["file_path"]}"')
            script_lines.append(f'            TARGET_FILE="$TARGET_DIR/{directory}/{model["name"]}"')
            script_lines.append(f'            if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then')
            script_lines.append(f'                mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true')
            script_lines.append(f'                rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true')
            script_lines.append(f'            fi')
            script_lines.append(f'            echo "      ✓ 下载完成"')
            script_lines.append(f'            ((SUCCESS++))')
            script_lines.append(f'        else')
            script_lines.append(f'            echo "      ✗ 下载失败"')
            script_lines.append(f'            ((FAILED++))')
            script_lines.append(f'        fi')
            script_lines.append(f'    fi')
            script_lines.append('')
        
        script_lines.append(f'    echo ""')
        script_lines.append(f'}}')
        script_lines.append('')
    
    # 主执行逻辑
    script_lines.extend([
        '# 执行下载',
        'for dir in "${SELECTED_DIRS[@]}"; do',
        '    func_name="download_${dir//-/_}"',
        '    if declare -f "$func_name" > /dev/null; then',
        '        $func_name',
        '    fi',
        'done',
        '',
    ])
    
    # 其他来源的提示
    if other_sources:
        script_lines.append('# ==================== 其他来源 ====================')
        script_lines.append('echo ""')
        script_lines.append('echo "以下模型来自其他来源，需要手动下载:"')
        for model in other_sources:
            script_lines.append(f'echo "  - {model["name"]} ({model["directory"]})"')
            script_lines.append(f'echo "    URL: {model["url"]}"')
        script_lines.append('')
    
    # 统计信息
    script_lines.extend([
        '# 显示统计',
        'echo ""',
        'echo "======================================"',
        'echo "下载完成!"',
        'echo "======================================"',
        'echo "成功: $SUCCESS"',
        'echo "跳过: $SKIPPED"',
        'echo "失败: $FAILED"',
        'echo "总计: $((SUCCESS + SKIPPED + FAILED))"',
        'echo "======================================"',
    ])
    
    # 写入文件
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(script_lines))
        f.write('\n')
    
    print(f"✓ 已生成脚本: {output_file}")
    print(f"  Hugging Face 模型: {len(models)}")
    print(f"  按目录分组: {len(models_by_dir)} 个目录")
    print(f"  可用目录: {', '.join(all_dirs)}")
    print(f"  其他来源模型: {len(other_sources)}")
    print(f"\n使用方法:")
    print(f"  chmod +x {output_file}")
    print(f"  ./{output_file}                          # 下载所有模型")
    print(f"  ./{output_file} --dirs loras controlnet  # 只下载指定目录")

def main():
    csv_file = 'models_table.csv'
    output_file = 'download_with_hf.sh'
    
    if not Path(csv_file).exists():
        print(f"错误: 找不到 {csv_file}")
        return
    
    generate_bash_script(csv_file, output_file)

if __name__ == "__main__":
    main()
