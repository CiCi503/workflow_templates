#!/usr/bin/env python3
"""
验证本地模型文件的 SHA256 完整性

功能：
- 扫描指定目录下的所有模型文件
- 计算本地文件的 SHA256
- 从 Hugging Face 获取远程文件的 SHA256
- 比较并报告不一致的文件

依赖：
    pip install huggingface_hub colorama

使用方法：
    python3 verify_models_sha256.py /path/to/models
    python3 verify_models_sha256.py /path/to/models --dir unet
    python3 verify_models_sha256.py /path/to/models --verbose
"""

import argparse
import hashlib
import json
import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from urllib.parse import urlparse

try:
    from huggingface_hub import hf_hub_url, get_hf_file_metadata, HfFileMetadata
    from huggingface_hub.utils import HfHubHTTPError
except ImportError:
    print("错误: 请先安装 huggingface_hub")
    print("运行: pip install huggingface_hub")
    sys.exit(1)

try:
    from colorama import Fore, Style, init
    init(autoreset=True)
    HAS_COLOR = True
except ImportError:
    # 如果没有 colorama，使用空字符串
    class Fore:
        RED = GREEN = YELLOW = CYAN = BLUE = MAGENTA = ""
    class Style:
        RESET_ALL = BRIGHT = ""
    HAS_COLOR = False


def calculate_sha256(filepath: str, verbose: bool = False) -> str:
    """计算本地文件的 SHA256"""
    sha256_hash = hashlib.sha256()
    file_size = os.path.getsize(filepath)
    
    if verbose:
        print(f"      计算中... (文件大小: {file_size / (1024**3):.2f} GB)")
    
    with open(filepath, "rb") as f:
        # 使用较大的缓冲区以提高性能
        for byte_block in iter(lambda: f.read(8192 * 1024), b""):
            sha256_hash.update(byte_block)
    
    return sha256_hash.hexdigest()


def parse_hf_url(url: str) -> Optional[Dict[str, str]]:
    """
    解析 Hugging Face URL，提取 repo_id 和 file_path
    
    URL 格式: 
    - https://huggingface.co/{repo_id}/resolve/{revision}/{file_path}
    - https://huggingface.co/{repo_id}/blob/{revision}/{file_path}
    """
    if not url or not url.startswith('https://huggingface.co/'):
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


def get_hf_file_sha256(repo_id: str, filename: str, revision: str = "main") -> Optional[str]:
    """从 Hugging Face 获取文件的 SHA256"""
    try:
        url = hf_hub_url(repo_id, filename, revision=revision)
        metadata: HfFileMetadata = get_hf_file_metadata(url)
        
        # etag 通常包含 sha256，格式可能是 "sha256:xxxxx" 或直接是 hash
        if hasattr(metadata, 'etag') and metadata.etag:
            etag = metadata.etag.strip('"')
            # 有些 etag 是 sha256 格式
            if len(etag) == 64 and all(c in '0123456789abcdef' for c in etag.lower()):
                return etag.lower()
        
        # 尝试通过 LFS pointer 获取
        # 注意: huggingface_hub 可能不直接提供 sha256，需要通过 API
        return None
        
    except HfHubHTTPError as e:
        print(f"{Fore.RED}      ✗ HTTP 错误: {e}")
        return None
    except Exception as e:
        print(f"{Fore.RED}      ✗ 获取失败: {e}")
        return None


def get_hf_file_sha256_via_api(repo_id: str, filename: str, revision: str = "main") -> Optional[str]:
    """通过 HF API 获取文件的 SHA256（从 LFS 信息中）"""
    try:
        import requests
        
        # 使用 HF API 获取文件树
        api_url = f"https://huggingface.co/api/models/{repo_id}/tree/{revision}"
        params = {"recursive": "True"}
        
        response = requests.get(api_url, params=params, timeout=10)
        response.raise_for_status()
        
        files = response.json()
        
        # 查找目标文件
        for file_info in files:
            if file_info.get('path') == filename or file_info.get('path').endswith(filename):
                # LFS 文件的 sha256
                if 'lfs' in file_info and 'sha256' in file_info['lfs']:
                    return file_info['lfs']['sha256'].lower()
                # 有些文件可能在 oid 中
                if 'oid' in file_info and file_info['oid'].startswith('sha256:'):
                    return file_info['oid'].replace('sha256:', '').lower()
        
        return None
        
    except Exception as e:
        return None


