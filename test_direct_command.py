import subprocess
import sys

# 这个脚本直接复制之前在终端成功运行的FFmpeg命令
# 我们使用一个绝对路径的图片（确保文件存在）
image_path = "视频制作解决方案/captured/0001.jpg"
output_path = "direct-command-test.mp4"

# 构建之前成功的FFmpeg命令
command = [
    'ffmpeg',
    '-loop', '1', '-i', image_path,
    '-f', 'lavfi', '-i', 'color=c=black:s=1280x720:r=15:d=3',
    '-filter_complex', '[1][0]overlay=x="if(lt(t,1),1280-320-(t*1280/1),320)":y=0:shortest=1',
    '-c:v', 'libx264',
    '-crf', '30',
    '-preset', 'ultrafast',
    '-t', '3',
    '-y', output_path
]

print(f"执行命令: {' '.join(command)}")

try:
    # 执行FFmpeg命令
    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    if result.returncode == 0:
        print(f"视频创建成功: {output_path}")
        # 检查文件是否存在
        import os
        if os.path.exists(output_path):
            print(f"文件大小: {os.path.getsize(output_path)} 字节")
        else:
            print("文件不存在")
    else:
        print(f"FFmpeg命令执行失败，返回代码: {result.returncode}")
        print(f"FFmpeg标准输出: {result.stdout[:500]}")
        print(f"FFmpeg标准错误: {result.stderr[:500]}")
        sys.exit(1)

except Exception as e:
    print(f"执行命令时出错: {e}")
    sys.exit(1)