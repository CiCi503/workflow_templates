#!/usr/bin/env python3
"""
批量下载 ComfyUI 模型脚本（无第三方依赖版本）

从 models_table.csv 读取模型信息，下载到当前目录的对应子目录中
只使用 Python 标准库，无需安装额外依赖
"""

import os
import csv
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path
from urllib.parse import urlparse

# Hugging Face Token - 从环境变量获取
# 设置方式: export HF_TOKEN=your_token_here
HF_TOKEN = os.environ.get('HF_TOKEN', '')

class ModelDownloader:
    def __init__(self, base_dir="."):
        self.base_dir = Path(base_dir)
        
    def format_size(self, bytes_size):
        """格式化文件大小"""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if bytes_size < 1024.0:
                return f"{bytes_size:.1f} {unit}"
            bytes_size /= 1024.0
        return f"{bytes_size:.1f} TB"
    
    def download_file(self, url, target_path, max_retries=3):
        """
        下载文件，支持断点续传
        
        Args:
            url: 下载地址
            target_path: 保存路径
            max_retries: 最大重试次数
        """
        target_path = Path(target_path)
        target_path.parent.mkdir(parents=True, exist_ok=True)
        
        # 临时文件
        temp_path = target_path.with_suffix(target_path.suffix + '.downloading')
        
        # 检查是否已经下载
        if target_path.exists():
            print(f"  ✓ 已存在，跳过")
            return True
        
        # 获取已下载的大小
        downloaded_size = 0
        if temp_path.exists():
            downloaded_size = temp_path.stat().st_size
            print(f"  继续下载，已完成 {self.format_size(downloaded_size)}")
        
        for attempt in range(max_retries):
            try:
                # 创建请求
                headers = {
                    'Authorization': f'Bearer {HF_TOKEN}',
                    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'
                }
                
                # 设置 Range header 用于断点续传
                if downloaded_size > 0:
                    headers['Range'] = f'bytes={downloaded_size}-'
                
                req = urllib.request.Request(url, headers=headers)
                
                # 发起请求
                with urllib.request.urlopen(req, timeout=30) as response:
                    # 获取文件总大小
                    if 'Content-Length' in response.headers:
                        content_length = int(response.headers['Content-Length'])
                        if response.status == 206:  # Partial Content
                            total_size = downloaded_size + content_length
                        else:
                            total_size = content_length
                    else:
                        total_size = None
                    
                    print(f"  文件大小: {self.format_size(total_size) if total_size else '未知'}")
                    print(f"  下载中...")
                    
                    # 下载文件
                    mode = 'ab' if downloaded_size > 0 else 'wb'
                    chunk_size = 8192
                    downloaded_chunks = downloaded_size
                    last_print_time = time.time()
                    last_size = downloaded_size
                    
                    with open(temp_path, mode) as f:
                        while True:
                            chunk = response.read(chunk_size)
                            if not chunk:
                                break
                            
                            f.write(chunk)
                            downloaded_chunks += len(chunk)
                            
                            # 每秒更新一次进度
                            current_time = time.time()
                            if current_time - last_print_time >= 1.0:
                                speed = (downloaded_chunks - last_size) / (current_time - last_print_time)
                                if total_size:
                                    percent = (downloaded_chunks / total_size) * 100
                                    print(f"  进度: {percent:.1f}% ({self.format_size(downloaded_chunks)}/{self.format_size(total_size)}) "
                                          f"速度: {self.format_size(speed)}/s", end='\r')
                                else:
                                    print(f"  已下载: {self.format_size(downloaded_chunks)} "
                                          f"速度: {self.format_size(speed)}/s", end='\r')
                                last_print_time = current_time
                                last_size = downloaded_chunks
                
                print()  # 换行
                
                # 下载完成，重命名
                temp_path.rename(target_path)
                print(f"  ✓ 下载完成")
                return True
                
            except urllib.error.HTTPError as e:
                print(f"\n  ✗ HTTP 错误 {e.code}: {e.reason}")
                if attempt < max_retries - 1:
                    print(f"  重试 {attempt + 1}/{max_retries}...")
                    time.sleep(2)
                else:
                    print(f"  ✗ 达到最大重试次数，跳过")
                    return False
                    
            except urllib.error.URLError as e:
                print(f"\n  ✗ 网络错误: {e.reason}")
                if attempt < max_retries - 1:
                    print(f"  重试 {attempt + 1}/{max_retries}...")
                    time.sleep(2)
                else:
                    print(f"  ✗ 达到最大重试次数，跳过")
                    return False
                    
            except KeyboardInterrupt:
                print(f"\n  中断下载")
                raise
                
            except Exception as e:
                print(f"\n  ✗ 未知错误: {e}")
                if attempt < max_retries - 1:
                    print(f"  重试 {attempt + 1}/{max_retries}...")
                    time.sleep(2)
                else:
                    return False
        
        return False
    
    def process_csv(self, csv_file, directories=None, dry_run=False, skip_existing=True):
        """
        处理 CSV 文件，批量下载模型
        
        Args:
            csv_file: CSV 文件路径
            directories: 指定要下载的目录列表（None 表示全部）
            dry_run: 是否只显示将要下载的文件，不实际下载
            skip_existing: 是否跳过已存在的文件
        """
        if not Path(csv_file).exists():
            print(f"错误: 找不到文件 {csv_file}")
            return
        
        # 读取 CSV
        models_to_download = []
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                directory = row['目录']
                model_name = row['模型名称']
                url = row['下载地址']
                
                # 过滤掉无效的 URL
                if not url or url == '⚠️ 未提供' or not url.startswith('http'):
                    continue
                
                # 如果指定了目录过滤
                if directories and directory not in directories:
                    continue
                
                models_to_download.append({
                    'directory': directory,
                    'name': model_name,
                    'url': url
                })
        
        if not models_to_download:
            print("没有找到可下载的模型")
            return
        
        print(f"\n找到 {len(models_to_download)} 个可下载的模型")
        
        if dry_run:
            print("\n[预览模式] 将要下载的文件：")
            print("="*80)
            for i, model in enumerate(models_to_download, 1):
                print(f"\n{i}. {model['name']}")
                print(f"   目录: {model['directory']}")
                print(f"   URL: {model['url'][:100]}{'...' if len(model['url']) > 100 else ''}")
            print("\n" + "="*80)
            print(f"\n提示: 去掉 --dry-run 参数开始实际下载")
            return
        
        # 统计信息
        success_count = 0
        skip_count = 0
        fail_count = 0
        
        # 开始下载
        print("\n" + "="*80)
        print("开始下载模型...")
        print("="*80 + "\n")
        
        for i, model in enumerate(models_to_download, 1):
            directory = model['directory']
            model_name = model['name']
            url = model['url']
            
            print(f"\n[{i}/{len(models_to_download)}] {model_name}")
            print(f"  目录: {directory}")
            
            # 目标路径
            target_dir = self.base_dir / directory
            target_path = target_dir / model_name
            
            # 检查是否已存在
            if skip_existing and target_path.exists():
                print(f"  ✓ 文件已存在，跳过")
                skip_count += 1
                continue
            
            # 下载
            if self.download_file(url, target_path):
                success_count += 1
            else:
                fail_count += 1
        
        # 显示统计
        print("\n" + "="*80)
        print("下载完成!")
        print("="*80)
        print(f"✓ 成功: {success_count}")
        print(f"⊙ 跳过: {skip_count}")
        print(f"✗ 失败: {fail_count}")
        print(f"═ 总计: {len(models_to_download)}")
        print("="*80)

