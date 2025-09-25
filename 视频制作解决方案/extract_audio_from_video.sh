#!/bin/bash
# 从视频中抽取出音频
ffmpeg -i xu_lian_lian.mp4 -q:a 0 -map a xu_lian_lian.mp3