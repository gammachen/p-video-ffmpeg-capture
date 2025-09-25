#!/bin/bash
# resize_images.sh
# 调整图片尺寸的脚本，支持参数化输入

# 默认参数
IMAGE_PATTERN="artistic_portrait_1_*.jpg"
OUTPUT_PREFIX="resized_"
DEFAULT_WIDTH=1280
DEFAULT_HEIGHT=720

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo "  调整图片尺寸到统一大小"
    echo ""
    echo "选项:"
    echo "  -p, --pattern <模式>    图片匹配模式 (默认: $IMAGE_PATTERN)"
    echo "  -o, --output <前缀>     输出图片前缀 (默认: $OUTPUT_PREFIX)"
    echo "  -w, --width <宽度>      目标宽度 (默认: 自动计算最大宽度)"
    echo "  -h, --height <高度>     目标高度 (默认: 自动计算最大高度)"
    echo "  --help                  显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -p 'photos/*.jpg' -o 'processed_'"
    echo "  $0 -p 'images/*.png' -w 1920 -h 1080"
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--pattern)
                IMAGE_PATTERN="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_PREFIX="$2"
                shift 2
                ;;
            -w|--width)
                TARGET_WIDTH="$2"
                shift 2
                ;;
            -h|--height)
                TARGET_HEIGHT="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "错误: 未知选项 '$1'" >&2
                show_help
                exit 1
                ;;
        esac
    done
}

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

# 查找所有图片的最大尺寸或使用指定尺寸
find_max_dimensions() {
    # 如果用户指定了目标宽度和高度，直接使用它们
    if [ -n "$TARGET_WIDTH" ] && [ -n "$TARGET_HEIGHT" ]; then
        echo "使用用户指定的尺寸: $TARGET_WIDTH x $TARGET_HEIGHT"
        # 确保尺寸为偶数（视频编码要求）
        MAX_WIDTH=$((TARGET_WIDTH / 2 * 2))
        MAX_HEIGHT=$((TARGET_HEIGHT / 2 * 2))
        echo "调整为偶数尺寸: $MAX_WIDTH x $MAX_HEIGHT"
        return
    fi
    
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
        echo "警告：未找到任何图片，使用默认尺寸 $DEFAULT_WIDTH x $DEFAULT_HEIGHT"
        max_width=$DEFAULT_WIDTH
        max_height=$DEFAULT_HEIGHT
    fi
    
    # 如果用户只指定了宽度或高度，按比例计算另一维
    if [ -n "$TARGET_WIDTH" ]; then
        echo "用户指定了宽度，按比例调整高度"
        MAX_WIDTH=$((TARGET_WIDTH / 2 * 2))
        # 按原图宽高比计算高度
        if [ $max_width -gt 0 ]; then
            MAX_HEIGHT=$(( (TARGET_WIDTH * max_height) / max_width / 2 * 2 ))
        else
            MAX_HEIGHT=$DEFAULT_HEIGHT
        fi
        echo "调整后的尺寸: $MAX_WIDTH x $MAX_HEIGHT"
    elif [ -n "$TARGET_HEIGHT" ]; then
        echo "用户指定了高度，按比例调整宽度"
        MAX_HEIGHT=$((TARGET_HEIGHT / 2 * 2))
        # 按原图宽高比计算宽度
        if [ $max_height -gt 0 ]; then
            MAX_WIDTH=$(( (TARGET_HEIGHT * max_width) / max_height / 2 * 2 ))
        else
            MAX_WIDTH=$DEFAULT_WIDTH
        fi
        echo "调整后的尺寸: $MAX_WIDTH x $MAX_HEIGHT"
    else
        # 返回最大尺寸（通过全局变量）
        MAX_WIDTH=$max_width
        MAX_HEIGHT=$max_height
    fi
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

# 主函数
main() {
    # 解析命令行参数
    parse_args "$@"
    
    check_dependencies
    find_max_dimensions
    resize_images_to_max
    
    # 输出处理结果
    echo "\n图片尺寸调整任务完成！"
    echo "- 输入图片模式: $IMAGE_PATTERN"
    echo "- 输出图片前缀: $OUTPUT_PREFIX"
    echo "- 调整后尺寸: $MAX_WIDTH x $MAX_HEIGHT"
}

# 执行主函数
main "$@"