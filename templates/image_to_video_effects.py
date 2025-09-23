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
    
    def __init__(self, input_pattern, output_dir=None, fps=25):
        """初始化图片转视频特效工具
        
        Args:
            input_pattern: 输入图片的模式，如 'input%d.jpg' 或 'output_%03d.jpg'
            output_dir: 输出目录路径
            fps: 帧率，默认为25
        """
        # 检查ffmpeg是否安装
        if not self._check_ffmpeg_installed():
            raise RuntimeError("未找到ffmpeg，请先安装ffmpeg")
            
        # 设置输入模式和帧率
        self.input_pattern = input_pattern
        self.fps = fps
        
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
        
        # 特效配置列表
        self.effects = [
            {
                "name": "fade_in_out",
                "description": "淡入淡出效果",
                "command": [
                    "ffmpeg",
                    "-framerate", str(self.fps),
                    "-i", self.input_pattern,
                    "-vf", "fade=in:0:30,fade=out:295:30",
                    "-c:v", "libx264",
                    "-crf", "23",
                    "-pix_fmt", "yuv420p",
                    str(self.output_dir / "fade_in_out.mp4")
                ]
            },
            {
                "name": "slide_horizontal",
                "description": "水平滑动效果",
                "command": [
                    "ffmpeg",
                    "-framerate", str(self.fps),
                    "-i", self.input_pattern,
                    "-vf", "scroll=horizontal=0.01",
                    "-c:v", "libx264",
                    "-crf", "23",
                    "-pix_fmt", "yuv420p",
                    str(self.output_dir / "slide_horizontal.mp4")
                ]
            },
            {
                "name": "zoompan_slow",
                "description": "缓慢缩放效果 (肯Burns效果)",
                "command": [
                    "ffmpeg",
                    "-framerate", str(self.fps),
                    "-i", self.input_pattern,
                    "-vf", "zoompan=z='min(zoom+0.0015,1.5)':d=25:x='iw/2-(iw*zoom/2)':y='ih/2-(ih*zoom/2)'",
                    "-c:v", "libx264",
                    "-crf", "23",
                    "-pix_fmt", "yuv420p",
                    str(self.output_dir / "zoompan_slow.mp4")
                ]
            },
            {
                "name": "scroll_horizontal",
                "description": "水平平移效果",
                "command": [
                    "ffmpeg",
                    "-framerate", str(self.fps),
                    "-i", self.input_pattern,
                    "-vf", "scroll=horizontal=0.001",
                    "-c:v", "libx264",
                    "-crf", "23",
                    "-pix_fmt", "yuv420p",
                    str(self.output_dir / "scroll_horizontal.mp4")
                ]
            },
            {
                "name": "black_white",
                "description": "黑白效果",
                "command": [
                    "ffmpeg",
                    "-framerate", str(self.fps),
                    "-i", self.input_pattern,
                    "-vf", "hue=s=0",
                    "-c:v", "libx264",
                    "-crf", "23",
                    "-pix_fmt", "yuv420p",
                    str(self.output_dir / "black_white.mp4")
                ]
            },
            {
                "name": "vintage",
                "description": "复古效果",
                "command": [
                    "ffmpeg",
                    "-framerate", str(self.fps),
                    "-i", self.input_pattern,
                    "-vf", "curves=preset=vintage",
                    "-c:v", "libx264",
                    "-crf", "23",
                    "-pix_fmt", "yuv420p",
                    str(self.output_dir / "vintage.mp4")
                ]
            },
            {
                "name": "gaussian_blur",
                "description": "高斯模糊效果",
                "command": [
                    "ffmpeg",
                    "-framerate", str(self.fps),
                    "-i", self.input_pattern,
                    "-vf", "gblur=sigma=5",
                    "-c:v", "libx264",
                    "-crf", "23",
                    "-pix_fmt", "yuv420p",
                    str(self.output_dir / "gaussian_blur.mp4")
                ]
            },
            {
                "name": "text_watermark",
                "description": "添加文字水印",
                "command": [
                    "ffmpeg",
                    "-framerate", str(self.fps),
                    "-i", self.input_pattern,
                    "-vf", "drawtext=text='My Slideshow':x=10:y=10:fontsize=24:fontcolor=white",
                    "-c:v", "libx264",
                    "-crf", "23",
                    "-pix_fmt", "yuv420p",
                    str(self.output_dir / "text_watermark.mp4")
                ]
            },
            {
                "name": "dynamic_text",
                "description": "动态文字效果",
                "command": [
                    "ffmpeg",
                    "-framerate", str(self.fps),
                    "-i", self.input_pattern,
                    "-vf", "drawtext=text='Frame %{n}':x=w-tw-10:y=10:fontsize=20:fontcolor=red",
                    "-c:v", "libx264",
                    "-crf", "23",
                    "-pix_fmt", "yuv420p",
                    str(self.output_dir / "dynamic_text.mp4")
                ]
            },
            {
                "name": "slow_motion",
                "description": "慢动作效果",
                "command": [
                    "ffmpeg",
                    "-framerate", str(self.fps),
                    "-i", self.input_pattern,
                    "-vf", "setpts=2.0*PTS",
                    "-c:v", "libx264",
                    "-crf", "23",
                    "-pix_fmt", "yuv420p",
                    str(self.output_dir / "slow_motion.mp4")
                ]
            },
            {
                "name": "fast_forward",
                "description": "快进效果",
                "command": [
                    "ffmpeg",
                    "-framerate", str(self.fps),
                    "-i", self.input_pattern,
                    "-vf", "setpts=0.5*PTS",
                    "-c:v", "libx264",
                    "-crf", "23",
                    "-pix_fmt", "yuv420p",
                    str(self.output_dir / "fast_forward.mp4")
                ]
            },
            {
                "name": "pixelize",
                "description": "马赛克效果",
                "command": [
                    "ffmpeg",
                    "-framerate", str(self.fps),
                    "-i", self.input_pattern,
                    "-vf", "pixelize=20:20",
                    "-c:v", "libx264",
                    "-crf", "23",
                    "-pix_fmt", "yuv420p",
                    str(self.output_dir / "pixelize.mp4")
                ]
            },
            {
                "name": "mirror",
                "description": "镜像效果",
                "command": [
                    "ffmpeg",
                    "-framerate", str(self.fps),
                    "-i", self.input_pattern,
                    "-vf", "crop=iw/2:ih:0:0,split[left][tmp];[tmp]hflip[right];[left][right]hstack",
                    "-c:v", "libx264",
                    "-crf", "23",
                    "-pix_fmt", "yuv420p",
                    str(self.output_dir / "mirror.mp4")
                ]
            },
            {
                "name": "comprehensive",
                "description": "高级综合特效 (缩放+淡入淡出+文字)",
                "command": [
                    "ffmpeg",
                    "-framerate", str(self.fps),
                    "-i", self.input_pattern,
                    "-vf", "zoompan=z='min(zoom+0.001,1.2)':d=125:x='iw/2-(iw*zoom/2)':y='ih/2-(ih*zoom/2)',fade=in:0:25,fade=out:295:25,drawtext=text='My Photo':x=(w-text_w)/2:y=h-text_h-10:fontsize=30:fontcolor=white:box=1:boxcolor=black@0.5",
                    "-c:v", "libx264",
                    "-crf", "23",
                    "-pix_fmt", "yuv420p",
                    str(self.output_dir / "comprehensive.mp4")
                ]
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
        # 如果模式包含%d或%03d等，替换为通配符
        # if '%' in pattern:
        #     pattern = pattern.replace('%d', '*').replace('%03d', '*')
        
        matching_files = glob.glob(pattern)
        return len(matching_files) > 0
    
    def generate_all_effects(self):
        """生成所有特效视频"""
        print(f"开始生成所有特效视频...")
        print(f"输入图片模式: {self.input_pattern}")
        print(f"输出目录: {self.output_dir}")
        print(f"帧率: {self.fps}")
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
            # 执行ffmpeg命令
            result = subprocess.run(
                effect['command'],
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )
            print(f"成功生成: {effect['description']}")
            # 将成功生成的视频添加到列表
            output_file = str(self.output_dir / f"{effect['name']}.mp4")
            self.generated_videos.append(output_file)
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
                # 获取输入模式，替换格式说明符
                if '%03d' in self.input_pattern:
                    img_path = self.input_pattern % i
                else:
                    # 在这个函数的文档字符串中，我使用了%d，但argparse可能会尝试解释它
                    # 修复方式是用%%d或者使用其他描述方式
                    img_path = self.input_pattern.replace('%%d', str(i))
                
                # 创建带有不同颜色和文字的测试图片
                color = f"rgb({(i*30)%255}, {(i*60)%255}, {(i*90)%255})"
                cmd = [
                    "convert",
                    "-size", "1280x720",
                    color,
                    "-gravity", "center",
                    "-pointsize", "72",
                    "-fill", "white",
                    "label:Image %d" % i,
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
    parser.add_argument('-i', '--input', required=True, help='输入图片的模式，如 \'input%d.jpg\' 或 \'output_%03d.jpg\'')
    parser.add_argument('-o', '--output', help='输出目录路径')
    parser.add_argument('--fps', type=int, default=25, help='帧率，默认为25')
    parser.add_argument('--create-test-images', type=int, help='创建测试图片的数量')
    
    args = parser.parse_args()
    
    try:
        # 创建图片转视频特效工具实例
        img_to_video = ImageToVideoEffects(args.input, args.output, args.fps)
        
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