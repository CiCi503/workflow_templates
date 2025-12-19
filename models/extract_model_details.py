#!/usr/bin/env python3
"""
提取所有模板中的模型详细信息，包括下载地址和存储路径
"""

import json
import os
import re
from collections import defaultdict
from typing import Dict, List, Set, Tuple

def extract_url_with_balanced_parens(text: str, start_pos: int) -> Tuple[str, int]:
    """提取URL，处理平衡的括号"""
    depth = 1
    pos = start_pos
    while pos < len(text) and depth > 0:
        char = text[pos]
        if char == '(':
            depth += 1
        elif char == ')':
            depth -= 1
            if depth == 0:
                break
        elif char in ' \t\n\r':
            break
        pos += 1
    return text[start_pos:pos], pos

def find_markdown_links(obj, links_list):
    """递归查找所有markdown链接"""
    if isinstance(obj, dict):
        for v in obj.values():
            find_markdown_links(v, links_list)
    elif isinstance(obj, list):
        for v in obj:
            find_markdown_links(v, links_list)
    elif isinstance(obj, str):
        # Markdown链接格式: [filename.safetensors](url)
        pattern = r'\[([^\]]+?\.(?:safetensors|ckpt|pt|pth))\]\('
        for match in re.finditer(pattern, obj):
            text_name = match.group(1)
            start_pos = match.end()
            url, _ = extract_url_with_balanced_parens(obj, start_pos)
            links_list.append({
                'name': text_name,
                'url': url
            })

def get_model_directory(node_type: str, file_name: str = '') -> str:
    """根据节点类型和文件名确定模型存储目录"""
    node_type_lower = node_type.lower()
    file_name_lower = file_name.lower()
    
    # 基于节点类型的映射
    if 'unet' in node_type_lower:
        return 'unet'
    elif 'vae' in node_type_lower:
        return 'vae'
    elif 'clip' in node_type_lower:
        if 'vision' in node_type_lower:
            return 'clip_vision'
        return 'clip'
    elif 'lora' in node_type_lower:
        return 'loras'
    elif 'checkpoint' in node_type_lower:
        return 'checkpoints'
    elif 'controlnet' in node_type_lower:
        return 'controlnet'
    elif 'upscale' in node_type_lower or 'upscaler' in node_type_lower:
        return 'upscale_models'
    elif 'audio' in node_type_lower:
        return 'audio'
    elif 'sam' in node_type_lower or 'sam2' in node_type_lower:
        return 'sams'
    elif 'style' in node_type_lower:
        return 'style_models'
    
    # 基于文件名的推断
    if 'lora' in file_name_lower:
        return 'loras'
    elif 'vae' in file_name_lower:
        return 'vae'
    elif 'controlnet' in file_name_lower or 'control' in file_name_lower:
        return 'controlnet'
    elif 'upscale' in file_name_lower:
        return 'upscale_models'
    
    return 'unknown'

