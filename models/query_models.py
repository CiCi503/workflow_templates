#!/usr/bin/env python3
"""
查询特定工作流模板所需的模型
"""

import json
import sys
from pathlib import Path

def load_models_data():
    """加载模型数据"""
    json_file = Path(__file__).parent / 'models_data.json'
    if not json_file.exists():
        print("错误: 未找到 models_data.json 文件")
        print("请先运行: python3 extract_model_details.py")
        sys.exit(1)
    
    with open(json_file, 'r', encoding='utf-8') as f:
        return json.load(f)

def query_by_template(template_name, models_data):
    """查询特定模板所需的模型"""
    if not template_name.endswith('.json'):
        template_name += '.json'
    
    results = []
    for model_name, info in models_data.items():
        if template_name in info['used_in_templates']:
            results.append((model_name, info))
    
    return results

def query_by_directory(directory, models_data):
    """查询特定目录下的所有模型"""
    results = []
    for model_name, info in models_data.items():
        if directory in info['directories']:
            results.append((model_name, info))
    
    return results

def query_by_model_name(model_name, models_data):
    """查询特定模型的信息"""
    for key, info in models_data.items():
        if model_name.lower() in key.lower():
            return [(key, info)]
    return []

def print_model_info(model_name, info, show_templates=True):
    """打印模型信息"""
    print(f"\n{'='*80}")
    print(f"📦 {model_name}")
    print(f"{'='*80}")
    
    if info['url']:
        print(f"\n🔗 下载地址:")
        print(f"   {info['url']}")
    else:
        print(f"\n⚠️  下载地址: 未提供")
    
    print(f"\n📁 存储路径:")
    for directory in info['directories']:
        print(f"   ComfyUI/models/{directory}/")
    
    print(f"\n🔧 节点类型:")
    for node_type in info['node_types'][:3]:  # 最多显示3个
        print(f"   - {node_type}")
    if len(info['node_types']) > 3:
        print(f"   ... 还有 {len(info['node_types']) - 3} 个节点类型")
    
    if show_templates:
        print(f"\n📄 使用的模板: ({len(info['used_in_templates'])} 个)")
        for template in info['used_in_templates'][:5]:  # 最多显示5个
            print(f"   - {template}")
        if len(info['used_in_templates']) > 5:
            print(f"   ... 还有 {len(info['used_in_templates']) - 5} 个模板")

def main():
    if len(sys.argv) < 2:
        print("用法:")
        print("  查询模板所需模型:     python3 query_models.py template <模板名称>")
        print("  查询目录下的模型:     python3 query_models.py dir <目录名>")
        print("  查询特定模型信息:     python3 query_models.py model <模型名>")
        print("\n示例:")
        print("  python3 query_models.py template flux_schnell")
        print("  python3 query_models.py dir unet")
        print("  python3 query_models.py model flux1-dev")
        sys.exit(1)
    
    models_data = load_models_data()
    
    query_type = sys.argv[1].lower()
    query_value = ' '.join(sys.argv[2:])
    
    if query_type in ['template', 't']:
        results = query_by_template(query_value, models_data)
        if results:
            print(f"\n🔍 模板 '{query_value}' 需要以下 {len(results)} 个模型:")
            for model_name, info in sorted(results):
                print_model_info(model_name, info, show_templates=False)
        else:
            print(f"\n❌ 未找到模板 '{query_value}'")
            print(f"提示: 请确保模板名称正确，或添加 .json 后缀")
    
    elif query_type in ['dir', 'd', 'directory']:
        results = query_by_directory(query_value, models_data)
        if results:
            print(f"\n🔍 目录 'ComfyUI/models/{query_value}/' 包含 {len(results)} 个模型:")
            for model_name, info in sorted(results):
                has_url = "✓" if info['url'] else "✗"
                print(f"  [{has_url}] {model_name}")
            
            print(f"\n提示: 使用以下命令查看详细信息:")
            print(f"  python3 query_models.py model <模型名>")
        else:
            print(f"\n❌ 未找到目录 '{query_value}'")
    
    elif query_type in ['model', 'm']:
        results = query_by_model_name(query_value, models_data)
        if results:
            print(f"\n🔍 找到 {len(results)} 个匹配的模型:")
            for model_name, info in sorted(results):
                print_model_info(model_name, info, show_templates=True)
        else:
            print(f"\n❌ 未找到包含 '{query_value}' 的模型")
    
    else:
        print(f"❌ 未知的查询类型: {query_type}")
        print("支持的类型: template, dir, model")

if __name__ == "__main__":
    main()