def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description='批量下载 ComfyUI 模型（无第三方依赖版本）',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例用法:

  # 预览将要下载的文件
  python3 download_models_simple.py --dry-run

  # 下载所有模型
  python3 download_models_simple.py

  # 只下载 unet 目录的模型
  python3 download_models_simple.py --dirs unet

  # 下载多个目录的模型
  python3 download_models_simple.py --dirs unet clip vae

  # 指定输出目录
  python3 download_models_simple.py --output ./comfyui_models

  # 强制重新下载
  python3 download_models_simple.py --no-skip-existing
        """
    )
    
    parser.add_argument(
        '--csv',
        default='models_table.csv',
        help='CSV 文件路径（默认: models_table.csv）'
    )
    
    parser.add_argument(
        '--output', '-o',
        default='.',
        help='下载到的根目录（默认: 当前目录）'
    )
    
    parser.add_argument(
        '--dirs', '-d',
        nargs='+',
        help='指定要下载的目录（例如: unet clip vae）'
    )
    
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='预览模式，只显示将要下载的文件，不实际下载'
    )
    
    parser.add_argument(
        '--no-skip-existing',
        action='store_true',
        help='不跳过已存在的文件，强制重新下载'
    )
    
    args = parser.parse_args()
    
    # 检查 HF_TOKEN
    if not HF_TOKEN and not args.dry_run:
        print("⚠️  错误: 未设置 Hugging Face Token")
        print("\n请设置环境变量 HF_TOKEN:")
        print("  export HF_TOKEN=your_token_here")
        print("\n或者在运行时设置:")
        print("  HF_TOKEN=your_token python3 download_models_simple.py")
        print("\n提示: 使用 --dry-run 可以在不设置 Token 的情况下预览")
        sys.exit(1)
    
    try:
        downloader = ModelDownloader(base_dir=args.output)
        downloader.process_csv(
            csv_file=args.csv,
            directories=args.dirs,
            dry_run=args.dry_run,
            skip_existing=not args.no_skip_existing
        )
    except KeyboardInterrupt:
        print("\n\n用户中断下载")
        sys.exit(1)
    except Exception as e:
        print(f"\n错误: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()

