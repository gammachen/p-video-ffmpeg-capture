# ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
#        -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
#        -filter_complex \
#        "color=black:1920x1080:r=30[duration=3][base];
#         [0:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,
#               trim=duration=3,setpts=PTS-STARTPTS,
#               translate=x='if(lte(T,0.5),960*(1-T/0.5),0)'[img1];
#         [1:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,
#               trim=duration=3,setpts=PTS-STARTPTS,
#               translate=x='if(between(T,0.5,1.0),960*(1-(T-0.5)/0.5),if(gt(T,1.0),0,960))'[img2];
#         [2:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,
#               trim=duration=3,setpts=PTS-STARTPTS,
#               translate=x='if(between(T,1.0,1.5),960*(1-(T-1.0)/0.5),if(gt(T,1.5),0,960))'[img3];
#         [3:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,
#               trim=duration=3,setpts=PTS-STARTPTS,
#               translate=x='if(between(T,1.5,2.0),960*(1-(T-1.5)/0.5),if(gt(T,2.0),0,960))'[img4];
#         [base][img1]overlay=0:0[bg1];
#         [bg1][img2]overlay=960:0[bg2];
#         [bg2][img3]overlay=0:540[bg3];
#         [bg3][img4]overlay=960:540[out]" \
#        -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
#        -y "sequential_grid.mp4"

# ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
#        -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
#        -f lavfi -i color=black:1920x1080:r=30:d=3 \
#        -filter_complex \
#        "[0:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,trim=duration=3,setpts=PTS-STARTPTS,
#         fade=in:st=0:d=0.5:alpha=1[img1];
#         [1:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,trim=duration=3,setpts=PTS-STARTPTS,
#         fade=in:st=0.5:d=0.5:alpha=1[img2];
#         [2:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,trim=duration=3,setpts=PTS-STARTPTS,
#         fade=in:st=1.0:d=0.5:alpha=1[img3];
#         [3:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,trim=duration=3,setpts=PTS-STARTPTS,
#         fade=in:st=1.5:d=0.5:alpha=1[img4];
#         [4:v][img1]overlay=0:0[v1];
#         [v1][img2]overlay=960:0[v2];
#         [v2][img3]overlay=0:540[v3];
#         [v3][img4]overlay=960:540[out]" \
#        -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
#        -y "sequential_grid.mp4"

# ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
#        -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
#        -f lavfi -i color=black:1920x1080:r=30:d=3 \
#        -filter_complex \
#        "[0:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,trim=duration=3,setpts=PTS-STARTPTS[img1];
#         [1:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,trim=duration=3,setpts=PTS-STARTPTS[img2];
#         [2:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,trim=duration=3,setpts=PTS-STARTPTS[img3];
#         [3:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,trim=duration=3,setpts=PTS-STARTPTS[img4];
#         [img1][img2]xfade=transition=slideleft:duration=0.5:offset=0.5[tmp1];
#         [tmp1][img3]xfade=transition=slideleft:duration=0.5:offset=1.0[tmp2];
#         [tmp2][img4]xfade=transition=slideleft:duration=0.5:offset=1.5[out]" \
#        -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
#        -y "sequential_grid.mp4"

# ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
#        -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
#        -f lavfi -i color=black:1920x1080:r=30:d=3 \
#        -filter_complex \
#        "[0:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,trim=duration=3,setpts=PTS-STARTPTS[img1];
#         [1:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,trim=duration=3,setpts=PTS-STARTPTS[img2];
#         [2:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,trim=duration=3,setpts=PTS-STARTPTS[img3];
#         [3:v]scale=960:540:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,trim=duration=3,setpts=PTS-STARTPTS[img4];
#         [img1][img2]hstack[top];
#         [img3][img4]hstack[bottom];
#         [top][bottom]vstack[grid];
#         [4:v][grid]overlay=(W-w)/2:(H-h)/2:format=auto[out]" \
#        -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
#        -y "sequential_grid.mp4"

