#!/bin/bash

# Test xfade transitions with image sequence
# This script demonstrates how to properly apply crossfade transitions
# between video segments created from an image sequence

echo "Testing xfade transitions with proper frame rate configuration..."

# Set variables
INPUT_PATTERN="output_*.jpg"
# INPUT_PATTERN="output_%03d.jpg"
OUTPUT_FILE="xfade_test.mp4"
FPS=25
DURATION=5  # Duration of each segment in seconds
TRANSITION_DURATION=1  # Transition duration in seconds

# First, check if input files exist
if [ -z "$(ls -1 ${INPUT_PATTERN} 2>/dev/null)" ]; then
    echo "Error: No input files found matching pattern ${INPUT_PATTERN}"
    echo "Creating test images..."
    # Create test images if none exist
    for i in {1..20}; do
        printf -v num "%03d" $i
        convert -size 1280x720 "rgb($((i*10%255)),$((i*20%255)),$((i*30%255)))" -gravity center -pointsize 72 -fill white label:"Image $num" "output_${num}.jpg"
    done
fi

# Clear previous output if exists
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
fi

# Calculate number of frames
SEGMENT_FRAMES=$((FPS * DURATION))
TRANSITION_FRAMES=$((FPS * TRANSITION_DURATION))

# Method 1: Using split and xfade with proper timestamp handling
# This approach duplicates the input, applies different filters to each stream,
# then combines them with a crossfade transition
echo "Method 1: Basic split and xfade..."
ffmpeg -y \
  -framerate $FPS \
  -i "$INPUT_PATTERN" \
  -filter_complex "[0:v]split[a][b]; \
                   [a]trim=0:${SEGMENT_FRAMES},setpts=PTS-STARTPTS[v0]; \
                   [b]trim=${SEGMENT_FRAMES}:${SEGMENT_FRAMES}*2,setpts=PTS-STARTPTS[v1]; \
                   [v0][v1]xfade=transition=fade:duration=${TRANSITION_FRAMES}:offset=${SEGMENT_FRAMES}-${TRANSITION_FRAMES}:eval=frame[v]" \
  -map "[v]" \
  -c:v libx264 \
  -crf 18 \
  -pix_fmt yuv420p \
  -t $((DURATION * 2)) \
  "xfade_method1.mp4"

# Method 2: Using multiple crossfade transitions with different effects
# This approach creates three segments with different filters and applies
# different transition effects between them
echo "Method 2: Multiple segments with different transitions..."
ffmpeg -y \
  -framerate $FPS \
  -i "$INPUT_PATTERN" \
  -filter_complex "[0:v]split[a][b][c]; \
                   [a]trim=0:${SEGMENT_FRAMES},setpts=PTS-STARTPTS[v0]; \
                   [b]trim=${SEGMENT_FRAMES}:${SEGMENT_FRAMES}*2,setpts=PTS-STARTPTS,scale=1280:720,hflip[v1]; \
                   [c]trim=${SEGMENT_FRAMES}*2:${SEGMENT_FRAMES}*3,setpts=PTS-STARTPTS,eq=brightness=0.1:contrast=1.2[v2]; \
                   [v0][v1]xfade=transition=slideleft:duration=${TRANSITION_FRAMES}:offset=${SEGMENT_FRAMES}-${TRANSITION_FRAMES}:eval=frame[tmp1]; \
                   [tmp1][v2]xfade=transition=circleopen:duration=${TRANSITION_FRAMES}:offset=${SEGMENT_FRAMES}*2-${TRANSITION_FRAMES}:eval=frame[v]" \
  -map "[v]" \
  -c:v libx264 \
  -crf 18 \
  -pix_fmt yuv420p \
  -t $((DURATION * 3)) \
  "xfade_method2.mp4"

# Method 3: Using fade in/out with xfade
# This approach combines fade in/out effects with xfade transition
echo "Method 3: Combining fade effects with xfade..."
ffmpeg -y \
  -framerate $FPS \
  -i "$INPUT_PATTERN" \
  -filter_complex "[0:v]split[a][b]; \
                   [a]trim=0:${SEGMENT_FRAMES},setpts=PTS-STARTPTS,fade=in:0:${FPS},fade=out:${SEGMENT_FRAMES}-${FPS}:${FPS}[v0]; \
                   [b]trim=${SEGMENT_FRAMES}:${SEGMENT_FRAMES}*2,setpts=PTS-STARTPTS,fade=in:0:${FPS},fade=out:${SEGMENT_FRAMES}-${FPS}:${FPS}[v1]; \
                   [v0][v1]xfade=transition=distance:duration=${TRANSITION_FRAMES}:offset=${SEGMENT_FRAMES}-${TRANSITION_FRAMES}:eval=frame[v]" \
  -map "[v]" \
  -c:v libx264 \
  -crf 18 \
  -pix_fmt yuv420p \
  -t $((DURATION * 2)) \
  "xfade_method3.mp4"

# Final test with the original input pattern but with proper configuration
echo "Final test with original configuration but fixed parameters..."
ffmpeg -y \
  -framerate $FPS \
  -i "$INPUT_PATTERN" \
  -filter_complex "[0:v]split[a][b]; \
                   [a]trim=0:12,setpts=PTS-STARTPTS,fps=$FPS[v0]; \
                   [b]trim=12:24,setpts=PTS-STARTPTS,fps=$FPS[v1]; \
                   [v0][v1]xfade=transition=fade:duration=1*$FPS:offset=11*$FPS:eval=frame[v]" \
  -map "[v]" \
  -c:v libx264 \
  -crf 18 \
  -pix_fmt yuv420p \
  -t 24 \
  "$OUTPUT_FILE"

# Check if outputs were created
success_count=0
for file in "$OUTPUT_FILE" xfade_method1.mp4 xfade_method2.mp4 xfade_method3.mp4; do
    if [ -f "$file" ] && [ -s "$file" ]; then
        echo "Successfully created: $file"
        success_count=$((success_count + 1))
    else
        echo "Failed to create: $file"
    fi
done

echo "xfade test completed! Successfully created $success_count out of 4 test files."

# Display troubleshooting tips
cat << EOF

Troubleshooting Tips:
---------------------
1. If you get 'current rate of 1/0 is invalid' error:
   - Ensure you're using -framerate option before -i for image sequences
   - Add fps filter after trim and setpts operations
   - Use eval=frame parameter in xfade

2. If you get 'deprecated pixel format' warnings:
   - Always specify -pix_fmt yuv420p for compatibility

3. For best results with xfade:
   - Both input streams must have the same resolution
   - Both input streams must have constant frame rate
   - Use setpts=PTS-STARTPTS after trim operations
   - Specify duration and offset in frames when using eval=frame

EOF