def load_models_mapping() -> Dict[str, Dict]:
    """从 models_data.json 加载模型映射"""
    json_file = Path(__file__).parent / 'models_data.json'
    
    if not json_file.exists():
        print(f"{Fore.YELLOW}警告: 未找到 models_data.json，将只能验证 Hugging Face 直接链接的模型")
        return {}
    
    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"{Fore.YELLOW}警告: 读取 models_data.json 失败: {e}")
        return {}


def find_model_files(base_dir: str, target_subdir: Optional[str] = None) -> List[Tuple[str, str, str]]:
    """
    查找所有模型文件
    
    返回: [(完整路径, 相对目录, 文件名), ...]
    """
    base_path = Path(base_dir)
    if not base_path.exists():
        print(f"{Fore.RED}错误: 目录不存在: {base_dir}")
        sys.exit(1)
    
    model_extensions = {'.safetensors', '.ckpt', '.pt', '.pth', '.bin'}
    found_files = []
    
    # 如果指定了子目录
    if target_subdir:
        search_path = base_path / target_subdir
        if not search_path.exists():
            print(f"{Fore.RED}错误: 子目录不存在: {search_path}")
            sys.exit(1)
        search_paths = [search_path]
    else:
        # 搜索所有可能的子目录
        search_paths = [base_path]
    
    for search_path in search_paths:
        for root, dirs, files in os.walk(search_path):
            for filename in files:
                if any(filename.endswith(ext) for ext in model_extensions):
                    full_path = os.path.join(root, filename)
                    # 计算相对于 base_dir 的目录
                    rel_dir = os.path.relpath(root, base_path)
                    found_files.append((full_path, rel_dir, filename))
    
    return sorted(found_files)


def verify_model_file(
    file_path: str,
    rel_dir: str,
    filename: str,
    models_mapping: Dict,
    verbose: bool = False
) -> Dict:
    """
    验证单个模型文件
    
    返回验证结果字典
    """
    result = {
        'path': file_path,
        'dir': rel_dir,
        'filename': filename,
        'local_sha256': None,
        'remote_sha256': None,
        'match': None,
        'error': None
    }
    
    # 计算本地 SHA256
    try:
        if verbose:
            print(f"    计算本地 SHA256...")
        result['local_sha256'] = calculate_sha256(file_path, verbose)
    except Exception as e:
        result['error'] = f"计算 SHA256 失败: {e}"
        return result
    
    # 查找对应的远程 URL
    model_info = models_mapping.get(filename)
    
    if not model_info or not model_info.get('url'):
        result['error'] = "未找到下载 URL"
        return result
    
    url = model_info['url']
    
    # 解析 URL
    parsed = parse_hf_url(url)
    if not parsed:
        result['error'] = f"无法解析 URL (非 Hugging Face 链接): {url}"
        return result
    
    # 从 Hugging Face 获取 SHA256
    if verbose:
        print(f"    从 Hugging Face 获取 SHA256...")
        print(f"      Repo: {parsed['repo_id']}")
        print(f"      File: {parsed['file_path']}")
    
    # 先尝试通过 API 获取
    remote_sha256 = get_hf_file_sha256_via_api(
        parsed['repo_id'],
        parsed['file_path'],
        parsed['revision']
    )
    
    if not remote_sha256:
        # 尝试通过 huggingface_hub 获取
        remote_sha256 = get_hf_file_sha256(
            parsed['repo_id'],
            parsed['file_path'],
            parsed['revision']
        )
    
    if not remote_sha256:
        result['error'] = "无法从 Hugging Face 获取 SHA256"
        return result
    
    result['remote_sha256'] = remote_sha256
    result['match'] = (result['local_sha256'].lower() == remote_sha256.lower())
    
    return result


def print_result(result: Dict, verbose: bool = False):
    """打印单个文件的验证结果"""
    filename = result['filename']
    rel_dir = result['dir']
    
    print(f"\n{Fore.CYAN}{'='*80}")
    print(f"{Fore.CYAN}📁 目录: {Fore.YELLOW}{rel_dir}")
    print(f"{Fore.CYAN}📄 文件: {Fore.YELLOW}{filename}")
    print(f"{Fore.CYAN}{'='*80}")
    
    if result['error']:
        print(f"{Fore.RED}❌ 错误: {result['error']}")
        return
    
    print(f"本地 SHA256:  {result['local_sha256']}")
    print(f"远程 SHA256:  {result['remote_sha256']}")
    
    if result['match']:
        print(f"{Fore.GREEN}✅ 状态: 一致 - 文件完整")
    else:
        print(f"{Fore.RED}❌ 状态: 不一致 - 文件可能损坏")


