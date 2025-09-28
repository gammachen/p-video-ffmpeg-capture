#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""测试image_grid_creator.py中的create_transition_video方法（使用xstack实现网格布局）"""

import os
import sys
from image_grid_creator import ImageGridCreator


def main():
    # 查找测试图片（output_001.jpg到output_005.jpg）
    image_files = []
    for i in range(1, 6):
        img_path = os.path.join('images', f'output_{i:03d}.jpg')
        if os.path.exists(img_path):
            image_files.append(img_path)
        else:
            print(f"警告：未找到测试图片 {img_path}")
    
    # 如果没有找到足够的测试图片，尝试使用其他路径
    if len(image_files) < 1:
        # 尝试在当前目录查找
        for i in range(1, 6):
            img_path = f'output_{i:03d}.jpg'
            if os.path.exists(img_path):
                image_files.append(img_path)
        
        if len(image_files) < 1:
            print("错误：没有找到测试图片！请确保有output_001.jpg等测试图片在images目录或当前目录")
            return 1
    
    print(f"找到 {len(image_files)} 张测试图片")
    for img in image_files:
        print(f"- {img}")
    
    # 创建输出目录（如果不存在）
    output_dir = 'test_output'
    os.makedirs(output_dir, exist_ok=True)
    
    # 创建输出文件路径
    output_video = os.path.join(output_dir, 'test_xstack_grid.mp4')
    
    # 创建ImageGridCreator实例
    creator = ImageGridCreator(
        output_file=output_video,
        max_width=1920,
        max_height=1080,
        create_video=True,
        video_duration=3.0,  # 简短的视频用于测试
        fps=30.0
    )
    
    # 检查FFmpeg是否安装
    if not creator.check_ffmpeg():
        print("错误：未安装FFmpeg！")
        return 1
    
    # 调用create_transition_video方法
    print(f"\n开始测试create_transition_video方法...")
    success = creator.create_transition_video(image_files, output_video)
    
    if success:
        print(f"\n测试成功！视频已生成：{output_video}")
        print(f"文件大小：{os.path.getsize(output_video) / 1024:.2f} KB")
        return 0
    else:
        print("\n测试失败！未能生成视频")
        return 1


if __name__ == "__main__":
    sys.exit(main())