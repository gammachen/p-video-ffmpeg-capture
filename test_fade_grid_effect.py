#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
from image_grid_creator import ImageGridCreator

"""测试修改后的create_transition_video方法，验证图片依次淡入效果"""

# 确保中文显示正常
if __name__ == "__main__":
    # 设置测试图片路径
    test_images_dir = "images"
    output_dir = "test_output"
    os.makedirs(output_dir, exist_ok=True)
    
    # 查找测试图片（寻找5张测试图片）
    test_images = []
    for i in range(1, 6):
        img_path = os.path.join(test_images_dir, f"output_00{i}.jpg")
        if os.path.exists(img_path):
            test_images.append(img_path)
    
    if len(test_images) < 5:
        print(f"警告：只找到 {len(test_images)} 张测试图片，需要至少5张图片来测试3x2网格布局")
        
        # 尝试从其他目录寻找图片
        other_dirs = ["docs", "视频制作解决方案/captured"]
        for dir_path in other_dirs:
            for root, _, files in os.walk(dir_path):
                for file in files:
                    if file.lower().endswith((".jpg", ".jpeg", ".png")) and len(test_images) < 5:
                        img_path = os.path.join(root, file)
                        test_images.append(img_path)
            if len(test_images) >= 5:
                break
    
    if len(test_images) == 0:
        print("错误：没有找到任何测试图片！")
        sys.exit(1)
    
    # 限制为前5张图片以测试3x2网格布局
    test_images = test_images[:5]
    print(f"使用 {len(test_images)} 张图片进行测试")
    for i, img in enumerate(test_images):
        print(f"图片{i+1}: {img}")
    
    # 创建ImageGridCreator实例
    creator = ImageGridCreator(
        max_width=1920,
        max_height=1080,
        fps=30,
        video_duration=3
    )
    
    # 设置输出路径
    output_video = os.path.join(output_dir, "test_fade_grid_effect.mp4")
    
    # 调用修改后的create_transition_video方法
    print(f"\n开始生成带有淡入效果的网格视频: {output_video}")
    success = creator.create_transition_video(test_images, output_video)
    
    if success:
        print(f"\n测试成功！视频已生成: {output_video}")
        print(f"视频大小: {os.path.getsize(output_video) / (1024 * 1024):.2f} MB")
        print("请查看视频效果，确认图片是否按照预期依次淡入")
    else:
        print("\n测试失败！视频生成过程中出现错误")
        sys.exit(1)