#!/bin/bash

# 简单修复版：5张图片网格布局视频生成脚本
# 使用更简单、更可靠的方法

# 方案：将5张图片排列成2行布局（3+2），使用hstack和vstack组合
ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
       -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
       -loop 1 -i output_005.jpg \
       -f lavfi -i color=black:1920x1080:r=30:d=3 \
       -filter_complex "\
       [0:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img1]; \
       [1:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img2]; \
       [2:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img3]; \
       [3:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img4]; \
       [4:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img5]; \
       [img1][img2][img3]hstack=inputs=3[top_row]; \
       [img4][img5]hstack=inputs=2[bottom_row_half]; \
       [bottom_row_half]pad=width=1920:height=360:x=(ow-iw)/2:color=black[bottom_row]; \
       [top_row][bottom_row]vstack=inputs=2[full_grid]; \
       [full_grid][5:v]overlay=(W-w)/2:(H-h)/2[out]" \
       -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
       -y "fixed_5_images_simple.mp4"

# 验证生成的文件
ls -la fixed_5_images_simple.mp4

# 显示文件大小和创建时间
if [ -f fixed_5_images_simple.mp4 ]; then
    echo "文件大小: $(du -h fixed_5_images_simple.mp4 | cut -f1)"
    echo "创建时间: $(stat -f %Sm fixed_5_images_simple.mp4)"
else
    echo "文件未成功创建，请检查错误信息"
fi

# 提供原命令的修复版本供参考
cat > fixed_original_command.txt << 'EOF'
# 原命令的修复版本（使用overlay滤镜逐个叠加5张图片）
ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
       -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
       -loop 1 -i output_005.jpg \
       -f lavfi -i color=black:1920x1080:r=30:d=3 \
       -filter_complex \
       "[0:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img1];\
        [1:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img2];\
        [2:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img3];\
        [3:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img4];\
        [4:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img5];\
        [5:v][img1]overlay=0:0[base1];\
        [base1][img2]overlay=960:0[base2];\
        [base2][img3]overlay=0:540[base3];\
        [base3][img4]overlay=960:540[base4];\
        [base4][img5]overlay=480:270[out]" \
       -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
       -y "fixed_original_style.mp4"
EOF

echo "修复后的原命令样式已保存到 fixed_original_command.txt"

# 错误分析
cat > error_analysis.txt << 'EOF'
## FFmpeg命令失败原因分析

1. **原命令问题**：
   - 原命令中 `xstack=inputs=5:layout=0_0|w0_0|0_h0|w0_h0[out]` 有配置错误
   - 定义了5个输入(inputs=5)，但只提供了4个布局位置(layout只指定了4个)
   - 这导致FFmpeg无法正确配置xstack滤镜，错误信息：`Failed to configure output pad on Parsed_xstack_15`

2. **修复策略**：
   - 使用hstack和vstack组合创建更灵活的布局
   - 或者使用overlay滤镜逐个叠加图片
   - 确保输入数量和布局位置完全匹配

3. **推荐方案**：
   - 对于5张图片，建议使用3+2的布局（上3下2）
   - 或者使用overlay滤镜创建更自定义的布局
EOF

echo "错误分析已保存到 error_analysis.txt"