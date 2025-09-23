## 图片转视频

```shell
## 将一系列图片转换为视频（按数字顺序）
ffmpeg -framerate 24 -i output_%03d.jpg pic_to_video.mp4

## 指定图片格式和帧率
ffmpeg -framerate 30 -pattern_type glob -i "*.jpg" output_pic_to_video.mp4

## 创建带有过渡效果的幻灯片
ffmpeg -framerate 1/3 -i output_%03d.jpg -vf "fps=25,format=yuv420p" -c:v libx264 -crf 23 slideshow.mp4

## 添加缩放平移效果（Ken Burns效应）
ffmpeg -i output_%03d.jpg -vf "zoompan=z='min(zoom+0.0015,1.5)':d=125:x='if(gte(zoom,1.5),x,x+1)':y='y+1':s=1280x720" -c:v libx264 ken_burns_show.mp4

## 2x2网格图片
ffmpeg -i output_001.jpg -i output_002.jpg -i output_003.jpg -i output_004.jpg -filter_complex "[0:v][1:v]hstack=inputs=2[top];[2:v][3:v]hstack=inputs=2[bottom];[top][bottom]vstack=inputs=2[v]"  -map "[v]" output_4_to_2x2.jpg

## 3x3网格图片
ffmpeg -i output_001.jpg -i output_002.jpg -i output_003.jpg -i output_004.jpg -i output_005.jpg -i output_006.jpg -i output_007.jpg -i output_008.jpg -i output_007.jpg -i output_008.jpg -i output_009.jpg   -filter_complex "[0:v][1:v][2:v]hstack=inputs=3[top];[3:v][4:v][5:v]hstack=inputs=3[middle];[6:v][7:v][8:v]hstack=inputs=3[bottom];[top][middle][bottom]vstack=inputs=3[v]"  -map "[v]" output_3x3.jpg
```

```shell
# 在视频右上角添加PNG水印 
ffmpeg -i input.mp4 -i watermark.png -filter_complex "overlay=W-w-10:10" output.mp4 

# 添加水印并设置透明度 
ffmpeg -i input.mp4 -i watermark.png -filter_complex "[1]format=rgba,colorchannelmixer=aa=0.5[transparency];[0][transparency]overlay=10:10" output.mp4

# 添加文字水印 
ffmpeg -i input.mp4 -vf "drawtext=text='Sample Watermark':x=10:y=H-th-10:fontsize=24:fontcolor=white:shadowcolor=black:shadowx=2:shadowy=2" output.mp4 

# 动态移动的文字水印 
ffmpeg -i input.mp4 -vf "drawtext=text='Moving Text':x=mod(2*n\,w+tw)-tw:y=100:fontsize=30:fontcolor=white" output.mp4

# 添加时间戳水印 
ffmpeg -i input.mp4 -vf "drawtext=text='%{localtime}':x=10:y=10:fontsize=20:fontcolor=white" output.mp4 

# 添加帧计数和时间码 
ffmpeg -i input.mp4 -vf "drawtext=text='Frame %{n} • Time %{pts}':x=10:y=H-th-10:fontsize=20:fontcolor=white" output.mp4

# 在视频的不同部分显示不同的动态文字
ffmpeg -i input.mp4 -vf " drawtext=text='Intro':x=mod(2*n\,w+tw)-tw:y=50:fontsize=24:fontcolor=red:enable='between(t,0,5)', drawtext=text='Main Content':x=w-mod(3*n\,w+tw):y=100:fontsize=30:fontcolor=white:enable='between(t,5,15)', drawtext=text='Section 2':x=mod(5*n\,w+tw)-tw:y=150:fontsize=28:fontcolor=yellow:enable='between(t,15,25)', drawtext=text='Final Part':x=w-mod(2*n\,w+tw):y=200:fontsize=32:fontcolor=cyan:enable='between(t,25,35)', drawtext=text='The End':x=(w-tw)/2:y=(h-th)/2:fontsize=40:fontcolor=green:enable='between(t,35,40)' " output_difftime_difftext.mp4
```