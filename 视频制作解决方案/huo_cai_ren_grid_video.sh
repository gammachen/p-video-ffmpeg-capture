#!/bin/bash
# 火柴人图片网格视频合成脚本
# 将图片按照1x2、2x4、3x6等行列模式合并成视频，并生成不同速度的视频，最后合并所有视频

# 配置参数
IMAGE_DIR="/Users/shhaofu/Code/cursor-projects/p-video-ffmpeg-capture/huo_cai_ren_video"
OUTPUT_DIR="/Users/shhaofu/Code/cursor-projects/p-video-ffmpeg-capture/huo_cai_ren_output"
IMAGE_PATTERN="output_%03d.jpg"
GRID_VIDEO_PREFIX="grid_video_"
MIDDLE_VIDEO="pic_to_video_middle_speech.mp4"
FAST_VIDEO="pic_to_video_fast_speech.mp4"
FINAL_MERGED="final_merged.mp4"
MAX_WIDTH=1920  # 最大视频宽度
MAX_HEIGHT=1080 # 最大视频高度
VIDEO_DURATION=1  # 每个网格视频的持续时间（秒）

# 初始化变量，防止未调用count_images时出现变量未定义错误
NUM_IMAGES=0  # 默认值，会在count_images函数中更新

# 确保输出目录存在
mkdir -p "$OUTPUT_DIR"

# 检查ffmpeg是否安装
check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        echo "错误：未找到ffmpeg，请先安装ffmpeg！"
        exit 1
    fi
}

# 统计图片数量
count_images() {
    echo "正在统计图片数量..."
    # 使用ls和wc统计图片数量
    cd "$IMAGE_DIR"
    IMAGE_LIST=($(ls -1 output_*.jpg 2>/dev/null | sort -V))
    NUM_IMAGES=${#IMAGE_LIST[@]}
    cd -
    
    if [ $NUM_IMAGES -eq 0 ]; then
        echo "错误：未找到任何图片文件！请检查图片目录。"
        exit 1
    fi
    
    echo "找到 $NUM_IMAGES 张图片。"
}

# 创建网格视频（按照1x2, 2x4, 3x6等模式）
create_grid_videos() {
    echo "开始创建网格视频..."
    local current_index=0
    local grid_level=1
    local video_count=0
    
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
        create_grid_image "$current_index" "$required_images" "$rows" "$cols" "$grid_image"
        
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
}

# 创建单个网格图片
create_grid_image() {
    local start_index=$1
    local count=$2
    local rows=$3
    local cols=$4
    local output_file=$5
    
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
        local img_path="$IMAGE_DIR/${IMAGE_LIST[$file_index]}"
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

# 创建不同速度的视频
create_speed_videos() {
    echo "开始创建不同速度的视频..."
    
    # 中速视频 (5fps)
    echo "正在创建中速视频 (5fps)..."
    ffmpeg -framerate 5 -i "$IMAGE_DIR/$IMAGE_PATTERN" -vf "format=yuv420p" -c:v libx264 -crf 23 -preset medium "$OUTPUT_DIR/$MIDDLE_VIDEO" -y
    
    if [ $? -eq 0 ]; then
        echo "成功创建中速视频: $OUTPUT_DIR/$MIDDLE_VIDEO"
    else
        echo "创建中速视频失败！" >&2
    fi
    
    # 快速视频 (15fps)
    echo "正在创建快速视频 (15fps)..."
    ffmpeg -framerate 15 -i "$IMAGE_DIR/$IMAGE_PATTERN" -vf "format=yuv420p" -c:v libx264 -crf 23 -preset medium "$OUTPUT_DIR/$FAST_VIDEO" -y
    
    if [ $? -eq 0 ]; then
        echo "成功创建快速视频: $OUTPUT_DIR/$FAST_VIDEO"
    else
        echo "创建快速视频失败！" >&2
    fi
}

# 获取final_merged_effects.mp4视频
get_effects_video() {
    echo "正在检查final_merged_effects.mp4视频..."
    local effects_video="/Users/shhaofu/Code/cursor-projects/p-video-ffmpeg-capture/effects_output/final_merged_effects.mp4"
    
    if [ -f "$effects_video" ]; then
        echo "找到final_merged_effects.mp4，复制到输出目录..."
        cp "$effects_video" "$OUTPUT_DIR/"
    else
        echo "警告：未找到final_merged_effects.mp4视频！将跳过此视频的合并。"
    fi
}

# 合并所有视频并添加过场特效
merge_all_videos() {
    echo "开始合并所有视频..."
    
    # 创建视频列表
    local video_list="$OUTPUT_DIR/all_videos.txt"
    rm -f "$video_list"
       
    # 添加所有网格视频 - 使用find命令更可靠
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
    
    # 添加特效视频
    if [ -f "$OUTPUT_DIR/final_merged_effects.mp4" ]; then
        echo "添加特效视频: final_merged_effects.mp4"
        echo "file '$OUTPUT_DIR/final_merged_effects.mp4'" >> "$video_list"
    else
        echo "警告：未找到特效视频 final_merged_effects.mp4！"
    fi
    
    # 检查是否有视频可以合并
    local video_count=$(wc -l < "$video_list" 2>/dev/null || echo 0)
    
    if [ $video_count -eq 0 ]; then
        echo "错误：没有找到任何视频可以合并！" >&2
        rm -f "$video_list"
        exit 1
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
    else
        echo "视频合并失败！" >&2
    fi
    
    # 清理临时文件
    rm -f "$video_list"
}

# 主函数
main() {
    echo "开始火柴人图片网格视频合成任务..."
    check_ffmpeg
    count_images
    create_grid_videos
    create_speed_videos
    get_effects_video
    merge_all_videos
    echo "任务完成！所有视频已保存在: $OUTPUT_DIR"
}

# 执行主函数
main

