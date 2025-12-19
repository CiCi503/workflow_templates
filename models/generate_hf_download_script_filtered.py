#!/usr/bin/env python3
"""
生成使用 huggingface-cli 下载模型的脚本（支持过滤目录）
"""

import csv
import re
import sys
from pathlib import Path
from urllib.parse import urlparse

def parse_hf_url(url):
    """解析 Hugging Face URL"""
    if not url.startswith('https://huggingface.co/'):
        return None
    
    url = url.split('?')[0]
    pattern = r'https://huggingface\.co/([^/]+/[^/]+)/(resolve|blob)/([^/]+)/(.+)'
    match = re.match(pattern, url)
    
    if match:
        return {
            'repo_id': match.group(1),
            'revision': match.group(3),
            'file_path': match.group(4)
        }
    return None

def generate_bash_script(csv_file, output_file, target_dir='/root/dehui/models', filter_dirs=None):
    """
    生成 Bash 下载脚本
    
    Args:
        csv_file: CSV 文件路径
        output_file: 输出脚本路径
        target_dir: 目标目录
        filter_dirs: 要下载的目录列表（None 表示全部）
    """
    
    models = []
    other_sources = []
    
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            directory = row['目录']
            model_name = row['模型名称']
            url = row['下载地址']
            
            # 过滤目录
            if filter_dirs and directory not in filter_dirs:
                continue
            
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
    
    # 生成脚本
    script_lines = [
        '#!/bin/bash',
        '#',
        '# 使用 hf download 批量下载 ComfyUI 模型',
        '#',
    ]
    
    if filter_dirs:
        script_lines.append(f'# 只下载目录: {", ".join(filter_dirs)}')
        script_lines.append('#')
    
    script_lines.extend([
        '# 安装依赖:',
        '#   pip install huggingface_hub',
        '#',
        '# 设置 Token:',
        '#   export HF_TOKEN=your_token_here',
        '#   或: huggingface-cli login',
        '#',
        '',
        f'TARGET_DIR="{target_dir}"',
        '',
        '# 检查是否安装了 hf',
        'if ! command -v hf &> /dev/null; then',
        '    echo "错误: 未找到 hf 命令"',
        '    echo "请运行: pip install huggingface_hub"',
        '    exit 1',
        'fi',
        '',
        'echo "开始下载模型到: $TARGET_DIR"',
        f'echo "总计: {len(models)} 个 Hugging Face 模型"',
    ])
    
    if filter_dirs:
        script_lines.append(f'echo "目录: {", ".join(filter_dirs)}"')
    
    script_lines.extend([
        'echo ""',
        '',
        '# 统计',
        'SUCCESS=0',
        'FAILED=0',
        'SKIPPED=0',
        '',
    ])
    
    # 按目录分组
    models_by_dir = {}
    for model in models:
        directory = model['directory']
        if directory not in models_by_dir:
            models_by_dir[directory] = []
        models_by_dir[directory].append(model)
    
    # 生成下载命令
    for directory in sorted(models_by_dir.keys()):
        script_lines.append(f'# ==================== {directory} ====================')
        script_lines.append(f'echo "下载 {directory} 目录的模型..."')
        script_lines.append(f'mkdir -p "$TARGET_DIR/{directory}"')
        script_lines.append('')
        
        for i, model in enumerate(models_by_dir[directory], 1):
            script_lines.append(f'# [{i}/{len(models_by_dir[directory])}] {model["name"]}')
            script_lines.append(f'echo "  下载: {model["name"]}"')
            
            cmd = (
                f'hf download "{model["repo_id"]}" '
                f'"{model["file_path"]}" '
                f'--local-dir "$TARGET_DIR/{directory}" '
                f'--revision {model["revision"]}'
            )
            
            script_lines.append(f'if [ -f "$TARGET_DIR/{directory}/{model["name"]}" ]; then')
            script_lines.append(f'    echo "  ✓ 已存在，跳过"')
            script_lines.append(f'    ((SKIPPED++))')
            script_lines.append(f'else')
            script_lines.append(f'    {cmd}')
            script_lines.append(f'    if [ $? -eq 0 ]; then')
            script_lines.append(f'        SOURCE_FILE="$TARGET_DIR/{directory}/{model["file_path"]}"')
            script_lines.append(f'        TARGET_FILE="$TARGET_DIR/{directory}/{model["name"]}"')
            script_lines.append(f'        if [ "$SOURCE_FILE" != "$TARGET_FILE" ] && [ -f "$SOURCE_FILE" ]; then')
            script_lines.append(f'            mv "$SOURCE_FILE" "$TARGET_FILE" 2>/dev/null || true')
            script_lines.append(f'            rmdir "$(dirname "$SOURCE_FILE")" 2>/dev/null || true')
            script_lines.append(f'        fi')
            script_lines.append(f'        echo "  ✓ 下载完成"')
            script_lines.append(f'        ((SUCCESS++))')
            script_lines.append(f'    else')
            script_lines.append(f'        echo "  ✗ 下载失败"')
            script_lines.append(f'        ((FAILED++))')
            script_lines.append(f'    fi')
            script_lines.append(f'fi')
            script_lines.append('')
    
    # 其他来源的提示
    if other_sources:
        script_lines.append('')
        script_lines.append('# ==================== 其他来源 ====================')
        script_lines.append('echo ""')
        script_lines.append('echo "以下模型来自其他来源，需要手动下载:"')
        for model in other_sources:
            script_lines.append(f'echo "  - {model["name"]} ({model["directory"]})"')
            script_lines.append(f'echo "    URL: {model["url"]}"')
    
    # 统计信息
    script_lines.extend([
        '',
        '# 显示统计',
        'echo ""',
        'echo "======================================"',
        'echo "下载完成!"',
        'echo "======================================"',
        'echo "成功: $SUCCESS"',
        'echo "跳过: $SKIPPED"',
        'echo "失败: $FAILED"',
        f'echo "总计: {len(models)}"',
        'echo "======================================"',
    ])
    
    # 写入文件
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(script_lines))
        f.write('\n')
    
    print(f"✓ 已生成脚本: {output_file}")
    print(f"  Hugging Face 模型: {len(models)}")
    if filter_dirs:
        print(f"  过滤目录: {', '.join(filter_dirs)}")
    print(f"  其他来源模型: {len(other_sources)}")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='生成 hf download 下载脚本')
    parser.add_argument('--csv', default='models_table.csv', help='CSV 文件路径')
    parser.add_argument('--output', '-o', default='download_with_hf.sh', help='输出脚本路径')
    parser.add_argument('--target-dir', default='/root/dehui/models', help='目标目录')
    parser.add_argument('--dirs', '-d', nargs='+', help='只下载指定目录（例如: loras controlnet）')
    
    args = parser.parse_args()
    
    if not Path(args.csv).exists():
        print(f"错误: 找不到 {args.csv}")
        return
    
    generate_bash_script(args.csv, args.output, args.target_dir, args.dirs)
    
    print(f"\n使用方法:")
    print(f"  chmod +x {args.output}")
    print(f"  ./{args.output}")

if __name__ == "__main__":
    main()

