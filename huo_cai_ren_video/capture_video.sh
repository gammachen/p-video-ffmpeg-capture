#!/bin/bash
# 视频截图生成统一格式的图片集合
# 从指定时间范围截取连续的视频帧

# 视频文件路径
VIDEO_FILE="火柴人-武斗.mp4"
# 输出图片格式
OUTPUT_FORMAT="output_%03d.jpg"
# 截图频率：每秒截图数量 (增加这个值可以获得更连续的截图)
FRAMES_PER_SECOND=5
# 开始时间：1分27秒 = 87秒
START_TIME="00:01:27"
# 结束时间：3分钟 = 180秒
END_TIME="00:03:00"

# 检查视频文件是否存在
if [ ! -f "$VIDEO_FILE" ]; then
    echo "错误：视频文件 '$VIDEO_FILE' 不存在！"
    exit 1
fi

# 检查ffmpeg是否安装
if ! command -v ffmpeg &> /dev/null; then
    echo "错误：未找到ffmpeg，请先安装ffmpeg！"
    exit 1
fi

# 显示当前设置信息
echo "视频文件: $VIDEO_FILE"
echo "输出格式: $OUTPUT_FORMAT"
echo "截图频率: $FRAMES_PER_SECOND 帧/秒"
echo "截图范围: 从 $START_TIME 到 $END_TIME"
echo "开始截图..."

# 使用ffmpeg从指定时间范围截图
# -ss: 指定开始时间点
# -to: 指定结束时间点
# -i: 输入文件
# -vf: 视频滤镜，这里使用fps设置截图频率
# -q:v 2: 设置较高的图片质量
# -start_number 1: 从1开始编号
ffmpeg -ss "$START_TIME" -to "$END_TIME" -i "$VIDEO_FILE" -vf "fps=$FRAMES_PER_SECOND" -q:v 2 -start_number 1 "$OUTPUT_FORMAT"

# 检查命令执行是否成功
if [ $? -eq 0 ]; then
    # 统计生成的图片数量
    NUM_IMAGES=$(ls -1 $OUTPUT_FORMAT 2>/dev/null | wc -l)
    if [ $NUM_IMAGES -gt 0 ]; then
        echo "截图完成！成功生成了 $NUM_IMAGES 张图片。"
        echo "图片保存在: $(pwd)"
    else
        echo "警告：没有生成截图文件。请检查视频文件和时间范围设置。"
    fi
else
    echo "错误：截图过程中出现问题！"
    exit 1
fi
