#!/usr/bin/env python3
"""测试视频生成功能的脚本"""

import os
import sys
from image_grid_creator_simple import ImageGridCreator


def main():
    # 确保有足够的图片文件用于测试
    image_files = []
    for i in range(1, 5):  # 寻找4张测试图片
        img_path = f"output_00{i}.jpg"
        if os.path.exists(img_path):
            image_files.append(img_path)
            print(f"找到测试图片: {img_path}")
        else:
            print(f"警告: 找不到测试图片 {img_path}")
    
    if len(image_files) < 4:
        print(f"错误: 需要至少4张测试图片，只找到了{len(image_files)}张")
        print("请确保当前目录下有output_001.jpg到output_004.jpg这四张图片")
        return 1
    
    # 创建视频生成器实例
    output_dir = os.path.dirname(os.path.abspath(__file__))
    creator = ImageGridCreator(
        image_folder=output_dir,
        output_folder=output_dir,
        video_duration=3,
        frame_rate=30
    )
    
    # 测试修复后的create_transition_video方法
    output_video = os.path.join(output_dir, "test_fixed_transition_video.mp4")
    print(f"\n测试修复后的create_transition_video方法...")
    print(f"输出视频路径: {output_video}")
    
    success = creator.create_transition_video(image_files, output_video)
    
    if success and os.path.exists(output_video):
        print(f"\n成功: 视频已生成！文件大小: {os.path.getsize(output_video)} 字节")
        print(f"请检查文件: {output_video}")
    else:
        print("\n失败: 视频生成失败或输出文件不存在")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())