# 没有动画效果的脚本，将多张图片拼接成网格，静态展示
# 4张图片拼接成2x2网格
ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
       -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
       -f lavfi -i color=black:1920x1080:r=30:d=3 \
       -filter_complex \
       "[0:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img1];
        [1:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img2];
        [2:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img3];
        [3:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img4];
        [img1][img2][img3][img4]xstack=inputs=4:layout=0_0|w0_0|0_h0|w0_h0[out]" \
       -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
       -y "sequential_grid_4_static.mp4"

# 3张图片拼接成2x2网格
ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
       -loop 1 -i output_003.jpg \
       -f lavfi -i color=black:1920x1080:r=30:d=3 \
       -filter_complex \
       "[0:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img1];
        [1:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img2];
        [2:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img3];
        [img1][img2][img3]xstack=inputs=3:layout=0_0|w0_0|0_h0[out]" \
       -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
       -y "sequential_grid_3_static.mp4"

# layout定义不好没法用
# ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
#        -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
#        -loop 1 -i output_005.jpg \
#        -f lavfi -i color=black:1920x1080:r=30:d=3 \
#        -filter_complex \
#        "[0:v]scale=640:540,trim=duration=3,setpts=PTS-STARTPTS[img1];
#         [1:v]scale=640:540,trim=duration=3,setpts=PTS-STARTPTS[img2];
#         [2:v]scale=640:540,trim=duration=3,setpts=PTS-STARTPTS[img3];
#         [3:v]scale=640:540,trim=duration=3,setpts=PTS-STARTPTS[img4];
#         [4:v]scale=640:540,trim=duration=3,setpts=PTS-STARTPTS[img5];
#         [img1][img2][img3][img4][img5]xstack=inputs=5:layout=0_0|w0_0|0_h0|w0_h0|0_h2[out]" \
#        -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
#        -y "sequential_grid_5_static.mp4"

# layout的写法完全不一样，使用值，而是w0_h0，w1_h0，w0_h1，w1_h1
ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
       -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
       -loop 1 -i output_005.jpg \
       -f lavfi -i color=black:1920x1080:r=30:d=3 \
       -filter_complex \
       "[0:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img1];
        [1:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img2];
        [2:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img3];
        [3:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img4];
        [4:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img5];
        [img1][img2][img3][img4][img5]xstack=inputs=5:layout=0_0|640_0|0_360|640_360|0_720[out]" \
       -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
       -y "sequential_grid_5_static.mp4"


ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
       -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
       -loop 1 -i output_005.jpg \
       -f lavfi -i color=black:640x360:r=30:d=3 \
       -f lavfi -i color=black:1920x1080:r=30:d=3 \
       -filter_complex \
       "[0:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img1];
        [1:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img2];
        [2:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img3];
        [3:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img4];
        [4:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img5];
        [5:v]trim=duration=3,setpts=PTS-STARTPTS[blank];
        [img1][img2][img3][img4][img5][blank]xstack=grid=2x3[grid];
        [6:v][grid]overlay=(W-w)/2:(H-h)/2[out]" \
       -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
       -y "sequential_grid_5_static_2x3.mp4"

ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
       -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
       -loop 1 -i output_005.jpg \
       -f lavfi -i color=black:640x360:r=30:d=3 \
       -f lavfi -i color=black:1920x1080:r=30:d=3 \
       -filter_complex \
       "[0:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img1];
        [1:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img2];
        [2:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img3];
        [3:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img4];
        [4:v]scale=640:360,trim=duration=3,setpts=PTS-STARTPTS[img5];
        [5:v]trim=duration=3,setpts=PTS-STARTPTS[blank];
        [img1][img2][img3][img4][img5][blank]xstack=grid=3x2[grid];
        [6:v][grid]overlay=(W-w)/2:(H-h)/2[out]" \
       -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
       -y "sequential_grid_5_static_3x2.mp4"

