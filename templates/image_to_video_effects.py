#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
图片转视频特效工具
根据技术文档实现所有ffmpeg图片转视频特效，生成不同的mp4结果，并最终合并为一个视频
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
            fps: 帧率，默认为25
            duration: 每个效果视频的时长（秒）
            output_size: 输出分辨率，例如 '1280x720'
        """
        # 检查ffmpeg是否安装
        if not self._check_ffmpeg_installed():
            raise RuntimeError("未找到ffmpeg，请先安装ffmpeg")
            
        # 设置输入模式和帧率
        self.input_pattern = input_pattern
        self.fps = int(fps)
        self.duration = float(duration)
        self.output_size = str(output_size)
        self.total_frames = max(1, int(self.fps * self.duration))
        
        # 检查是否有符合模式的图片文件
        if not self._check_input_files():
            print(f"警告: 未找到符合模式 '{input_pattern}' 的图片文件")
        
        # 设置输出目录
        if output_dir:
            self.output_dir = Path(output_dir)
        else:
            self.output_dir = Path.cwd() / "effects_output"
        
        # 创建输出目录
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # 特效配置列表（使用更稳健的滤镜组合，统一时长与分辨率，避免黑屏/一闪而过）
        self.effects = [
            {
                "name": "fade_in_out",
                "description": "淡入淡出效果",
                "filter": self._vf_chain(
                    [
                        f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                        f"pad={self.output_size}:(ow-iw)/2:(oh-ih)/2:color=black",
                        f"fps={self.fps}",
                        f"fade=in:0:{max(1, int(self.fps*0.6))}",
                        f"fade=out:{max(0, self.total_frames - int(self.fps*0.6))}:{max(1, int(self.fps*0.6))}"
                    ]
                )
            },
            {
                "name": "slide_horizontal",
                "description": "水平滑动效果",
                # 通过zoompan实现平移（z=1，仅移动x）
                "filter": self._vf_chain(
                    [
                        f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                        f"pad={self.output_size}:(ow-iw)/2:(oh-ih)/2:color=black",
                        # 使用zoompan将每帧渲染一次，并移动x（t为秒）
                        # 注意：zoompan需要指定输出大小s
                        f"zoompan=z=1:x=min(max(0, t*{int(self.output_size.split('x')[0])//self.duration}),(iw-w)):y=0:d=1:s={self.output_size}:fps={self.fps}"
                    ]
                )
            },
            {
                "name": "zoompan_slow",
                "description": "缓慢缩放效果 (Ken Burns)",
                "filter": self._vf_chain(
                    [
                        f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                        f"pad={self.output_size}:(ow-iw)/2:(oh-ih)/2:color=black",
                        f"zoompan=z='min(1.0+0.15*t,1.5)':x='iw/2-(iw*zoom/2)':y='ih/2-(ih*zoom/2)':d=1:s={self.output_size}:fps={self.fps}"
                    ]
                )
            },
            {
                "name": "black_white",
                "description": "黑白效果",
                "filter": self._vf_chain(
                    [
                        f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                        f"pad={self.output_size}:(ow-iw)/2:(oh-ih)/2:color=black",
                        f"fps={self.fps}",
                        "hue=s=0"
                    ]
                )
            },
            {
                "name": "sepia",
                "description": "复古（棕褐色）效果",
                "filter": self._vf_chain(
                    [
                        f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                        f"pad={self.output_size}:(ow-iw)/2:(oh-ih)/2:color=black",
                        f"fps={self.fps}",
                        # 使用颜色通道混合实现复古色调
                        "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131"
                    ]
                )
            },
            {
                "name": "gaussian_blur",
                "description": "高斯模糊效果",
                "filter": self._vf_chain(
                    [
                        f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                        f"pad={self.output_size}:(ow-iw)/2:(oh-ih)/2:color=black",
                        f"fps={self.fps}",
                        "gblur=sigma=5"
                    ]
                )
            },
            {
                "name": "text_watermark",
                "description": "添加文字水印",
                "filter": self._vf_chain(
                    [
                        f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                        f"pad={self.output_size}:(ow-iw)/2:(oh-ih)/2:color=black",
                        f"fps={self.fps}",
                        # 如果系统找不到默认字体，建议在命令行传入 fontfile
                        "drawtext=text='My Slideshow':x=10:y=10:fontsize=36:fontcolor=white:box=1:boxcolor=black@0.35:boxborderw=10"
                    ]
                )
            },
            {
                "name": "dynamic_text",
                "description": "动态文字效果",
                "filter": self._vf_chain(
                    [
                        f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                        f"pad={self.output_size}:(ow-iw)/2:(oh-ih)/2:color=black",
                        f"fps={self.fps}",
                        "drawtext=text='Frame %{n}':x=w-tw-20:y=20:fontsize=28:fontcolor=red:box=1:boxcolor=black@0.35:boxborderw=10"
                    ]
                )
            },
            {
                "name": "slow_motion",
                "description": "慢动作效果",
                # 使用setpts拉长时基，并用trim统一时长
                "filter": self._vf_chain(
                    [
                        f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                        f"pad={self.output_size}:(ow-iw)/2:(oh-ih)/2:color=black",
                        f"fps={self.fps}",
                        "setpts=2.0*PTS",
                        f"trim=duration={self.duration}"
                    ]
                )
            },
            {
                "name": "fast_forward",
                "description": "快进效果",
                "filter": self._vf_chain(
                    [
                        f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                        f"pad={self.output_size}:(ow-iw)/2:(oh-ih)/2:color=black",
                        f"fps={self.fps}",
                        "setpts=0.5*PTS",
                        f"trim=duration={self.duration}"
                    ]
                )
            },
            {
                "name": "pixelize",
                "description": "马赛克像素化效果",
                # 使用两次scale+neighbor实现像素化（pixelize滤镜在很多构建中不存在）
                "filter": self._vf_chain(
                    [
                        f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                        f"pad={self.output_size}:(ow-iw)/2:(oh-ih)/2:color=black",
                        f"fps={self.fps}",
                        "scale=iw/20:ih/20:flags=neighbor",
                        "scale=iw*20:ih*20:flags=neighbor"
                    ]
                )
            },
            {
                "name": "mirror",
                "description": "镜像效果",
                "filter": self._vf_chain(
                    [
                        f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                        f"pad={self.output_size}:(ow-iw)/2:(oh-ih)/2:color=black",
                        f"fps={self.fps}",
                        "split[a][b];[b]hflip[c];[a][c]hstack"
                    ]
                )
            },
            {
                "name": "comprehensive",
                "description": "高级综合特效 (缩放+淡入淡出+文字)",
                "filter": self._vf_chain(
                    [
                        f"scale={self.output_size}:force_original_aspect_ratio=decrease",
                        f"pad={self.output_size}:(ow-iw)/2:(oh-ih)/2:color=black",
                        # 温和的Ken Burns
                        f"zoompan=z='min(1.0+0.1*t,1.2)':x='iw/2-(iw*zoom/2)':y='ih/2-(ih*zoom/2)':d=1:s={self.output_size}:fps={self.fps}",
                        f"fade=in:0:{max(1, int(self.fps*0.5))}",
                        f"fade=out:{max(0, self.total_frames - int(self.fps*0.5))}:{max(1, int(self.fps*0.5))}",
                        "drawtext=text='My Photo':x=(w-text_w)/2:y=h-text_h-40:fontsize=34:fontcolor=white:box=1:boxcolor=black@0.5:boxborderw=20"
                    ]
                )
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
        # 输入帧率控制
        # 使用 -framerate（输入级别）对于图像序列比 -r 更安全
        args.extend(["-framerate", str(self.fps)])
        # 区分三种情况：glob（* / ? / [ ]）、printf模式（%d）、单文件
        pattern = self.input_pattern
        if any(ch in pattern for ch in ["*", "?", "["]):
            args.extend(["-pattern_type", "glob", "-i", pattern])
        elif "%" in pattern:
            args.extend(["-i", pattern])
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
            "-r", str(self.fps),
            "-t", str(self.duration),
            str(output_path)
        ]
    
    def _vf_chain(self, filters):
        """将滤镜列表拼接为 -vf 参数字符串。"""
        return ",".join(filters)
    
    def generate_all_effects(self):
        """生成所有特效视频"""
        print(f"开始生成所有特效视频...")
        print(f"输入图片模式: {self.input_pattern}")
        print(f"输出目录: {self.output_dir}")
        print(f"帧率: {self.fps}")
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