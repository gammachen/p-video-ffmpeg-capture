## 如何有效利用FFmpeg进行图片和视频切割

python image_spliter_and_video_creator.py -i images/output_001.jpg -cw 200 -ch 200 -o output_video.mp4

python image_spliter_and_video_creator.py -i docs/image.png -cw 2410 -ch 1500 -o docs/图片合并成视频-1.mp4

这里的图片是一个比较长，比较大的图片，可以是任意是一张图片（比如你的屏幕截图、CodeSnap、任意图片），脚本将会使用ffmpeg进行切割，切割后的图片将会是尺寸一致的，这些图片最后还是被合并成一个视频，这里的视频分辨率默认是和图片一致的，你可以通过 `-o` 参数指定输出视频的路径和文件名，也可以通过 `-fps` 参数指定视频的帧率，通过 `-output_size` 参数指定输出视频的分辨率。

最后还会将切割后的图片删除掉（如果要保留切割后的图片，要将clean_up()函数的调用停止掉）

会制作两个视频，一个是快速的将内容展示，另一个会按照图片的顺序合并在一起，两个视频会最后链接在一起，使用slidleft进行转场。（很适合对技术方案或者长文本的图片进行动画式的视频化展示）

## 另一起

python ../templates/image_to_video_effects_commented_simples.py -i 'cropped_%02d_0.jpg' 

这里的 `cropped_%02d_0.jpg` 是切割后的图片文件名的模式，`%02d` 表示图片的序号，`_0.jpg` 表示切割后的图片的后缀名，你可以根据实际情况修改这个模式。

该脚本有着多种特效的组合（简单特效）

其中的cw阐述是宽度，ch是高度，你可以根据实际情况修改这个参数。

在image_spliter_and_video_creator.py中有clean_up函数，如果要使用所有切割后的图片，要将clean_up()函数的调用停止掉（为什么要使用临时生成的，因为后续视频的生成、合成都是需要规范化的图片，比如多少宽和多少高）

使用过程中发现难以设置cw和ch，导致切割后的图片尺寸不一致，导致后续视频合成失败，解决方法是在image_spliter_and_video_creator.py中添加一个参数 `-output_size`，用于指定输出视频的分辨率，默认是和图片一致的。

运行脚本的过程中会打印出当前要处理的图片的宽与高。（要将clean_up()函数的调用停止掉，否则会删除切割后的图片）

## 网格图片展示与多特效组合

/Users/shhaofu/Code/cursor-projects/p-video-ffmpeg-capture/xu_lian_lian_video/run_xu_lian_lian_grid_video.sh