# 
# 4张图片拼接成2x2网格，动画效果
ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
       -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
       -f lavfi -i color=black:1920x1080:r=30:d=3 \
       -filter_complex \
       "[0:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0:d=0.5:alpha=1[img1];
        [1:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0.5:d=0.5:alpha=1[img2];
        [2:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.0:d=0.5:alpha=1[img3];
        [3:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.5:d=0.5:alpha=1[img4];
        [4:v][img1]overlay=0:0:enable='between(t,0,3)'[v1];
        [v1][img2]overlay=960:0:enable='between(t,0.5,3)'[v2];
        [v2][img3]overlay=0:540:enable='between(t,1.0,3)'[v3];
        [v3][img4]overlay=960:540:enable='between(t,1.5,3)'[out]" \
       -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
       -y "sequential_grid_2x2_animation_overlay.mp4"

ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
       -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
       -f lavfi -i color=black:1920x1080:r=30:d=3 \
       -filter_complex \
       "[0:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0:d=0.5:alpha=1[img1];
        [1:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0.5:d=0.5:alpha=1[img2];
        [2:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.0:d=0.5:alpha=1[img3];
        [3:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.5:d=0.5:alpha=1[img4];
        [img1][img2]hstack[top];
        [img3][img4]hstack[bottom];
        [top][bottom]vstack[grid];
        [4:v][grid]overlay=(W-w)/2:(H-h)/2[out]" \
       -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
       -y "sequential_grid_2x2_animation_overlay_hstack.mp4"

ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
       -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
       -f lavfi -i color=black:1920x1080:r=30:d=3 \
       -filter_complex \
       "[0:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img1];
        [1:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img2];
        [2:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img3];
        [3:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS[img4];
        [4:v][img1]overlay=0:0:enable='lt(t,3)'[v1];
        [v1][img2]overlay=960:0:enable='gt(t,0.5)'[v2];
        [v2][img3]overlay=0:540:enable='gt(t,1.0)'[v3];
        [v3][img4]overlay=960:540:enable='gt(t,1.5)'[out]" \
       -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
       -y "sequential_grid_2x2_animation_overlay_2.mp4"

ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
       -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
       -f lavfi -i color=black:1920x1080:r=30:d=3 \
       -filter_complex \
       "[0:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0:d=0.5:alpha=1[img1];
        [1:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0.5:d=0.5:alpha=1[img2];
        [2:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.0:d=0.5:alpha=1[img3];
        [3:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.5:d=0.5:alpha=1[img4];
        [img1][img2][img3][img4]xstack=grid=2x2[grid];
        [4:v][grid]overlay=(W-w)/2:(H-h)/2[out]" \
       -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
       -y "sequential_grid_2x2_animation_overlay_xstack.mp4"

ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
       -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
       -loop 1 -i output_005.jpg \
       -f lavfi -i color=black:1920x1080:r=30:d=3 \
       -filter_complex \
       "[0:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0:d=0.5:alpha=1[img1];
        [1:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0.5:d=0.5:alpha=1[img2];
        [2:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.0:d=0.5:alpha=1[img3];
        [3:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.5:d=0.5:alpha=1[img4];
        [4:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=2.0:d=0.5:alpha=1[img5];
        [img1][img2][img3][img4][img5]xstack=inputs=5:layout=0_0|960_0|1920_0|0_540|960_540[grid];
        [5:v][grid]overlay=(W-w)/2:(H-h)/2[out]" \
       -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
       -y "sequential_grid_3x2_animation_overlay_xstack.mp4"

ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
       -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
       -loop 1 -i output_005.jpg \
       -f lavfi -i color=black:1920x1080:r=30:d=3 \
       -filter_complex \
       "[0:v]scale=960:216,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0:d=0.5:alpha=1[img1];
        [1:v]scale=960:216,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0.5:d=0.5:alpha=1[img2];
        [2:v]scale=960:216,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.0:d=0.5:alpha=1[img3];
        [3:v]scale=960:216,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.5:d=0.5:alpha=1[img4];
        [4:v]scale=960:216,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=2.0:d=0.5:alpha=1[img5];
        [img1][img2][img3][img4][img5]xstack=grid=2x3[grid];
        [5:v][grid]overlay=(W-w)/2:(H-h)/2[out]" \
       -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
       -y "sequential_grid_3x2_animation_overlay_xstack_3.mp4"       

ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
       -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
       -loop 1 -i output_005.jpg \
       -f lavfi -i color=black:960x216:r=30:d=3 \
       -f lavfi -i color=black:1920x1080:r=30:d=3 \
       -filter_complex \
       "[0:v]scale=960:216,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0:d=0.5:alpha=1[img1];
        [1:v]scale=960:216,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0.5:d=0.5:alpha=1[img2];
        [2:v]scale=960:216,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.0:d=0.5:alpha=1[img3];
        [3:v]scale=960:216,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.5:d=0.5:alpha=1[img4];
        [4:v]scale=960:216,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=2.0:d=0.5:alpha=1[img5];
        [5:v]trim=duration=3,setpts=PTS-STARTPTS[blank];
        [img1][img2][img3][img4][img5][blank]xstack=grid=3x2[grid];
        [6:v][grid]overlay=(W-w)/2:(H-h)/2[out]" \
       -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
       -y "sequential_grid_3x2_animation_overlay_xstack_2.mp4"   

ffmpeg -loop 1 -i /Users/shhaofu/Code/cursor-projects/p-video-ffmpeg-capture/视频制作解决方案/captured/output_001.jpg \
    -loop 1 -i /Users/shhaofu/Code/cursor-projects/p-video-ffmpeg-capture/视频制作解决方案/captured/output_002.jpg \
    -loop 1 -i /Users/shhaofu/Code/cursor-projects/p-video-ffmpeg-capture/视频制作解决方案/captured/output_003.jpg \
    -loop 1 -i /Users/shhaofu/Code/cursor-projects/p-video-ffmpeg-capture/视频制作解决方案/captured/output_004.jpg \
    -loop 1 -i /Users/shhaofu/Code/cursor-projects/p-video-ffmpeg-capture/视频制作解决方案/captured/output_005.jpg \
    -f lavfi -i color=c=black:s=640x540:r=30.0:d=5.0 -f lavfi -i color=c=black:s=1920x1080:r=30.0:d=5.0 \
    -filter_complex "[0:v]scale=640:540,trim=duration=5.0,setpts=PTS-STARTPTS,fade=in:st=0.0:d=0.5:alpha=1[img1];[1:v]scale=640:540,trim=duration=5.0,setpts=PTS-STARTPTS,fade=in:st=0.5:d=0.5:alpha=1[img2];[2:v]scale=640:540,trim=duration=5.0,setpts=PTS-STARTPTS,fade=in:st=1.0:d=0.5:alpha=1[img3];[3:v]scale=640:540,trim=duration=5.0,setpts=PTS-STARTPTS,fade=in:st=1.5:d=0.5:alpha=1[img4];[4:v]scale=640:540,trim=duration=5.0,setpts=PTS-STARTPTS,fade=in:st=2.0:d=0.5:alpha=1[img5];[5:v]trim=duration=5.0,setpts=PTS-STARTPTS[img6];[img1][img2][img3][img4][img5][img6]xstack=grid=3x2[grid];[6][grid]overlay=(W-w)/2:(H-h)/2[out]" \
    -map "[out]" -t 5.0 -r 30.0 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
    -y "视频制作解决方案/capture/sequential_grid_3x2_animation_overlay_xstack_2.mp4"

# ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
#        -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
#        -loop 1 -i output_005.jpg \
#        -f lavfi -i color=black:1920x1080:r=30:d=3 \
#        -filter_complex \
#        "[0:v]scale=960:216,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0:d=0.5:alpha=1[img1];
#         [1:v]scale=960:216,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0.5:d=0.5:alpha=1[img2];
#         [2:v]scale=960:216,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.0:d=0.5:alpha=1[img3];
#         [3:v]scale=960:216,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.5:d=0.5:alpha=1[img4];
#         [4:v]scale=960:216,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=2.0:d=0.5:alpha=1[img5];
#         [img1][img2][img3]hstack=3[top];
#         [img4][img5]hstack=2[bottom];
#         [top][bottom]vstack[grid];
#         [5:v][grid]overlay=(W-w)/2:(H-h)/2[out]" \
#        -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
#        -y "sequential_grid_3x2_animation_overlay_xstack.mp4"

# ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
#        -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
#        -i output_005.jpg \
#        -f lavfi -i color=black:1920x1080:r=30:d=3 \
#        -filter_complex \
#        "[0:v]scale=960:360,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0:d=0.5:alpha=1[img1];
#         [1:v]scale=960:360,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=0.5:d=0.5:alpha=1[img2];
#         [2:v]scale=960:360,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.0:d=0.5:alpha=1[img3];
#         [3:v]scale=960:360,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=1.5:d=0.5:alpha=1[img4];
#         [4:v]scale=960:360,trim=duration=3,setpts=PTS-STARTPTS,fade=in:st=2.0:d=0.5:alpha=1[img5];
#         [img1][img2][img3][img4][img5]xstack=grid=2x3[grid];
#         [4:v][grid]overlay=(W-w)/2:(H-h)/2[out]" \
#        -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
#        -y "sequential_grid_3x2_animation_overlay_xstack.mp4"
# [swscaler @ 0x110508000] deprecated pixel format used, make sure you did set range correctly
# [Parsed_xstack_20 @ 0x153714120] Input 5 height 1080 does not match current row's height 360.
# [Parsed_xstack_20 @ 0x153714120] Failed to configure output pad on Parsed_xstack_20
# [fc#0 @ 0x153615780] Error reinitializing filters!
# [fc#0 @ 0x153615780] Task finished with error code: -22 (Invalid argument)
# [fc#0 @ 0x153615780] Terminating thread with return code -22 (Invalid argument)
# [vost#0:0/libx264 @ 0x153621800] Could not open encoder before EOF
# [vost#0:0/libx264 @ 0x153621800] Task finished with error code: -22 (Invalid argument)
# [vost#0:0/libx264 @ 0x153621800] Terminating thread with return code -22 (Invalid argument)
# [out#0/mp4 @ 0x15361fc70] Nothing was written into output file, because at least one of its streams received no packets.
# frame=    0 fps=0.0 q=0.0 Lsize=       0KiB time=N/A bitrate=N/A speed=N/A    
# Conversion failed!


# ffmpeg -loop 1 -i output_001.jpg -loop 1 -i output_002.jpg \
#        -loop 1 -i output_003.jpg -loop 1 -i output_004.jpg \
#        -f lavfi -i color=black:1920x1080:r=30:d=3 \
#        -filter_complex \
#        "[0:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,zoompan=z='if(lte(on,15),1.5,1/1.5)':d=15[img1];
#         [1:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,zoompan=z='if(lte(on,30),1.5,1/1.5)':d=15:s=960x540[img2];
#         [2:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,zoompan=z='if(lte(on,45),1.5,1/1.5)':d=15:s=960x540[img3];
#         [3:v]scale=960:540,trim=duration=3,setpts=PTS-STARTPTS,zoompan=z='if(lte(on,60),1.5,1/1.5)':d=15:s=960x540[img4];
#         [img1][img2][img3][img4]xstack=grid=2x2[out]" \
#        -map "[out]" -t 3 -r 30 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
#        -y "sequential_grid_4.mp4"