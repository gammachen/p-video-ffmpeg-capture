#!/bin/bash
# resize_image_and_to_video.sh
# 调整图片尺寸并生成视频的脚本

# 配置参数
IMAGE_PATTERN="artistic_portrait_1_*.jpg"
OUTPUT_PREFIX="resized_"
VIDEO_FPS=25
VIDEO_DURATION_PER_IMAGE=3  # 每张图片在视频中显示的秒数
VIDEO_BITRATE="2M"
VIDEO_OUTPUT="slideshow.mp4"

# 检查依赖命令
check_dependencies() {
    local missing=false
    
    if ! command -v ffmpeg &> /dev/null; then
        echo "错误：未找到ffmpeg，请先安装ffmpeg！" >&2
        missing=true
    fi
    
    if ! command -v identify &> /dev/null; then
        echo "错误：未找到identify命令（ImageMagick的一部分），请先安装ImageMagick！" >&2
        missing=true
    fi
    
    if [ "$missing" = true ]; then
        exit 1
    fi
}

# 查找所有图片的最大尺寸
find_max_dimensions() {
    echo "正在扫描所有图片，查找最大尺寸..."
    local max_width=0
    local max_height=0
    local total_images=0
    
    for img in $IMAGE_PATTERN; do
        if [ -f "$img" ]; then
            total_images=$((total_images + 1))
            # 获取图片尺寸
            dimensions=$(identify -format "%wx%h" "$img" 2>/dev/null)
            
            if [ $? -eq 0 ]; then
                width=$(echo $dimensions | cut -d'x' -f1)
                height=$(echo $dimensions | cut -d'x' -f2)
                
                # 更新最大宽度和高度
                if [ $width -gt $max_width ]; then
                    max_width=$width
                fi
                if [ $height -gt $max_height ]; then
                    max_height=$height
                fi
            else
                echo "警告：无法获取图片尺寸: $img" >&2
            fi
        fi
    done
    
    # 确保最大尺寸为偶数（视频编码要求）
    max_width=$((max_width / 2 * 2))
    max_height=$((max_height / 2 * 2))
    
    echo "找到 $total_images 张图片的最大尺寸: $max_width x $max_height"
    
    # 如果没有找到图片，设置默认尺寸
    if [ $total_images -eq 0 ]; then
        echo "警告：未找到任何图片，使用默认尺寸 1280x720"
        max_width=1280
        max_height=720
    fi
    
    # 返回最大尺寸（通过全局变量）
    MAX_WIDTH=$max_width
    MAX_HEIGHT=$max_height
}

# 调整图片尺寸到最大尺寸并填充黑色
resize_images_to_max() {
    echo "开始调整所有图片到最大尺寸 $MAX_WIDTH x $MAX_HEIGHT..."
    local success_count=0
    local failure_count=0
    
    for img in $IMAGE_PATTERN; do
        if [ -f "$img" ]; then
            # 获取原图尺寸
            dimensions=$(identify -format "%wx%h" "$img" 2>/dev/null)
            
            if [ $? -eq 0 ]; then
                orig_width=$(echo $dimensions | cut -d'x' -f1)
                orig_height=$(echo $dimensions | cut -d'x' -f2)
                
                # 使用ffmpeg调整图片尺寸并填充黑色
                # scale=iw*max($MAX_WIDTH/iw,$MAX_HEIGHT/ih):ih*max($MAX_WIDTH/iw,$MAX_HEIGHT/ih) - 保持宽高比缩放到覆盖最大尺寸
                # crop=$MAX_WIDTH:$MAX_HEIGHT - 从中心裁剪到最大尺寸
                # 或者使用 pad=$MAX_WIDTH:$MAX_HEIGHT:(ow-iw)/2:(oh-ih)/2:black - 保持原始大小并填充黑色
                # 这里使用第一种方法：先缩放到覆盖，再裁剪到最大尺寸
                if ffmpeg -i "$img" \
                    -vf "scale=iw*max($MAX_WIDTH/iw\,$MAX_HEIGHT/ih):ih*max($MAX_WIDTH/iw\,$MAX_HEIGHT/ih),crop=$MAX_WIDTH:$MAX_HEIGHT" \
                    -frames:v 1 "${OUTPUT_PREFIX}$img" -y &> /dev/null; then
                    echo "调整尺寸: $img ($orig_width x $orig_height) → ${OUTPUT_PREFIX}$img ($MAX_WIDTH x $MAX_HEIGHT)"
                    success_count=$((success_count + 1))
                else
                    echo "调整尺寸失败: $img" >&2
                    failure_count=$((failure_count + 1))
                fi
            else
                echo "无法获取图片尺寸: $img" >&2
                failure_count=$((failure_count + 1))
            fi
        fi
    done
    
    echo "图片处理完成！成功: $success_count 张, 失败: $failure_count 张"
    
    # 如果没有成功处理的图片，退出脚本
    if [ $success_count -eq 0 ]; then
        echo "错误：没有成功处理任何图片，无法生成视频！" >&2
        exit 1
    fi
}

# 生成视频
create_video() {
    echo "开始生成视频..."
    
    # 计算输入帧率（每张图片显示3秒）
    input_framerate="1/$VIDEO_DURATION_PER_IMAGE"
    
    # 使用glob模式匹配所有调整后的图片
    if ffmpeg -framerate $input_framerate -pattern_type glob -i "${OUTPUT_PREFIX}${IMAGE_PATTERN}" \
        -vf "fps=$VIDEO_FPS,format=yuv420p" \
        -c:v libx264 -crf 23 -b:v $VIDEO_BITRATE -preset medium \
        -movflags +faststart \
        "$VIDEO_OUTPUT" -y; then
        echo "视频生成成功: $VIDEO_OUTPUT"
        echo "视频信息："
        echo "- 帧率: $VIDEO_FPS fps"
        echo "- 每张图片显示: $VIDEO_DURATION_PER_IMAGE 秒"
        echo "- 视频比特率: $VIDEO_BITRATE"
        echo "- 视频分辨率: $MAX_WIDTH x $MAX_HEIGHT"
    else
        echo "错误：视频生成失败！" >&2
        exit 1
    fi
}

# 主函数
main() {
    check_dependencies
    find_max_dimensions
    resize_images_to_max
    create_video
}

# 执行主函数
main