#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
图片转视频特效工具
根据技术文档实现所有ffmpeg图片转视频特效，生成不同的mp4结果，并最终合并为一个视频
python image_to_video_effects_commented.py -i 'output_%03d.jpg'
"""
import os
import subprocess
import argparse
import sys
import tempfile
from pathlib import Path

class ImageToVideoEffects:
    """图片转视频特效类，用于将图片序列转换为带有各种特效的视频"""
    
    def __init__(self, input_pattern, output_dir=None, fps=25, duration=6, output_size="1280x720"):
        """初始化图片转视频特效工具
        
        Args:
            input_pattern: 输入图片的模式，如 'input%d.jpg' 或 'output_%03d.jpg' 或 'images/*.jpg'
            output_dir: 输出目录路径
            fps: 帧率，默认为25（输出帧率）
            duration: 每个效果视频的时长（秒）
            output_size: 输出分辨率，例如 '1280x720'
        """
        # 检查ffmpeg是否安装
        if not self._check_ffmpeg_installed():
            raise RuntimeError("未找到ffmpeg，请先安装ffmpeg")
            
        # 设置输入模式和帧率
        self.input_pattern = input_pattern
        self.output_fps = int(fps)
        self.fps = self.output_fps  # 兼容旧字段名
        self.duration = float(duration)
        self.output_size = str(output_size)
        self.total_frames = max(1, int(self.output_fps * self.duration))
        # 解析输出尺寸
        try:
            self.w, self.h = map(int, self.output_size.lower().split('x'))
        except Exception:
            raise ValueError(f"非法的输出分辨率: {self.output_size}，应为例如 1280x720")
        
        # 输入文件统计
        self._detect_input_set()
        
        # 设置输出目录
        if output_dir:
            self.output_dir = Path(output_dir)
        else:
            self.output_dir = Path.cwd() / "effects_output"
        
        # 创建输出目录
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # 预先计算zoompan归一化分母，避免除0
        self._zp_den = max(1, self.total_frames - 1)
        
        # 常用片段：先把图放大到至少覆盖目标画布（increase），再进行zoompan到目标尺寸
        base_upscale = f"scale={self.output_size}:force_original_aspect_ratio=increase"
        
        # 特效配置列表（使用更稳健的滤镜组合，统一时长与分辨率，避免黑屏/一闪而过）
        self.effects = [
            {
                "name": "fade_in_out",
                "description": "淡入淡出效果",
                "filter": self._vf_with_duration([
                    f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                    self._pad_center(),
                    f"fps={self.output_fps}",
                    f"fade=in:0:{max(1, int(self.output_fps*0.6))}",
                    f"fade=out:{max(0, self.total_frames - int(self.output_fps*0.6))}:{max(1, int(self.output_fps*0.6))}"
                ])
            },
            {
                "name": "scroll_horizontal",
                "description": "水平平移效果",
                "filter": self._vf_with_duration([
                    base_upscale,
                    # 从左到右平移
                    f"zoompan=z=1:x=(iw-{self.w})*on/{self._zp_den}:y=(ih-{self.h})/2:d=1:s={self.output_size}:fps={self.output_fps}"
                ])
            },
            {
                "name": "slide_horizontal",
                "description": "水平滑动效果",
                "filter": self._vf_with_duration([
                    base_upscale,
                    # 与scroll类似，保持一致的实现
                    f"zoompan=z=1:x=(iw-{self.w})*on/{self._zp_den}:y=(ih-{self.h})/2:d=1:s={self.output_size}:fps={self.output_fps}"
                ])
            },
            {
                "name": "zoompan_slow",
                "description": "缓慢缩放效果 (Ken Burns)",
                "filter": self._vf_with_duration([
                    base_upscale,
                    # 以中心为基准进行缓慢放大
                    f"zoompan=z=1.0+0.15*on/{self._zp_den}:x='iw/2-(ow*zoom/2)':y='ih/2-(oh*zoom/2)':d=1:s={self.output_size}:fps={self.output_fps}"
                ])
            },
            {
                "name": "black_white",
                "description": "黑白效果",
                "filter": self._vf_with_duration([
                    f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                    self._pad_center(),
                    f"fps={self.output_fps}",
                    "hue=s=0"
                ])
            },
            {
                "name": "vintage",
                "description": "复古（棕褐色/曲线）效果",
                "filter": self._vf_with_duration([
                    f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                    self._pad_center(),
                    f"fps={self.output_fps}",
                    # 使用颜色通道混合模拟复古
                    "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131"
                ])
            },
            {
                "name": "gaussian_blur",
                "description": "高斯模糊效果",
                "filter": self._vf_with_duration([
                    f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                    self._pad_center(),
                    f"fps={self.output_fps}",
                    "gblur=sigma=5"
                ])
            },
            {
                "name": "text_watermark",
                "description": "添加文字水印",
                "filter": self._vf_with_duration([
                    f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                    self._pad_center(),
                    f"fps={self.output_fps}",
                    # 如果系统找不到默认字体，建议在命令行传入 fontfile
                    "drawtext=text='My Slideshow':x=10:y=10:fontsize=36:fontcolor=white:box=1:boxcolor=black@0.35:boxborderw=10"
                ])
            },
            {
                "name": "dynamic_text",
                "description": "动态文字效果",
                "filter": self._vf_with_duration([
                    f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                    self._pad_center(),
                    f"fps={self.output_fps}",
                    "drawtext=text='Frame %{n}':x=w-tw-20:y=20:fontsize=28:fontcolor=red:box=1:boxcolor=black@0.35:boxborderw=10"
                ])
            },
            {
                "name": "slow_motion",
                "description": "慢动作效果",
                # 使用setpts拉长时基，并用trim统一时长
                "filter": self._vf_with_duration([
                    f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                    self._pad_center(),
                    f"fps={self.output_fps}",
                    "setpts=2.0*PTS"
                ], add_trim=True)
            },
            {
                "name": "fast_forward",
                "description": "快进效果",
                "filter": self._vf_with_duration([
                    f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                    self._pad_center(),
                    f"fps={self.output_fps}",
                    "setpts=0.5*PTS"
                ], add_trim=True)
            },
            {
                "name": "pixelize",
                "description": "马赛克像素化效果",
                # 使用两次scale+neighbor实现像素化（pixelize滤镜在很多构建中不存在）
                "filter": self._vf_with_duration([
                    f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                    self._pad_center(),
                    f"fps={self.output_fps}",
                    "scale=iw/20:ih/20:flags=neighbor",
                    "scale=iw*20:ih*20:flags=neighbor"
                ])
            },
            {
                "name": "mirror",
                "description": "镜像效果",
                "filter": self._vf_with_duration([
                    f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                    self._pad_center(),
                    f"fps={self.output_fps}",
                    "split[a][b];[b]hflip[c];[a][c]hstack"
                ])
            },
            {
                "name": "comprehensive",
                "description": "高级综合特效 (缩放+淡入淡出+文字)",
                "filter": self._vf_with_duration([
                    base_upscale,
                    # 中心缓慢放大
                    f"zoompan=z=1.0+0.1*on/{self._zp_den}:x='iw/2-(ow*zoom/2)':y='ih/2-(oh*zoom/2)':d=1:s={self.output_size}:fps={self.output_fps}",
                    f"fade=in:0:{max(1, int(self.output_fps*0.5))}",
                    f"fade=out:{max(0, self.total_frames - int(self.output_fps*0.5))}:{max(1, int(self.output_fps*0.5))}",
                    "drawtext=text='My Photo':x=(w-text_w)/2:y=h-text_h-40:fontsize=34:fontcolor=white:box=1:boxcolor=black@0.5:boxborderw=20"
                ])
            }
        ]
        
        # 存储成功生成的视频文件列表
        self.generated_videos = []
    
    def _check_ffmpeg_installed(self):
        """检查系统是否安装了ffmpeg"""
        try:
            subprocess.run(["ffmpeg", "-version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
            return True
        except (subprocess.SubprocessError, FileNotFoundError):
            return False
    
    def _detect_input_set(self):
        """检测输入是序列还是单图，并统计数量，计算输入帧率。"""
        import glob, re
        self.is_sequence = False
        pattern = self.input_pattern
        # 统计匹配文件
        glob_pattern = pattern
        if "%" in pattern:
            glob_pattern = re.sub(r"%0?\d*d", "*", pattern)
        matching_files = sorted(glob.glob(glob_pattern))
        self.num_input_frames = len(matching_files) if matching_files else 0
        # 判断是否为序列
        if any(ch in pattern for ch in ["*", "?", "["]) or "%" in pattern:
            self.is_sequence = True
        # 计算输入帧率：让所有输入帧均匀分布在目标时长内
        if self.is_sequence and self.num_input_frames > 0 and self.duration > 0:
            self.input_fps = max(0.5, self.num_input_frames / self.duration)
        else:
            # 单张图或未知，退化为输出帧率
            self.input_fps = float(self.output_fps)
    
    def _check_input_files(self):
        """检查是否有符合输入模式的图片文件"""
        # 尝试查找匹配的文件
        import glob
        pattern = self.input_pattern
        # 将 %d/%0Nd 转换为通配以用于glob
        if "%" in pattern:
            import re
            pattern = re.sub(r"%0?\d*d", "*", pattern)
        matching_files = glob.glob(pattern)
        return len(matching_files) > 0
    
    def _build_input_args(self):
        """根据输入模式构建稳健的输入参数，支持glob、%d、单张图片。"""
        args = []
        # 允许覆盖输出
        args.extend(["-y"])
        # 输入帧率控制（序列用自适应帧率，单图用loop）
        pattern = self.input_pattern
        if any(ch in pattern for ch in ["*", "?", "["]):
            args.extend(["-framerate", str(self.input_fps), "-pattern_type", "glob", "-i", pattern])
        elif "%" in pattern:
            args.extend(["-framerate", str(self.input_fps), "-i", pattern])
        else:
            # 单张图片：开启loop并限定时长
            args.extend(["-loop", "1", "-t", str(self.duration), "-i", pattern])
        return args
    
    def _build_output_args(self, output_path: Path):
        """统一的输出编码参数。"""
        return [
            "-c:v", "libx264",
            "-crf", "18",
            "-preset", "medium",
            "-pix_fmt", "yuv420p",
            "-movflags", "+faststart",
            "-r", str(self.output_fps),
            str(output_path)
        ]
    
    def _vf_chain(self, filters):
        """将滤镜列表拼接为 -vf 参数字符串。"""
        return ",".join(filters)
    
    def _vf_with_duration(self, filters, add_trim=False):
        """在现有滤镜链后追加 tpad+trim 来保证输出时长。"""
        chain = list(filters)
        # 延长到至少 duration 秒（克隆最后一帧）
        chain.append(f"tpad=stop_mode=clone:stop_duration={max(0.0, self.duration)}")
        # 最后裁切为精确时长
        chain.append(f"trim=duration={self.duration}")
        return self._vf_chain(chain)
    
    def _pad_center(self):
        """返回居中填充到目标分辨率的 pad 滤镜。"""
        return f"pad={self.w}:{self.h}:(ow-iw)/2:(oh-ih)/2:color=black"
    
    def generate_all_effects(self):
        """生成所有特效视频"""
        print(f"开始生成所有特效视频...")
        print(f"输入图片模式: {self.input_pattern}")
        print(f"输出目录: {self.output_dir}")
        print(f"帧率(输出): {self.output_fps}")
        if self.is_sequence:
            print(f"检测到序列输入，图片数: {self.num_input_frames}，自适应输入帧率: {self.input_fps:.3f} fps")
        else:
            print("检测到单张图片输入，将启用循环以满足时长")
        print(f"每段时长: {self.duration}s, 输出分辨率: {self.output_size}")
        print("=" * 50)
        
        # 为每个特效生成视频
        for effect in self.effects:
            self._generate_single_effect(effect)
        
        print("=" * 50)
        print(f"所有特效视频生成完成！")
        print(f"成功生成了 {len(self.generated_videos)} 个视频文件")
        
        # 如果有成功生成的视频，创建最终合并文件
        if self.generated_videos:
            self._merge_videos()
        else:
            print("警告: 没有成功生成任何视频文件，无法合并")
    
    def _generate_single_effect(self, effect):
        """生成单个特效视频
        
        Args:
            effect: 特效配置字典
        """
        print(f"正在生成 '{effect['description']}'...")
        try:
            output_file = self.output_dir / f"{effect['name']}.mp4"
            # 构建ffmpeg命令
            cmd = [
                "ffmpeg",
                *self._build_input_args(),
                "-vf", effect["filter"],
                *self._build_output_args(output_file)
            ]
            # 执行ffmpeg命令
            result = subprocess.run(
                cmd,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )
            # 简单校验输出文件确实存在且非空
            if output_file.exists() and os.path.getsize(output_file) > 0:
                print(f"成功生成: {effect['description']}")
                self.generated_videos.append(str(output_file))
            else:
                print(f"生成 '{effect['description']}' 失败: 输出文件不存在或为空")
        except subprocess.CalledProcessError as e:
            print(f"生成 '{effect['description']}' 失败:")
            print(f"错误信息: {e.stderr}")
            print(f"继续处理下一个特效...")
        except Exception as e:
            print(f"生成 '{effect['description']}' 时发生未知错误:")
            print(f"错误信息: {str(e)}")
            print(f"继续处理下一个特效...")
    
    def _merge_videos(self):
        """将所有生成的视频合并为一个最终的mp4文件"""
        print("开始合并所有视频...")
        
        # 创建临时文件列表
        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt', encoding='utf-8') as f:
            for video in self.generated_videos:
                f.write(f"file '{os.path.abspath(video)}'\n")
            temp_list_file = f.name
        
        # 合并视频的输出路径
        final_output = self.output_dir / "final_merged_effects.mp4"
        
        # 构建合并视频的ffmpeg命令
        merge_command = [
            "ffmpeg",
            "-y",
            "-f", "concat",
            "-safe", "0",
            "-i", temp_list_file,
            "-c", "copy",
            str(final_output)
        ]
        
        try:
            # 执行合并命令
            subprocess.run(
                merge_command,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )
            print(f"成功合并所有视频到: {final_output}")
        except subprocess.CalledProcessError as e:
            print(f"合并视频失败:")
            print(f"错误信息: {e.stderr}")
        except Exception as e:
            print(f"合并视频时发生未知错误:")
            print(f"错误信息: {str(e)}")
        finally:
            # 清理临时文件
            if os.path.exists(temp_list_file):
                os.unlink(temp_list_file)

    def create_test_images(self, count=10):
        """创建测试图片（用于演示和测试）
        
        Args:
            count: 要创建的测试图片数量
        """
        print(f"正在创建 {count} 张测试图片...")
        
        # 检查是否有ImageMagick或GraphicsMagick
        has_imagemagick = False
        try:
            subprocess.run(["convert", "-version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
            has_imagemagick = True
        except (subprocess.SubprocessError, FileNotFoundError):
            pass
        
        if has_imagemagick:
            # 使用ImageMagick创建测试图片
            for i in range(1, count + 1):
                # 根据输入模式生成图片路径
                if "%" in self.input_pattern:
                    try:
                        img_path = self.input_pattern % i
                    except Exception:
                        img_path = self.input_pattern.replace("%03d", f"{i:03d}").replace("%d", str(i))
                elif any(ch in self.input_pattern for ch in ["*", "?", "["]):
                    # 对于glob模式，默认写入到当前目录：test_0001.jpg 形式
                    img_path = f"test_{i:04d}.jpg"
                else:
                    # 单文件名，直接使用该路径
                    img_path = self.input_pattern
                
                # 创建带有不同颜色和文字的测试图片
                color = f"rgb({(i*30)%255}, {(i*60)%255}, {(i*90)%255})"
                cmd = [
                    "convert",
                    "-size", self.output_size,
                    f"xc:{color}",
                    "-gravity", "center",
                    "-pointsize", "72",
                    "-fill", "white",
                    f"-annotate", "+0+0", f"Image {i}",
                    img_path
                ]
                
                try:
                    subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                    print(f"创建测试图片: {img_path}")
                except Exception as e:
                    print(f"创建测试图片 {img_path} 失败: {str(e)}")
        else:
            print("警告: 未找到ImageMagick，无法创建测试图片。请手动准备图片或安装ImageMagick。")

def main():
    """主函数，处理命令行参数并执行特效生成"""
    parser = argparse.ArgumentParser(description='图片转视频特效工具')
    parser.add_argument('-i', '--input', required=True, help='输入图片的模式，如 \'input%d.jpg\' 或 \'output_%03d.jpg\' 或 \'images/*.jpg\'')
    parser.add_argument('-o', '--output', help='输出目录路径')
    parser.add_argument('--fps', type=int, default=25, help='帧率，默认为25')
    parser.add_argument('--duration', type=float, default=6.0, help='每个特效视频时长（秒），默认6')
    parser.add_argument('--size', default='1280x720', help='输出分辨率，例如 1280x720')
    parser.add_argument('--create-test-images', type=int, help='创建测试图片的数量')
    
    args = parser.parse_args()
    
    try:
        # 创建图片转视频特效工具实例
        img_to_video = ImageToVideoEffects(args.input, args.output, args.fps, args.duration, args.size)
        
        # 如果需要创建测试图片
        if args.create_test_images:
            img_to_video.create_test_images(args.create_test_images)
        
        # 生成所有特效视频
        img_to_video.generate_all_effects()
            
    except Exception as e:
        print(f"错误: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()