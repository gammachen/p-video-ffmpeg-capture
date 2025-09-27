#!/usr/bin/env python3
import subprocess
import os

"""
一个简单的测试脚本，用于验证FFmpeg实现从右往左滑入效果
"""

# 配置参数
output_file = 'test-slide-effect.mp4'
image_dir = '视频制作解决方案/captured'
video_duration = 5  # 秒
fps = 30
width, height = 1920, 1080

# 获取图片文件列表
image_files = [f for f in os.listdir(image_dir) if f.endswith(('.jpg', '.jpeg', '.png'))]
if not image_files:
    print("错误：没有找到图片文件！")
    exit(1)

# 限制使用4张图片进行测试
max_images = 4
image_files = image_files[:max_images]
image_files = [os.path.join(image_dir, f) for f in image_files]

print(f"找到 {len(image_files)} 张图片，准备创建测试视频")

# 使用2x2网格布局
grid_rows, grid_cols = 2, 2
cell_width = width // grid_cols
cell_height = height // grid_rows

# 准备FFmpeg命令和滤镜链
ffmpeg_inputs = []
filter_complex_parts = []

# 创建黑色背景
filter_complex_parts.append(f"color=c=black:s={width}x{height}:r={fps}:d={video_duration}[bg];")

# 为每张图片添加滤镜链 - 使用更简单的方法
slide_duration = 0.5  # 滑入动画持续时间

for i, img_path in enumerate(image_files):
    # 添加图片作为输入
    ffmpeg_inputs.extend(['-loop', '1', '-i', img_path])
    img_index = i + 1  # +1 因为背景是第一个输入
    
    # 计算图片在网格中的位置
    row = i // grid_cols
    col = i % grid_cols
    x_pos = col * cell_width
    y_pos = row * cell_height
    
    print(f"图片 {i+1}: 位置 ({row+1}:{col+1}), 坐标 ({x_pos}, {y_pos})")
    
    # 为每张图片创建带滑入效果的流
    # 1. 缩放图片
    filter_complex_parts.append(f"[{img_index}:v]scale={cell_width}:{cell_height}:force_original_aspect_ratio=decrease:flags=lanczos,pad={cell_width}:{cell_height}:(ow-iw)/2:(oh-ih)/2:black[img{i}];")

# 现在，将所有图片叠加到背景上，每个图片都有自己的滑入效果
# 首先是背景
current_output = "bg"

for i in range(len(image_files)):
    # 计算位置
    row = i // grid_cols
    col = i % grid_cols
    x_pos = col * cell_width
    y_pos = row * cell_height
    
    # 创建新的临时输出名称
    next_output = f"tmp{i}"
    
    # 构建overlay滤镜，实现从右往左滑入
    filter_complex_parts.append(f"[{current_output}][img{i}]overlay=x='if(lt(t,{slide_duration}),W-{x_pos}-(t*W/{slide_duration}),{x_pos})':y={y_pos}[{next_output}];")
    
    # 更新当前输出
    current_output = next_output

# 添加最终的淡出效果
filter_complex_parts.append(f"[{current_output}]fade=out:st={video_duration-1}:d=1[out];")

# 构建完整的filter_complex字符串
filter_complex = "".join(filter_complex_parts)

# 构建完整的FFmpeg命令
cmd = [
    'ffmpeg',
    *ffmpeg_inputs,
    '-filter_complex', filter_complex,
    '-map', '[out]',
    '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '28',
    '-pix_fmt', 'yuv420p', '-y', output_file
]

print(f"FFmpeg命令参数数量: {len(cmd)}")
print(f"Filter_complex前1000字符: {filter_complex[:1000]}...")

# 执行命令
try:
    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True
    )
    
    stdout, stderr = process.communicate()
    
    print(f"返回代码: {process.returncode}")
    print(f"标准输出前500字符: {stdout[:500]}")
    print(f"标准错误前500字符: {stderr[:500]}")
    
    if process.returncode == 0 and os.path.exists(output_file):
        print(f"成功创建测试视频: {output_file}")
        print(f"视频文件大小: {os.path.getsize(output_file)} 字节")
    else:
        print(f"创建视频失败")
except Exception as e:
    print(f"执行命令时出错: {str(e)}")