def analyze_template_file(file_path: str) -> Dict:
    """分析单个模板文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        return {'error': str(e)}
    
    result = {
        'file': os.path.basename(file_path),
        'models': []
    }
    
    # 提取所有markdown链接
    markdown_links = []
    find_markdown_links(data, markdown_links)
    
    # 创建URL查找字典
    url_map = {link['name']: link['url'] for link in markdown_links}
    
    # 分析节点
    nodes = data.get('nodes', [])
    for node in nodes:
        node_type = node.get('type', '')
        node_id = node.get('id', '')
        widgets_values = node.get('widgets_values', [])
        properties = node.get('properties', {})
        
        # 跳过 MarkdownNote 节点（它们只是文档说明）
        if node_type.lower() in ['markdownnote', 'note']:
            continue
        
        # 查找所有包含模型文件的widgets_values
        for widget_value in widgets_values:
            if isinstance(widget_value, str) and any(ext in widget_value for ext in ['.safetensors', '.ckpt', '.pt', '.pth']):
                model_dir = get_model_directory(node_type, widget_value)
                url = url_map.get(widget_value, '')
                
                result['models'].append({
                    'name': widget_value,
                    'url': url,
                    'directory': model_dir,
                    'node_type': node_type,
                    'node_id': node_id
                })
        
        # 也检查properties.models
        if 'models' in properties:
            for model in properties['models']:
                model_name = model.get('name', '')
                if model_name:
                    model_dir = get_model_directory(node_type, model_name)
                    url = url_map.get(model_name, model.get('url', ''))
                    
                    # 检查是否已经添加过
                    if not any(m['name'] == model_name and m['node_id'] == node_id for m in result['models']):
                        result['models'].append({
                            'name': model_name,
                            'url': url,
                            'directory': model_dir,
                            'node_type': node_type,
                            'node_id': node_id
                        })
    
    return result

def analyze_all_templates(templates_dir: str) -> Tuple[Dict, Dict]:
    """分析所有模板文件"""
    all_models = defaultdict(lambda: {
        'url': '',
        'directories': set(),
        'node_types': set(),
        'used_in_templates': []
    })
    
    for filename in sorted(os.listdir(templates_dir)):
        if filename.endswith('.json') and not filename.startswith('index.'):
            file_path = os.path.join(templates_dir, filename)
            result = analyze_template_file(file_path)
            
            if 'error' in result:
                print(f"Error processing {filename}: {result['error']}")
                continue
            
            for model in result['models']:
                model_name = model['name']
                all_models[model_name]['url'] = model['url'] or all_models[model_name]['url']
                all_models[model_name]['directories'].add(model['directory'])
                all_models[model_name]['node_types'].add(model['node_type'])
                all_models[model_name]['used_in_templates'].append(filename)
    
    # 转换set为list以便JSON序列化
    for model_name in all_models:
        all_models[model_name]['directories'] = sorted(list(all_models[model_name]['directories']))
        all_models[model_name]['node_types'] = sorted(list(all_models[model_name]['node_types']))
    
    return dict(all_models)

def generate_markdown_report(models_data: Dict) -> str:
    """生成Markdown格式的报告"""
    report = []
    report.append("# ComfyUI 工作流模板所需模型列表\n")
    report.append(f"本文档列出了 `templates` 目录中所有工作流模板所需的模型文件。\n")
    report.append(f"**统计信息：**")
    report.append(f"- 总模型数量: {len(models_data)}")
    
    # 按目录分组
    models_by_dir = defaultdict(list)
    for model_name, info in sorted(models_data.items()):
        # 使用第一个目录（如果有多个）
        primary_dir = info['directories'][0] if info['directories'] else 'unknown'
        models_by_dir[primary_dir].append((model_name, info))
    
    report.append(f"- 涉及目录数: {len(models_by_dir)}\n")
    
    # 按目录生成报告
    for directory in sorted(models_by_dir.keys()):
        models = models_by_dir[directory]
        report.append(f"## 📁 {directory}")
        report.append(f"\n存储路径: `ComfyUI/models/{directory}/`")
        report.append(f"\n模型数量: {len(models)}\n")
        
        for model_name, info in sorted(models):
            report.append(f"### {model_name}\n")
            
            if info['url']:
                report.append(f"**下载地址:**")
                report.append(f"```")
                report.append(f"{info['url']}")
                report.append(f"```\n")
            else:
                report.append(f"**下载地址:** ⚠️ 未提供 (请查看对应工作流的说明文档)\n")
            
            report.append(f"**节点类型:** {', '.join(info['node_types'])}\n")
            
            if len(info['used_in_templates']) <= 5:
                report.append(f"**使用模板:** {', '.join(info['used_in_templates'])}\n")
            else:
                report.append(f"**使用模板:** {len(info['used_in_templates'])} 个模板使用此模型\n")
            
            if len(info['directories']) > 1:
                report.append(f"**备注:** 此模型在不同工作流中可能存储于不同目录: {', '.join(info['directories'])}\n")
            
            report.append("---\n")
    
    # 添加使用说明
    report.append("\n## 📋 使用说明\n")
    report.append("1. 根据上述列表，下载所需的模型文件")
    report.append("2. 将模型文件放置到对应的 `ComfyUI/models/` 子目录中")
    report.append("3. 如果某个模型没有提供下载地址，请查看对应工作流模板的说明文档或MarkdownNote节点")
    report.append("4. 部分模型可能需要从 Hugging Face、Civitai 等平台下载")
    report.append("5. 确保模型文件名与工作流中指定的名称完全一致\n")
    
    report.append("## 🔍 目录说明\n")
    report.append("| 目录 | 说明 |")
    report.append("|------|------|")
    report.append("| `unet` | UNET 模型文件 |")
    report.append("| `vae` | VAE (变分自编码器) 模型 |")
    report.append("| `clip` | CLIP 文本编码器模型 |")
    report.append("| `clip_vision` | CLIP 视觉编码器模型 |")
    report.append("| `loras` | LoRA 微调模型 |")
    report.append("| `checkpoints` | 完整检查点模型 |")
    report.append("| `controlnet` | ControlNet 控制模型 |")
    report.append("| `upscale_models` | 图像放大模型 |")
    report.append("| `audio` | 音频处理模型 |")
    report.append("| `sams` | Segment Anything Model |")
    report.append("| `style_models` | 风格迁移模型 |")
    
    return '\n'.join(report)

def main():
    templates_dir = './templates'
    output_file = 'MODELS_REQUIRED.md'
    
    print("正在分析模板文件...")
    models_data = analyze_all_templates(templates_dir)
    
    print(f"找到 {len(models_data)} 个独特的模型文件")
    print("正在生成报告...")
    
    report = generate_markdown_report(models_data)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(report)
    
    print(f"报告已生成: {output_file}")
    
    # 同时输出JSON格式
    json_output = 'models_data.json'
    with open(json_output, 'w', encoding='utf-8') as f:
        json.dump(models_data, f, indent=2, ensure_ascii=False)
    
    print(f"JSON数据已生成: {json_output}")

if __name__ == "__main__":
    main()

