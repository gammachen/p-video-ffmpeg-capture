#!/bin/bash
# 将音频文件添加到视频中（作为背景）
ffmpeg -i xu_lian_lian.mp4 -i 曲婉婷-jar_of_love.mp3 -c:v copy -map 0:v:0 -map 1:a:0 -shortest xu_lian_lian_with_bg.mp4
