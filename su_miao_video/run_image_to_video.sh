#!/bin/bash
#
# cd到当前目录
cd "$(dirname "$0")"
python ../templates/image_to_video_effects_commented.py -i 'output_%03d.jpg'