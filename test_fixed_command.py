#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""测试修复后的FFmpeg命令执行

这个脚本用于测试修复后的ImageGridCreator类中的create_transition_video方法，
验证移除filter_complex、[out]和output_path参数中的双引号后是否能成功执行FFmpeg命令。
"""

import os
import sys
from image_grid_creator import ImageGridCreator


def main():
    # 获取当前目录
    current_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 设置输入图片目录和输出文件路径
    input_dir = os.path.join(current_dir, '视频制作解决方案', 'captured')
    output_file = os.path.join(current_dir, 'test_output', 'fixed_command_test.mp4')
    
    # 创建输出目录（如果不存在）
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    try:
        # 初始化ImageGridCreator
        creator = ImageGridCreator(
            output_file,
            max_width=1920,
            max_height=1080,
            create_video=True,
            video_duration=5.0,
            fps=30.0
        )
        
        # 检查FFmpeg是否安装
        if not creator.check_ffmpeg():
            print("错误：未找到FFmpeg，请先安装FFmpeg！")
            return 1
        
        # 获取图片文件
        image_files = creator.get_image_files_from_dir(input_dir)
        if not image_files:
            print(f"错误：在目录 {input_dir} 中未找到图片文件！")
            return 1
        
        # 如果图片太多，只使用前5张进行测试
        if len(image_files) > 5:
            image_files = image_files[:5]
            print(f"为了测试，只使用前5张图片：{image_files}")
        
        # 创建带转场特效的视频
        success = creator.create_transition_video(image_files, output_file)
        
        if success and os.path.exists(output_file):
            print(f"\n测试成功！视频已创建：{output_file}")
            print(f"文件大小：{os.path.getsize(output_file) / (1024 * 1024):.2f} MB")
            return 0
        else:
            print("测试失败！视频创建过程中出现错误。")
            return 1
            
    except Exception as e:
        print(f"测试过程中出现异常：{str(e)}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())