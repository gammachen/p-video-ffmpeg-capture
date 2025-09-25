这个问题是因为您对 `-framerate` 参数的理解有误。让我详细解释：

## framerate参数的正确理解

### 当前情况分析：
```bash
ffmpeg -y -framerate 10 -i resized_artistic_portrait_1_%02d.jpg pic_to_video.mp4
```
- **`-framerate 10`**：表示**每秒播放10张图片**
- **23张图片** ÷ **10张/秒** = **2.3秒视频**

### 修正后的情况：
```bash
ffmpeg -y -framerate 0.5 -i resized_artistic_portrait_1_%02d.jpg pic_to_video.mp4
```
- **`-framerate 0.5`**：表示**每2秒播放1张图片**（因为 1 ÷ 0.5 = 2秒/张）
- **23张图片** × **2秒/张** = **46秒视频**

## framerate参数的计算公式

**视频时长 = 图片数量 ÷ framerate值**

或者：

**每张图片显示时间 = 1 ÷ framerate值**

## 常用framerate值对应的效果

| framerate值 | 每张图片显示时间 | 23张图片总时长 |
|------------|-----------------|---------------|
| `10` | 0.1秒 | 2.3秒 |
| `5` | 0.2秒 | 4.6秒 |
| `2` | 0.5秒 | 11.5秒 |
| `1` | 1秒 | 23秒 |
| `0.5` | 2秒 | 46秒 |
| `0.33` | 3秒 | 69秒 |
| `0.25` | 4秒 | 92秒 |
| `0.1` | 10秒 | 230秒 |

## 推荐的使用方式

### 方法一：使用framerate控制（简单）
```bash
# 每张图片显示3秒
ffmpeg -y -framerate 0.33 -i resized_artistic_portrait_1_%02d.jpg pic_to_video.mp4

# 每张图片显示5秒
ffmpeg -y -framerate 0.2 -i resized_artistic_portrait_1_%02d.jpg pic_to_video.mp4
```

### 方法二：使用-r控制输出帧率（更灵活）
```bash
# 输入图片按1秒1张的速度读取，输出为25fps
ffmpeg -y -r 1 -i resized_artistic_portrait_1_%02d.jpg -r 25 pic_to_video.mp4

# 每张图片显示3秒（输入帧率=1/3）
ffmpeg -y -r 1/3 -i resized_artistic_portrait_1_%02d.jpg -r 25 pic_to_video.mp4
```

### 方法三：使用filter控制显示时间
```bash
# 使用fps滤镜控制每张图片的显示帧数
ffmpeg -y -i resized_artistic_portrait_1_%02d.jpg -vf "fps=25,loop=75:1:0" pic_to_video.mp4
# loop=75:1:0 表示每张图片循环75帧（75÷25=3秒）
```

## 验证视频时长

生成视频后可以检查时长：
```bash
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 pic_to_video.mp4
```

## 推荐的实用命令

```bash
# 每张图片显示3秒（适合照片展示）
ffmpeg -y -framerate 0.33 -i resized_artistic_portrait_1_%02d.jpg pic_to_video.mp4

# 或者使用-r参数（更明确）
ffmpeg -y -r 1/3 -i resized_artistic_portrait_1_%02d.jpg -r 25 pic_to_video.mp4
```

## 总结

- **framerate值越小** → 每张图片显示时间越长 → 总视频时长越长
- **framerate值越大** → 每张图片显示时间越短 → 总视频时长越短

对于照片幻灯片展示，推荐使用 `0.2`-`0.5` 的framerate值（每张显示2-5秒）。