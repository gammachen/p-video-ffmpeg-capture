# #!/bin/bash
# ffmpeg -loop 1 -i "output_001.jpg" \
#            -vf "scale=960:540:force_original_aspect_ratio=decrease:flags=lanczos,pad=960:540:(ow-iw)/2:(oh-ih)/2:black,translate=x='if(between(T,0,0.5),960*(1-(T-0*0.2)/0.5),0)':y=0" \
#            -t 2 -r 30 -c:v libx264 -preset ultrafast -pix_fmt yuv420p \
#            -y "temp_slide1.mp4"
# # 创建4个单独的滑动动画，然后合并
# for i in {1..4}; do
#     ffmpeg -loop 1 -i "output_00${i}.jpg" \
#            -vf "scale=960:540:force_original_aspect_ratio=decrease:flags=lanczos,
#                 pad=960:540:(ow-iw)/2:(oh-ih)/2:black,
#                 translate=x='if(between(T,0,0.5),960*(1-(T-($i-1)*0.2)/0.5),0)':y=0" \
#            -t 2 -r 30 -c:v libx264 -preset ultrafast -pix_fmt yuv420p \
#            -y "temp_slide${i}.mp4"
# done

# 合并为2x2网格
# ffmpeg -i temp_slide1.mp4 -i temp_slide2.mp4 -i temp_slide3.mp4 -i temp_slide4.mp4 \
#        -filter_complex \
#        "[0:v]setpts=PTS-STARTPTS[img1];
#         [1:v]setpts=PTS-STARTPTS[img2];
#         [2:v]setpts=PTS-STARTPTS[img3];
#         [3:v]setpts=PTS-STARTPTS[img4];
#         [img1][img2]hstack=inputs=2[top];
#         [img3][img4]hstack=inputs=2[bottom];
#         [top][bottom]vstack=inputs=2[out]" \
#        -map "[out]" -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p -r 30 \
#        -y "grid_slide_output.mp4"