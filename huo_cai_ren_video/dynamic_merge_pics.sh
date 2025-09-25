#!/bin/bash
# dynamic_grid_merge.sh

# 输入图片文件列表（按顺序）
INPUT_FILES=($(ls output_*.jpg | sort -V))
TOTAL_IMAGES=${#INPUT_FILES[@]}
MAX_WIDTH=1280
MAX_HEIGHT=1280

echo "找到 $TOTAL_IMAGES 张图片"
echo "开始生成动态合并视频..."

# 初始化变量
current_row=1
start_index=0

while [ $start_index -lt $TOTAL_IMAGES ]; do
    rows=$current_row
    cols=$((current_row * 2))  # 列数是行数的2倍
    required_images=$((rows * cols))
    available_images=$((TOTAL_IMAGES - start_index))
    
    # 如果剩余图片不够当前模式，调整到最大可能
    if [ $available_images -lt $required_images ]; then
        if [ $available_images -eq 0 ]; then
            break
        fi
        # 尝试找到最合适的行列组合
        best_rows=1
        best_cols=1
        max_cells=0
        
        for ((r=1; r<=current_row; r++)); do
            for ((c=1; c<=current_row*2; c++)); do
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
    
    echo "生成 ${rows}x${cols} 布局，使用图片 $((start_index+1))-$((start_index+required_images))"
    
    # 计算每个单元格的尺寸
    cell_width=$((MAX_WIDTH / cols))
    cell_height=$((MAX_HEIGHT / rows))
    
    # 确保尺寸是偶数（H.264要求）
    cell_width=$((cell_width / 2 * 2))
    cell_height=$((cell_height / 2 * 2))
    
    # 构建FFmpeg输入参数和滤镜
    input_params=""
    filter_parts=""
    
    # 添加输入文件
    for ((i=0; i<required_images; i++)); do
        file_index=$((start_index + i))
        input_params="$input_params -i ${INPUT_FILES[file_index]}"
        filter_parts="$filter_parts [$i:v]scale=${cell_width}:${cell_height}:force_original_aspect_ratio=decrease:flags=lanczos,pad=${cell_width}:${cell_height}:(ow-iw)/2:(oh-ih)/2:black[img$((i+1))];"
    done
    
    # 构建行堆叠
    filter_layout=""
    for ((row=0; row<rows; row++)); do
        row_inputs=""
        for ((col=0; col<cols; col++)); do
            index=$((row * cols + col))
            if [ $index -lt $required_images ]; then
                row_inputs="$row_inputs[img$((index+1))]"
            else
                # 如果图片不够，创建空白单元格
                row_inputs="$row_inputs color=${cell_width}x${cell_height}:color=black@0[blank$index]; [blank$index]"
            fi
        done
        filter_layout="$filter_layout $row_inputs hstack=${cols}[row$((row+1))];"
    done
    
    # 垂直堆叠所有行
    row_inputs=""
    for ((row=0; row<rows; row++)); do
        row_inputs="$row_inputs[row$((row+1))]"
    done
    filter_layout="$filter_layout $row_inputs vstack=${rows}[final]; [final]scale=${MAX_WIDTH}:${MAX_HEIGHT}:flags=lanczos"
    
    # 生成视频文件名
    output_file="merge_${rows}x${cols}_${((start_index+1))}-${((start_index+required_images))}.mp4"
    
    # 执行FFmpeg命令
    ffmpeg $input_params -filter_complex "$filter_parts $filter_layout" \
        -c:v libx264 -crf 23 -preset medium -pix_fmt yuv420p \
        -t 5 -r 1 "$output_file" -y
    
    echo "已生成: $output_file"
    
    # 更新索引和行数
    start_index=$((start_index + required_images))
    current_row=$((current_row + 1))
    
    # 安全限制，避免无限循环
    if [ $current_row -gt 10 ]; then
        break
    fi
done

echo "所有合并视频生成完成！"