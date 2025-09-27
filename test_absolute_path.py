import subprocess
import sys
import os

# 获取当前工作目录的绝对路径
base_dir = os.path.abspath('.')

# 使用绝对路径的图片（确保文件存在）
image_path = os.path.join(base_dir, '视频制作解决方案', 'captured', '0001.jpg')
output_path = os.path.join(base_dir, 'direct-test.mp4')

# 确保图片文件存在
if not os.path.exists(image_path):
    print(f"错误：找不到图片文件 {image_path}")
    sys.exit(1)

# 构建FFmpeg命令，使用绝对路径的FFmpeg
command = [
    '/opt/homebrew/bin/ffmpeg',
    '-loop', '1', '-i', image_path,
    '-f', 'lavfi', '-i', 'color=c=black:s=1280x720:r=15:d=3',
    '-filter_complex', '[1][0]overlay=x=320:y=0:shortest=1',
    '-c:v', 'libx264',
    '-crf', '30',
    '-preset', 'ultrafast',
    '-t', '3',
    '-y', output_path
]

print(f"执行命令: {' '.join(command)}")
print(f"图片路径: {image_path}")

# 测试直接在终端中执行的命令
print("\n建议直接在终端中执行的命令:")
print(f"cd {base_dir} && {' '.join(command)}")

try:
    # 执行FFmpeg命令
    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    print(f"返回代码: {result.returncode}")
    print(f"标准输出: {result.stdout[:500]}")
    print(f"标准错误: {result.stderr[:500]}")
    
    if result.returncode == 0:
        print(f"\n视频创建成功: {output_path}")
        if os.path.exists(output_path):
            print(f"文件大小: {os.path.getsize(output_path)} 字节")
        else:
            print("文件不存在")
    else:
        print("\nFFmpeg命令执行失败")
        sys.exit(1)

except Exception as e:
    print(f"\n执行命令时出错: {e}")
    sys.exit(1)