def print_summary(results: List[Dict]):
    """打印验证总结"""
    total = len(results)
    matched = sum(1 for r in results if r['match'] is True)
    mismatched = sum(1 for r in results if r['match'] is False)
    errors = sum(1 for r in results if r['error'] is not None)
    
    print(f"\n{Fore.CYAN}{'='*80}")
    print(f"{Fore.CYAN}{Style.BRIGHT}📊 验证总结")
    print(f"{Fore.CYAN}{'='*80}")
    print(f"总文件数: {total}")
    print(f"{Fore.GREEN}✅ 一致:   {matched}")
    print(f"{Fore.RED}❌ 不一致: {mismatched}")
    print(f"{Fore.YELLOW}⚠️  错误:   {errors}")
    
    if mismatched > 0:
        print(f"\n{Fore.RED}{Style.BRIGHT}⚠️  以下文件 SHA256 不一致，建议重新下载:")
        print(f"{Fore.RED}{'='*80}")
        for result in results:
            if result['match'] is False:
                print(f"{Fore.RED}  • {result['dir']}/{result['filename']}")
    
    if errors > 0:
        print(f"\n{Fore.YELLOW}{Style.BRIGHT}⚠️  以下文件验证时出错:")
        print(f"{Fore.YELLOW}{'='*80}")
        for result in results:
            if result['error']:
                print(f"{Fore.YELLOW}  • {result['dir']}/{result['filename']}")
                print(f"    原因: {result['error']}")


def main():
    parser = argparse.ArgumentParser(
        description='验证本地模型文件的 SHA256 完整性',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s /root/dehui/models
  %(prog)s /root/dehui/models --dir unet
  %(prog)s /root/dehui/models --dir loras --verbose
  %(prog)s ~/ComfyUI/models --output report.json
        """
    )
    
    parser.add_argument(
        'base_dir',
        help='模型文件所在的基础目录'
    )
    
    parser.add_argument(
        '--dir', '-d',
        dest='subdir',
        help='只验证指定子目录（如 unet, loras, vae 等）'
    )
    
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='显示详细信息'
    )
    
    parser.add_argument(
        '--output', '-o',
        help='将结果保存为 JSON 文件'
    )
    
    args = parser.parse_args()
    
    print(f"{Fore.CYAN}{Style.BRIGHT}{'='*80}")
    print(f"{Fore.CYAN}{Style.BRIGHT}🔍 ComfyUI 模型 SHA256 验证工具")
    print(f"{Fore.CYAN}{Style.BRIGHT}{'='*80}\n")
    
    # 加载模型映射
    print(f"{Fore.CYAN}📋 加载模型映射...")
    models_mapping = load_models_mapping()
    print(f"{Fore.GREEN}   找到 {len(models_mapping)} 个模型的信息\n")
    
    # 查找模型文件
    print(f"{Fore.CYAN}🔎 扫描目录: {args.base_dir}")
    if args.subdir:
        print(f"{Fore.CYAN}   子目录: {args.subdir}")
    
    model_files = find_model_files(args.base_dir, args.subdir)
    
    if not model_files:
        print(f"{Fore.YELLOW}\n未找到任何模型文件")
        return
    
    print(f"{Fore.GREEN}   找到 {len(model_files)} 个模型文件\n")
    
    # 验证每个文件
    results = []
    
    for i, (file_path, rel_dir, filename) in enumerate(model_files, 1):
        print(f"{Fore.CYAN}[{i}/{len(model_files)}] 验证: {rel_dir}/{filename}")
        
        result = verify_model_file(
            file_path,
            rel_dir,
            filename,
            models_mapping,
            args.verbose
        )
        
        results.append(result)
        print_result(result, args.verbose)
    
    # 打印总结
    print_summary(results)
    
    # 保存结果到 JSON
    if args.output:
        try:
            with open(args.output, 'w', encoding='utf-8') as f:
                json.dump(results, f, indent=2, ensure_ascii=False)
            print(f"\n{Fore.GREEN}✅ 结果已保存到: {args.output}")
        except Exception as e:
            print(f"\n{Fore.RED}❌ 保存结果失败: {e}")


if __name__ == "__main__":
    main()

