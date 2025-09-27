#!/usr/bin/env python3
import subprocess
import os

"""
最简单的测试脚本，只处理1张图片的从右往左滑入效果
"""

# 配置参数
output_file = 'test-single-slide.mp4'
image_dir = '视频制作解决方案/captured'
video_duration = 3  # 更短的时长以减少资源消耗
fps = 15  # 降低帧率以减少资源消耗
width, height = 1280, 720  # 降低分辨率以减少资源消耗

# 获取图片文件列表
image_files = [f for f in os.listdir(image_dir) if f.endswith(('.jpg', '.jpeg', '.png'))]
if not image_files:
    print("错误：没有找到图片文件！")
    exit(1)

# 只使用第一张图片
single_image = os.path.join(image_dir, image_files[0])
print(f"使用图片: {single_image}")

# 准备FFmpeg命令
cmd = [
    'ffmpeg',
    '-loop', '1', '-i', single_image,
    '-f', 'lavfi', '-i', f'color=c=black:s={width}x{height}:r={fps}',
    '-filter_complex', (
        f'[0:v]scale={width//2}:{height//2}:force_original_aspect_ratio=decrease:flags=lanczos,pad={width//2}:{height//2}:(ow-iw)/2:(oh-ih)/2:black[scaled];'
        f'[1:v][scaled]overlay=x="if(lt(t,1),{width}-{width//4}-(t*{width}/1),{width//4})":y={height//4}:shortest=1'
    ),
    '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '30',  # 更低的质量以加快处理
    '-pix_fmt', 'yuv420p', '-t', str(video_duration), '-r', str(fps), '-y', output_file
]

print(f"执行FFmpeg命令...")

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