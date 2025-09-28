#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
from image_grid_creator import ImageGridCreator

"""测试修改后的create_transition_video方法，验证特殊字符处理是否正确"""

# 确保中文显示正常
if __name__ == "__main__":
    # 设置测试图片路径
    test_images_dir = "视频制作解决方案/captured"
    output_dir = "test_output"
    os.makedirs(output_dir, exist_ok=True)
    
    # 查找测试图片（使用用户在终端中尝试过的图片路径）
    test_images = []
    for i in range(1, 6):
        img_path = os.path.join(test_images_dir, f"output_00{i}.jpg")
        if os.path.exists(img_path):
            test_images.append(img_path)
    
    if len(test_images) == 0:
        print("错误：在 {test_images_dir} 目录下没有找到测试图片！")
        sys.exit(1)
    
    print(f"找到 {len(test_images)} 张测试图片：")
    for i, img in enumerate(test_images):
        print(f"图片{i+1}: {os.path.abspath(img)}")
    
    # 创建ImageGridCreator实例
    creator = ImageGridCreator(
        max_width=1920,
        max_height=1080,
        fps=30,
        video_duration=5  # 使用与用户在终端中相同的时长
    )
    
    # 设置输出路径
    output_video = os.path.join(output_dir, "test_special_chars_fix.mp4")
    
    # 调用修改后的create_transition_video方法
    print(f"\n开始生成视频（验证特殊字符处理）: {output_video}")
    success = creator.create_transition_video(test_images, output_video)
    
    if success:
        print(f"\n测试成功！视频已生成: {output_video}")
        print(f"视频大小: {os.path.getsize(output_video) / (1024 * 1024):.2f} MB")
        print("特殊字符处理问题已解决，FFmpeg命令能够正确执行")
    else:
        print("\n测试失败！视频生成过程中出现错误")
        sys.exit(1)