#!/bin/bash
# resize_image_and_to_video.sh
# 调整图片尺寸并生成视频的脚本，支持参数化输入，可选择生成基础视频或复杂网格视频

# 默认参数 - 基础视频
IMAGE_DIR="."
IMAGE_PATTERN="artistic_portrait_1_*.jpg"
OUTPUT_PREFIX="resized_"
VIDEO_FPS=25
VIDEO_DURATION_PER_IMAGE=3  # 每张图片在视频中显示的秒数
VIDEO_BITRATE="2M"
VIDEO_OUTPUT="slideshow.mp4"
RESIZE_SCRIPT="$(dirname "$0")/resize_images.sh"

# 默认参数 - 复杂视频
GRID_ENABLED=false
GRID_VIDEO_PREFIX="grid_video_"
MIDDLE_VIDEO="pic_to_video_middle_speech.mp4"
FAST_VIDEO="pic_to_video_fast_speech.mp4"
FINAL_MERGED="final_merged.mp4"
VIDEO_DURATION=1  # 每个网格视频的持续时间（秒）

# 初始化变量
NUM_IMAGES=0  # 默认值，会在count_images函数中更新
MAX_WIDTH=1920  # 最大视频宽度
MAX_HEIGHT=1080 # 最大视频高度

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo "  调整图片尺寸并生成视频，支持基础视频和复杂网格视频制作"
    echo ""
    echo "基础视频选项:"
    echo "  -p, --pattern <模式>    图片匹配模式 (默认: $IMAGE_PATTERN)"
    echo "  -o, --output <文件>     输出视频文件名 (默认: $VIDEO_OUTPUT)"
    echo "  -f, --fps <帧率>        视频帧率 (默认: $VIDEO_FPS)"
    echo "  -d, --duration <秒数>   每张图片显示秒数 (默认: $VIDEO_DURATION_PER_IMAGE)"
    echo "  -b, --bitrate <比特率>  视频比特率 (默认: $VIDEO_BITRATE)"
    echo "  -w, --width <宽度>      目标宽度 (传递给resize_images.sh)"
    echo "  -h, --height <高度>     目标高度 (传递给resize_images.sh)"
    echo ""
    echo "复杂视频选项:"
    echo "  --enable-grid           启用网格视频制作功能"
    echo "  --grid-duration <秒>    每个网格视频的持续时间 (默认: $VIDEO_DURATION)"
    echo "  --grid-output <目录>    网格视频和最终合并视频的输出目录"
    echo ""
    echo "其他选项:"
    echo "  --help                  显示帮助信息"
    echo ""
    echo "示例:"
    echo "  # 生成基础幻灯片视频"
    echo "  $0 -p 'photos/*.jpg' -o 'my_slideshow.mp4' -d 5"
    echo "  生成复杂网格视频"
    echo "  $0 -p 'images/*.png' -o 'presentation.mp4' --enable-grid"
}

# 解析命令行参数
parse_args() {
    # 保存传递给resize_images.sh的参数
    local resize_args=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            # 基础视频参数
            --image-dir)
                IMAGE_DIR="$2"
                shift 2
                ;;
            -p|--pattern)
                IMAGE_PATTERN="$2"
                resize_args+=(-p "$2")
                shift 2
                ;;
            -o|--output)
                VIDEO_OUTPUT="$2"
                shift 2
                ;;
            -f|--fps)
                VIDEO_FPS="$2"
                shift 2
                ;;
            -d|--duration)
                VIDEO_DURATION_PER_IMAGE="$2"
                shift 2
                ;;
            -b|--bitrate)
                VIDEO_BITRATE="$2"
                shift 2
                ;;
            -w|--width)
                resize_args+=(-w "$2")
                # 更新最大尺寸变量
                MAX_WIDTH="$2"
                shift 2
                ;;
            -h|--height)
                resize_args+=(-h "$2")
                # 更新最大尺寸变量
                MAX_HEIGHT="$2"
                shift 2
                ;;
                
            # 复杂视频参数
            --enable-grid)
                GRID_ENABLED=true
                shift
                ;;
            --grid-duration)
                VIDEO_DURATION="$2"
                shift 2
                ;;
            --grid-output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
                
            # 其他参数
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
    
    # 设置默认输出目录
    if [ -z "$OUTPUT_DIR" ]; then
        OUTPUT_DIR="$(dirname "$0")/output"
    fi
    
    # 保存resize脚本参数供后续使用
    RESIZE_ARGS="${resize_args[@]}"
    
    # 确保IMAGE_DIR目录存在
    if [ ! -d "$IMAGE_DIR" ]; then
        echo "错误：图片目录 $IMAGE_DIR 不存在！" >&2
        exit 1
    fi
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

