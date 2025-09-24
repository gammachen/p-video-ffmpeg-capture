在FFmpeg中使用fade滤镜实现淡入淡出效果有多种方式。以下是详细的用法：

## 1. 基本淡入淡出滤镜

### 淡入（Fade In）
```bash
# 视频开头淡入（持续2秒）
ffmpeg -i input.mp4 -vf "fade=type=in:duration=2" output.mp4

# 音频淡入
ffmpeg -i input.mp4 -af "afade=type=in:duration=2" output.mp4
```

### 淡出（Fade Out）
```bash
# 视频结尾淡出（持续3秒）
ffmpeg -i input.mp4 -vf "fade=type=out:duration=3:start_time=10" output.mp4

# 自动检测视频长度淡出
ffmpeg -i input.mp4 -vf "fade=type=out:duration=3:start_time=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 input.mp4 | awk '{print $1-3}')" output.mp4
```

## 2. 同时淡入淡出
```bash
# 开头2秒淡入，结尾3秒淡出
ffmpeg -i input.mp4 -vf "fade=type=in:duration=2,fade=type=out:duration=3:start_time=15" output.mp4
```

## 3. 精确时间控制
```bash
# 从第5秒开始淡入，持续2秒
ffmpeg -i input.mp4 -vf "fade=type=in:start_time=5:duration=2" output.mp4

# 在视频结束前3秒开始淡出
ffmpeg -i input.mp4 -vf "fade=type=out:start_time=27:duration=3" output.mp4
```

## 4. 多段淡入淡出
```bash
# 复杂的时间线：淡入→正常播放→淡出→淡入→淡出
ffmpeg -i input.mp4 -filter_complex \
"[0:v]fade=type=in:duration=2:start_time=0,
 fade=type=out:duration=2:start_time=8,
 fade=type=in:duration=2:start_time=12,
 fade=type=out:duration=3:start_time=20[v]" \
-map "[v]" -map 0:a output.mp4
```

## 5. 结合音频淡入淡出
```bash
# 视频和音频同时淡入淡出
ffmpeg -i input.mp4 \
-vf "fade=type=in:duration=2,fade=type=out:duration=3:start_time=25" \
-af "afade=type=in:duration=2,afade=type=out:duration=3:start_time=25" \
output.mp4
```

## 6. 淡入淡出参数详解

### fade视频滤镜参数：
- **`type=in/out`** - 淡入或淡出
- **`duration=N`** - 过渡持续时间（秒）
- **`start_time=N`** - 开始时间（秒）
- **`color=color`** - 淡入淡出的颜色（默认黑色）
- **`alpha=1`** - 启用Alpha通道淡入淡出（用于透明视频）

### afade音频滤镜参数：
- **`type=in/out`** - 淡入或淡出
- **`duration=N`** - 过渡持续时间（秒）
- **`start_time=N`** - 开始时间（秒）
- **`curve=tri/qua/cub/hsin/etc`** - 过渡曲线类型

## 7. 实用示例

### 创建标准的10秒视频带淡入淡出：
```bash
# 开头1秒淡入，结尾1秒淡出
ffmpeg -i input.mp4 -t 10 -vf "fade=type=in:duration=1,fade=type=out:duration=1:start_time=9" output.mp4
```

### 批量处理多个文件：
```bash
for file in *.mp4; do
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")
    fade_out_start=$(echo "$duration - 2" | bc)
    ffmpeg -i "$file" -vf "fade=type=in:duration=1,fade=type=out:duration=2:start_time=$fade_out_start" "faded_${file}"
done
```

## 8. 高级用法：自定义颜色和曲线
```bash
# 白色淡入淡出
ffmpeg -i input.mp4 -vf "fade=type=in:duration=2:color=white,fade=type=out:duration=2:color=white:start_time=28" output.mp4

# 使用不同的过渡曲线
ffmpeg -i input.mp4 -af "afade=type=in:duration=2:curve=qua" output.mp4
```

这些滤镜可以灵活组合使用，根据具体需求调整时间和效果参数。