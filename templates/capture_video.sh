#!/bin/bash
# 视频截图生成统一格式的图片集合
# 视频文件路径：input.mp4
# 输出图片格式：output_%03d.jpg
# 截图频率：10帧/秒
ffmpeg -i input.mp4 -vf "fps=1/10" output_%03d.jpg
echo "截图完成！"
