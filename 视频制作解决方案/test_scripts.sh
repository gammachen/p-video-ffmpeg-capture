#!/bin/bash

# 测试脚本，用于验证resize_images.sh和resize_image_and_to_video.sh的参数化功能

# 设置脚本目录
SCRIPT_DIR="$(dirname "$0")"
RESIZE_SCRIPT="$SCRIPT_DIR/resize_images.sh"
VIDEO_SCRIPT="$SCRIPT_DIR/resize_image_and_to_video.sh"

# 打印测试信息
print_test() {
    echo "\n========================"
    echo "$1"
    echo "========================"
}

# 检查脚本是否存在且可执行
check_scripts() {
    local missing=false
    
    if [ ! -x "$RESIZE_SCRIPT" ]; then
        echo "错误：resize_images.sh 脚本不存在或不可执行！" >&2
        missing=true
    fi
    
    if [ ! -x "$VIDEO_SCRIPT" ]; then
        echo "错误：resize_image_and_to_video.sh 脚本不存在或不可执行！" >&2
        missing=true
    fi
    
    if [ "$missing" = true ]; then
        exit 1
    fi
}

# 测试resize_images.sh的帮助信息
print_test "测试resize_images.sh帮助信息"
bash "$RESIZE_SCRIPT" --help

# 测试resize_image_and_to_video.sh的帮助信息
print_test "测试resize_image_and_to_video.sh帮助信息"
bash "$VIDEO_SCRIPT" --help

# 测试resize_images.sh的基本参数
print_test "测试resize_images.sh基本参数"
bash "$RESIZE_SCRIPT" -p "*.jpg" -o "test_" --dry-run

# 测试resize_image_and_to_video.sh的基本参数
print_test "测试resize_image_and_to_video.sh基本参数"
bash "$VIDEO_SCRIPT" -p "*.jpg" -o "test_video.mp4" -d 2 --dry-run

# 提示用户如何进行实际测试
echo "\n======================================="
echo "测试脚本已完成基本功能验证。"
echo "要进行实际测试，请运行以下命令："
echo "1. 调整图片尺寸：$RESIZE_SCRIPT -p '你的图片模式' -o '输出前缀'"
echo "2. 生成视频：$VIDEO_SCRIPT -p '你的图片模式' -o '输出视频.mp4'"
echo "3. 指定尺寸：$VIDEO_SCRIPT -p '你的图片模式' -o '输出视频.mp4' -w 1920 -h 1080"
echo "======================================="