# 统计图片数量 - 从参考脚本复制并适配IMAGE_DIR
count_images() {
    echo "正在统计图片数量..."
    # 使用ls和wc统计调整后的图片数量
    local adjusted_images=($(ls -1 ${OUTPUT_PREFIX}${IMAGE_PATTERN} 2>/dev/null | sort -V))
    NUM_IMAGES=${#adjusted_images[@]}
    
    if [ $NUM_IMAGES -eq 0 ]; then
        echo "错误：未找到任何调整后的图片文件！请检查图片处理是否成功。" >&2
        return 1
    fi
    
    echo "找到 $NUM_IMAGES 张调整后的图片。"
    return 0
}

# 创建网格视频 - 从参考脚本复制并适配
create_grid_videos() {
    echo "开始创建网格视频..."
    local current_index=0
    local grid_level=1
    local video_count=0
    
    # 获取所有调整后的图片
    local adjusted_images=($(ls -1 ${OUTPUT_PREFIX}${IMAGE_PATTERN} 2>/dev/null | sort -V))
    
    while [ $current_index -lt $NUM_IMAGES ]; do
        # 计算当前网格的行列数（行数=grid_level，列数=grid_level*2）
        local rows=$grid_level
        local cols=$((grid_level * 2))
        local required_images=$((rows * cols))
        
        # 计算实际可用的图片数量
        local available_images=$((NUM_IMAGES - current_index))
        if [ $available_images -lt $required_images ]; then
            required_images=$available_images
            # 调整行列数以适应剩余图片
            best_rows=1
            best_cols=1
            max_cells=0
            
            for ((r=1; r<=grid_level; r++)); do
                for ((c=1; c<=grid_level*2; c++)); do
                    cells=$((r * c))
                    if [ $cells -le $available_images ] && [ $cells -gt $max_cells ]; then
                        max_cells=$cells
                        best_rows=$r
                        best_cols=$c
                    fi
                done
            done
            
            rows=$best_rows
            cols=$best_cols
            required_images=$max_cells
        fi
        
        local end_index=$((current_index + required_images))
        local video_file="$OUTPUT_DIR/${GRID_VIDEO_PREFIX}${rows}x${cols}_$((current_index+1))-${end_index}.mp4"
        echo "正在创建 ${rows}x${cols} 网格视频，使用图片 $((current_index+1))-$end_index..."
        
        # 创建临时目录存放中间处理的图片
        local temp_dir="$OUTPUT_DIR/temp_${grid_level}"
        mkdir -p "$temp_dir"
        
        # 创建网格图片
        local grid_image="$temp_dir/grid_image_${rows}x${cols}.jpg"
        create_grid_image "$current_index" "$required_images" "$rows" "$cols" "$grid_image" "${adjusted_images[@]}"
        
        if [ -f "$grid_image" ]; then
            # 将网格图片转换为视频
            if ffmpeg -loop 1 -i "$grid_image" -t $VIDEO_DURATION -vf "format=yuv420p" -c:v libx264 -crf 23 -preset medium "$video_file" -y; then
                echo "成功创建网格视频: $video_file"
                video_count=$((video_count + 1))
            else
                echo "创建网格视频失败: $video_file" >&2
            fi
        else
            echo "创建网格图片失败，跳过此视频！" >&2
        fi
        
        # 清理临时目录
        rm -rf "$temp_dir"
        
        # 更新索引和网格级别
        current_index=$end_index
        grid_level=$((grid_level + 1))
        
        # 安全限制，避免无限循环
        if [ $grid_level -gt 10 ]; then
            break
        fi
    done
    
    echo "网格视频创建完成！共创建了 $video_count 个网格视频。"
    if [ $video_count -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# 创建单个网格图片 - 从参考脚本复制并适配
create_grid_image() {
    local start_index=$1
    local count=$2
    local rows=$3
    local cols=$4
    local output_file=$5
    shift 5
    local adjusted_images=($@)
    
    # 计算每个单元格的尺寸
    local cell_width=$((MAX_WIDTH / cols))
    local cell_height=$((MAX_HEIGHT / rows))
    
    # 确保尺寸是偶数（H.264要求）
    cell_width=$((cell_width / 2 * 2))
    cell_height=$((cell_height / 2 * 2))
    
    # 构建FFmpeg输入参数和滤镜
    local input_params=""
    local filter_parts=""
    
    # 添加输入文件
    for ((i=0; i<count; i++)); do
        local file_index=$((start_index + i))
        local img_path="${adjusted_images[$file_index]}"
        input_params="$input_params -i $img_path"
        filter_parts="$filter_parts [$i:v]scale=${cell_width}:${cell_height}:force_original_aspect_ratio=decrease:flags=lanczos,pad=${cell_width}:${cell_height}:(ow-iw)/2:(oh-ih)/2:black[img$((i+1))];"
    done
    
    # 构建行堆叠
    local filter_layout=""
    for ((row=0; row<rows; row++)); do
        local row_inputs=""
        for ((col=0; col<cols; col++)); do
            local index=$((row * cols + col))
            if [ $index -lt $count ]; then
                row_inputs="$row_inputs[img$((index+1))]"
            else
                # 如果图片不够，创建空白单元格
                filter_parts="$filter_parts color=c=black:s=${cell_width}x${cell_height}[blank$index];"
                row_inputs="$row_inputs[blank$index]"
            fi
        done
        filter_layout="$filter_layout $row_inputs hstack=inputs=${cols}[row$((row+1))];"
    done
    
    # 垂直堆叠所有行
    local row_inputs=""
    for ((row=0; row<rows; row++)); do
        row_inputs="$row_inputs[row$((row+1))]"
    done
    filter_layout="$filter_layout $row_inputs vstack=inputs=${rows}[final]"
    
    # 执行FFmpeg命令创建网格图片
    ffmpeg $input_params -filter_complex "$filter_parts $filter_layout" -map "[final]" -q:v 2 "$output_file" -y
}

# 创建不同速度的视频 - 从参考脚本复制并适配
create_videos_with_different_speeds() {
    echo "===== 创建不同速度的视频 ====="
    
    # 中速视频 (5fps)
    echo "正在创建中速视频 (5fps)..."
    if ffmpeg -framerate 5 -i "${OUTPUT_PREFIX}${IMAGE_PATTERN}" -vf "format=yuv420p" -c:v libx264 -crf 23 -preset medium "$OUTPUT_DIR/$MIDDLE_VIDEO" -y; then
        echo "成功创建中速视频: $OUTPUT_DIR/$MIDDLE_VIDEO"
    else
        echo "创建中速视频失败！" >&2
        return 1
    fi
    
    # 快速视频 (15fps)
    echo "正在创建快速视频 (15fps)..."
    if ffmpeg -framerate 15 -i "${OUTPUT_PREFIX}${IMAGE_PATTERN}" -vf "format=yuv420p" -c:v libx264 -crf 23 -preset medium "$OUTPUT_DIR/$FAST_VIDEO" -y; then
        echo "成功创建快速视频: $OUTPUT_DIR/$FAST_VIDEO"
        echo "===== 不同速度视频创建完成 ====="
        return 0
    else
        echo "创建快速视频失败！" >&2
        return 1
    fi
}

# 合并所有视频并添加过场特效 - 从参考脚本复制并适配
merge_videos() {
    echo "===== 合并所有视频 ====="
    
    # 创建视频列表
    local video_list="$OUTPUT_DIR/all_videos.txt"
    rm -f "$video_list"
    
    # 添加所有网格视频
    echo "正在查找网格视频..."
    local grid_video_count=0
    
    # 打印调试信息
    echo "搜索路径: $OUTPUT_DIR"
    echo "搜索模式: ${GRID_VIDEO_PREFIX}*.mp4"
    
    # 使用find命令查找文件
    find "$OUTPUT_DIR" -name "${GRID_VIDEO_PREFIX}*.mp4" -type f | sort -V > "$OUTPUT_DIR/grid_videos_temp.txt"
    
    echo "找到的网格视频数量: $(wc -l < "$OUTPUT_DIR/grid_videos_temp.txt" 2>/dev/null || echo 0)"
    
    # 读取文件列表并添加到视频列表
    while IFS= read -r video; do
        if [ -f "$video" ]; then
            echo "正在添加网格视频：$(basename "$video")"
            echo "file '$video'" >> "$video_list"
            grid_video_count=$((grid_video_count + 1))
        fi
    done < "$OUTPUT_DIR/grid_videos_temp.txt"
    
    # 手动添加已知的网格视频作为后备方案
    if [ $grid_video_count -eq 0 ]; then
        echo "尝试手动添加已知的网格视频..."
        for grid_video in "$OUTPUT_DIR"/grid_video_*.mp4; do
            if [ -f "$grid_video" ]; then
                echo "手动添加网格视频：$(basename "$grid_video")"
                echo "file '$grid_video'" >> "$video_list"
                grid_video_count=$((grid_video_count + 1))
            fi
        done
    fi
    
    # 清理临时文件
    rm -f "$OUTPUT_DIR/grid_videos_temp.txt"
    
    if [ $grid_video_count -eq 0 ]; then
        echo "警告：仍然没有找到任何网格视频！请检查输出目录。"
        echo "输出目录内容："
        ls -la "$OUTPUT_DIR"
    else
        echo "成功添加了 $grid_video_count 个网格视频。"
    fi
    
    # 添加不同速度的视频
    if [ -f "$OUTPUT_DIR/$MIDDLE_VIDEO" ]; then
        echo "添加中速视频: $MIDDLE_VIDEO"
        echo "file '$OUTPUT_DIR/$MIDDLE_VIDEO'" >> "$video_list"
    else
        echo "警告：未找到中速视频 $MIDDLE_VIDEO！"
    fi
    
    if [ -f "$OUTPUT_DIR/$FAST_VIDEO" ]; then
        echo "添加快速视频: $FAST_VIDEO"
        echo "file '$OUTPUT_DIR/$FAST_VIDEO'" >> "$video_list"
    else
        echo "警告：未找到快速视频 $FAST_VIDEO！"
    fi
    
    # 添加基础视频
    if [ -f "$OUTPUT_DIR/$VIDEO_OUTPUT" ]; then
        echo "添加基础视频: $VIDEO_OUTPUT"
        echo "file '$OUTPUT_DIR/$VIDEO_OUTPUT'" >> "$video_list"
    else
        echo "警告：未找到基础视频 $VIDEO_OUTPUT！"
    fi
    
    # 检查是否有视频可以合并
    local video_count=$(wc -l < "$video_list" 2>/dev/null || echo 0)
    
    if [ $video_count -eq 0 ]; then
        echo "错误：没有找到任何视频可以合并！" >&2
        rm -f "$video_list"
        return 1
    fi
    
    echo "找到 $video_count 个视频，准备合并..."
    echo "视频列表内容："
    cat "$video_list"
    
    # 添加转场效果并合并视频
    echo "正在添加转场特效（淡入淡出，0.5秒）并合并视频..."
    
    # 创建一个临时的修改后的视频列表，用于转场处理
    local transition_list="$OUTPUT_DIR/transition_list.txt"
    rm -f "$transition_list"
    
    # 为每个视频创建单独的淡入淡出效果
    local counter=0
    local temp_videos=()
    
    while IFS= read -r video_line; do
        # 提取视频路径（去掉file '...' 格式）
        local video_path=$(echo "$video_line" | sed -e "s/file '//" -e "s/'//")
        local temp_video="$OUTPUT_DIR/temp_video_$counter.mp4"
        
        # 为每个视频添加淡入淡出效果
        ffmpeg -i "$video_path" -vf "format=yuv420p,fade=in:st=0:d=0.5,fade=out:st=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video_path" | awk '{print $1-0.5}'):d=0.5" -c:v libx264 -crf 23 -preset medium "$temp_video" -y
        
        if [ $? -eq 0 ]; then
            echo "file '$temp_video'" >> "$transition_list"
            temp_videos+=($temp_video)
        fi
        
        counter=$((counter+1))
    done < "$video_list"
    
    # 使用concat协议合并带转场效果的视频
    ffmpeg -f concat -safe 0 -i "$transition_list" -c:v copy "$OUTPUT_DIR/$FINAL_MERGED" -y
    
    # 清理临时文件
    rm -f "$transition_list"
    for temp_video in "${temp_videos[@]}"; do
        rm -f "$temp_video"
    done
    
    if [ $? -eq 0 ]; then
        echo "视频合并成功！最终视频: $OUTPUT_DIR/$FINAL_MERGED"
        echo "===== 视频合并完成 ====="
        return 0
    else
        echo "视频合并失败！" >&2
        return 1
    fi
}

# 查找所有图片的最大尺寸
find_max_dimensions() {
    echo "正在扫描所有图片，查找最大尺寸..."
    local max_width=0
    local max_height=0
    local total_images=0
    
    # 保存当前目录，以便之后返回
    local current_dir=$(pwd)
    
    # 切换到图片目录
    cd "$IMAGE_DIR"
    
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
    
    # 返回原目录
    cd "$current_dir"
    
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
    
    # 保存当前目录，以便之后返回
    local current_dir=$(pwd)
    
    # 切换到图片目录
    cd "$IMAGE_DIR"
    
    # 获取所有匹配的图片文件并排序
    IMAGE_LIST=($(ls -1 $IMAGE_PATTERN 2>/dev/null | sort -V))
    
    # 检查是否找到图片
    if [ ${#IMAGE_LIST[@]} -eq 0 ]; then
        echo "错误：未找到任何匹配 $IMAGE_PATTERN 的图片文件！" >&2
        cd "$current_dir"
        exit 1
    fi
    
    # 遍历所有图片文件
    for img in "${IMAGE_LIST[@]}"; do
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
                    -frames:v 1 "$current_dir/${OUTPUT_PREFIX}$img" -y &> /dev/null; then
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
    
    # 返回原目录
    cd "$current_dir"
    
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
    
    # 计算输入帧率
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
        # 尝试获取视频分辨率信息
        if command -v ffprobe &> /dev/null; then
            video_info=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$VIDEO_OUTPUT" 2>/dev/null)
            if [ $? -eq 0 ]; then
                echo "- 视频分辨率: $video_info"
            fi
        fi
    else
        echo "错误：视频生成失败！" >&2
        exit 1
    fi
}

# 主函数
main() {
    # 解析命令行参数
    parse_args "$@"
    
    # 检查依赖命令
    check_dependencies
    
    # 检查并执行resize_images.sh脚本进行图片规范化处理
    if [ -f "$RESIZE_SCRIPT" ]; then
        echo "\n===== 开始执行图片规范化处理 ====="
        echo "调用脚本: $RESIZE_SCRIPT"
        echo "传递参数: ${RESIZE_ARGS[*]}"
        
        # 执行resize脚本
        if bash "$RESIZE_SCRIPT" ${RESIZE_ARGS[*]}; then
            echo "===== 图片规范化处理完成 =====\n"
        else
            echo "错误：图片规范化处理失败！" >&2
            exit 1
        fi
    else
        echo "警告：未找到resize_images.sh脚本，将使用当前脚本内的图片处理逻辑" >&2
        # 使用当前脚本内的图片处理逻辑作为后备
        find_max_dimensions
        resize_images_to_max
    fi
    
    # 生成基础视频
    create_video
    
    # 如果启用了网格视频功能，执行复杂视频制作流程
    if [ "$GRID_ENABLED" = true ]; then
        echo "\n===== 开始执行复杂视频制作流程 ====="
        
        # 确保输出目录存在
        mkdir -p "$OUTPUT_DIR"
        
        # 1. 创建网格视频
        if create_grid_videos; then
            # 2. 创建不同速度的视频
            local middle_speed_video="$OUTPUT_DIR/$MIDDLE_VIDEO"
            local fast_speed_video="$OUTPUT_DIR/$FAST_VIDEO"
            if create_videos_with_different_speeds "$VIDEO_OUTPUT" "$middle_speed_video" "$fast_speed_video"; then
                # 3. 合并所有视频
                local final_merged_video="$OUTPUT_DIR/$FINAL_MERGED"
                if merge_videos "$VIDEO_OUTPUT" "$middle_speed_video" "$fast_speed_video" "$final_merged_video"; then
                    echo "===== 复杂视频制作流程完成 =====\n"
                fi
            fi
        fi
    fi
    
    # 输出完成信息
    echo "\n视频生成任务已完成！"
    echo "- 输入图片模式: $IMAGE_PATTERN"
    echo "- 输出视频文件: $VIDEO_OUTPUT"
    echo "- 每张图片显示时间: $VIDEO_DURATION_PER_IMAGE 秒"
    echo "- 视频帧率: $VIDEO_FPS fps"
    echo "- 视频比特率: $VIDEO_BITRATE"
    
    # 如果启用了网格视频功能，显示相关信息
    if [ "$GRID_ENABLED" = true ]; then
        echo "- 复杂视频输出目录: $OUTPUT_DIR"
        echo "- 网格视频功能: 已启用"
        echo "- 每个网格视频持续时间: $VIDEO_DURATION 秒"
    else
        echo "- 网格视频功能: 未启用 (使用 --enable-grid 参数启用)"
    fi
}

# 执行主函数
main "$@"