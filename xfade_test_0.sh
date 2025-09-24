#!/bin/bash
# deprecated(指令有问题)
# [fc#0 @ 0x12c72e2f0] Cannot find a matching stream for unlabeled input pad xfade
# Error binding filtergraph inputs/outputs: Invalid argument
ffmpeg -y \
    -framerate 25 \
    -i output_%03d.jpg \
    -filter_complex "[0:v]xfade=transition=dissolve:duration=1:offset=5[v]" \
    -map "[v]" \
    -c:v libx264 \
    -pix_fmt yuv420p \
    video_with_transition.mp4