#!/usr/bin/env python3
"""测试修复后的过渡视频生成功能"""

import os
import sys
from image_grid_creator_simple import ImageGridCreator


def main():
    # 获取当前工作目录
    current_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 寻找测试图片
    test_images = []
    for i in range(1, 5):
        img_path = os.path.join(current_dir, f"output_00{i}.jpg")
        if os.path.exists(img_path):
            test_images.append(img_path)
            print(f"找到测试图片: {os.path.basename(img_path)}")
    
    if len(test_images) < 4:
        print(f"错误: 需要至少4张测试图片，只找到了{len(test_images)}张")
        print("请确保当前目录下有output_001.jpg到output_004.jpg这四张图片")
        return 1
    
    # 创建视频生成器实例
    creator = ImageGridCreator(
        image_folder=current_dir,
        output_folder=current_dir,
        video_duration=3,  # 与参考命令保持一致的时长
        frame_rate=30
    )
    
    # 设置输出视频路径
    output_video = os.path.join(current_dir, "test_fixed_2x2_animation.mp4")
    
    print(f"\n开始测试修复后的create_transition_video方法...")
    print(f"输出视频将保存在: {output_video}")
    print(f"视频参数: 1920x1080, 30fps, 3秒时长")
    print(f"效果: 4张图片按顺序淡入，2x2网格布局")
    
    # 调用修复后的方法
    success = creator.create_transition_video(test_images, output_video)
    
    if success:
        print(f"\n✅ 测试成功！视频已生成")
        print(f"文件位置: {output_video}")
        print(f"文件大小: {os.path.getsize(output_video)} 字节")
        print("\n您可以使用以下命令播放视频:")
        print(f"   open {output_video}")
    else:
        print("\n❌ 测试失败！视频生成过程中出现错误")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())