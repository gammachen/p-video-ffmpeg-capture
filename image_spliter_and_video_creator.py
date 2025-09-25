#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
图片分割与视频合成工具
功能：
1. 根据指定的切割宽度和高度，将一张图片切割成多张图片
2. 将切割后的多张图片合并成一个视频

用法示例：
python image_spliter_and_video_creator.py -i images/output_001.jpg -cw 300 -ch 200
python image_spliter_and_video_creator.py -i images/output_001.jpg -cw 200 -ch 200 -o output_video.mp4
"""
import os
import subprocess
import argparse
import sys
import tempfile
from pathlib import Path
import re

class ImageSpliterAndVideoCreator:
    """图片分割与视频合成类，用于将图片切割并合成视频"""
    
    def __init__(self, input_image, crop_width, crop_height, output_video=None, fps=25, output_size=None):
        """初始化图片分割与视频合成工具
        
        Args:
            input_image: 输入图片路径
            crop_width: 切割宽度
            crop_height: 切割高度
            output_video: 输出视频路径
            fps: 视频帧率，默认为25
            output_size: 输出视频分辨率，例如 '1280:720'，默认使用原图片尺寸
        """
        # 检查ffmpeg是否安装
        if not self._check_ffmpeg_installed():
            raise RuntimeError("未找到ffmpeg，请先安装ffmpeg")
            
        # 检查输入图片是否存在
        if not os.path.exists(input_image):
            raise FileNotFoundError(f"输入图片不存在: {input_image}")
            
        self.input_image = input_image
        self.crop_width = int(crop_width)
        self.crop_height = int(crop_height)
        self.fps = int(fps)
        
        # 获取原图片尺寸
        self.original_width, self.original_height = self._get_image_dimensions(input_image)
        
        # 验证切割尺寸是否合法
        if self.crop_width > self.original_width or self.crop_height > self.original_height:
            raise ValueError(f"切割尺寸({self.crop_width}x{self.crop_height})大于原图片尺寸({self.original_width}x{self.original_height})")
            
        # 计算可以切割的行数和列数
        self.cols = self.original_width // self.crop_width
        self.rows = self.original_height // self.crop_height
        
        # 确保至少可以切割一块
        if self.cols < 1 or self.rows < 1:
            raise ValueError(f"无法按照指定尺寸({self.crop_width}x{self.crop_height})切割图片")
            
        # 设置输出视频路径
        if output_video:
            self.output_video = output_video
        else:
            # 默认输出路径
            input_name = os.path.splitext(os.path.basename(input_image))[0]
            self.output_video = f"{input_name}_split_{self.rows}x{self.cols}.mp4"
            
        # 设置输出尺寸
        if output_size:
            self.output_size = output_size
        else:
            self.output_size = f"{self.original_width}:{self.original_height}"
            
        # 创建临时目录用于存储切割后的图片
        self.temp_dir = tempfile.mkdtemp(prefix="image_spliter_")
        
        # 存储切割后的图片路径列表
        self.cropped_images = []
        
        print(f"初始化成功：")
        print(f"- 输入图片: {input_image}")
        print(f"- 原图片尺寸: {self.original_width}x{self.original_height}")
        print(f"- 切割尺寸: {self.crop_width}x{self.crop_height}")
        print(f"- 将切割为: {self.rows}行 × {self.cols}列 = {self.rows * self.cols}张图片")
        print(f"- 临时目录: {self.temp_dir}")
        print(f"- 输出视频: {self.output_video}")
    
    def _check_ffmpeg_installed(self):
        """检查ffmpeg是否安装"""
        try:
            subprocess.run(["ffmpeg", "-version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            return True
        except FileNotFoundError:
            return False
    
    def _get_image_dimensions(self, image_path):
        """获取图片尺寸
        
        Args:
            image_path: 图片路径
            
        Returns:
            tuple: (宽度, 高度)
        """
        try:
            # 使用ffprobe获取图片尺寸
            result = subprocess.run(
                ["ffprobe", "-v", "error", "-select_streams", "v:0", 
                 "-show_entries", "stream=width,height", "-of", "csv=p=0", image_path],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
            )
            
            # 解析输出结果
            dimensions = result.stdout.strip().split(',')
            if len(dimensions) == 2:
                return int(dimensions[0]), int(dimensions[1])
            else:
                raise ValueError(f"无法解析图片尺寸: {result.stdout}")
        except Exception as e:
            raise RuntimeError(f"获取图片尺寸失败: {str(e)}")
    
    def split_image(self):
        """将图片切割成多张图片"""
        print(f"开始切割图片...")
        
        # 清空存储列表
        self.cropped_images = []
        
        # 遍历所有切割块
        for row in range(self.rows):
            for col in range(self.cols):
                # 计算切割起始坐标
                x = col * self.crop_width
                y = row * self.crop_height
                
                # 设置输出图片路径
                output_image = os.path.join(self.temp_dir, f"cropped_{row}_{col}.jpg")
                
                # 构建ffmpeg命令切割图片
                cmd = [
                    "ffmpeg",
                    "-i", self.input_image,
                    "-vf", f"crop={self.crop_width}:{self.crop_height}:{x}:{y}",
                    "-y",  # 覆盖已存在的文件
                    output_image
                ]
                
                try:
                    # 执行命令
                    subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                    self.cropped_images.append(output_image)
                    print(f"已切割: {output_image} (位置: {x},{y})")
                except subprocess.CalledProcessError as e:
                    print(f"切割图片失败: {str(e)}")
                    raise
        
        print(f"图片切割完成，共生成 {len(self.cropped_images)} 张图片")
    
    def create_video(self):
        """将切割后的图片合并成视频，包含短视频和主视频的转场效果"""
        if not self.cropped_images:
            raise ValueError("没有可用于合成视频的切割图片，请先执行split_image方法")
        
        print(f"开始合成视频...")
        
        # 生成短视频（只包含前2张图片，持续1秒）
        short_video_path = os.path.join(self.temp_dir, "short_video.mp4")
        self._create_short_video(short_video_path)
        
        # 生成主视频（包含所有图片）
        main_video_path = os.path.join(self.temp_dir, "main_video.mp4")
        self._create_main_video(main_video_path)
        
        # 合并短视频和主视频，并添加转场效果
        self._merge_videos_with_transition(short_video_path, main_video_path, self.output_video)
        
        print(f"视频合成完成: {self.output_video}")
    
    def _create_short_video(self, output_path):
        """创建时长非常短的视频"""
        # 只使用前2张图片创建短视频（如果有的话）
        short_images = self.cropped_images[:2] if len(self.cropped_images) >= 2 else self.cropped_images
        
        # 创建文件列表文件
        file_list_path = os.path.join(self.temp_dir, "short_filelist.txt")
        with open(file_list_path, 'w') as f:
            for img in short_images:
                abs_path = os.path.abspath(img).replace('\\', '/')
                f.write(f"file '{abs_path}'\nduration 0.7\n")  # 每张图片显示0.5秒
            # 最后一张图片需要再写一次
            if short_images:
                abs_path = os.path.abspath(short_images[-1]).replace('\\', '/')
                f.write(f"file '{abs_path}'\n")
        
        # 构建ffmpeg命令合成短视频
        cmd = [
            "ffmpeg",
            "-f", "concat",
            "-safe", "0",
            "-i", file_list_path,
            "-vf", f"scale={self.output_size}:force_original_aspect_ratio=decrease,pad={self.crop_width}:{self.crop_height}:(ow-iw)/2:(oh-ih)/2:black,fps={self.fps}",
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            "-y",
            output_path
        ]
        
        try:
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            print(f"短视频合成完成: {output_path}")
        except subprocess.CalledProcessError as e:
            print(f"短视频合成失败: {str(e)}")
            raise
    
    def _create_main_video(self, output_path):
        """创建包含所有图片的主视频"""
        # 创建文件列表文件
        file_list_path = os.path.join(self.temp_dir, "main_filelist.txt")
        with open(file_list_path, 'w') as f:
            for img in self.cropped_images:
                abs_path = os.path.abspath(img).replace('\\', '/')
                f.write(f"file '{abs_path}'\nduration 0.5\n")  # 每张图片显示1秒
            # 最后一张图片需要再写一次
            abs_path = os.path.abspath(self.cropped_images[-1]).replace('\\', '/')
            f.write(f"file '{abs_path}'\n")
        
        # 构建ffmpeg命令合成主视频
        cmd = [
            "ffmpeg",
            "-f", "concat",
            "-safe", "0",
            "-i", file_list_path,
            "-vf", f"scale={self.output_size}:force_original_aspect_ratio=decrease,pad={self.crop_width}:{self.crop_height}:(ow-iw)/2:(oh-ih)/2:black,fps={self.fps}",
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            "-y",
            output_path
        ]
        
        try:
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            print(f"主视频合成完成: {output_path}")
        except subprocess.CalledProcessError as e:
            print(f"主视频合成失败: {str(e)}")
            raise
    
    def _merge_videos_with_transition(self, video1_path, video2_path, output_path):
        """合并两个视频并添加转场效果"""
        # 定义转场效果：使用xfade滤镜，设置为fade转场，持续1秒
        # 先获取两个视频的时长
        duration1 = self._get_video_duration(video1_path)
        
        # 构建ffmpeg命令合并视频并添加转场
        # 使用xfade滤镜实现转场效果，transition参数可以是fade、slideup、slidedown等
        cmd = [
            "ffmpeg",
            "-i", video1_path,
            "-i", video2_path,
            "-filter_complex", \
            f"[0:v][1:v]xfade=transition=fade:duration=0.7:offset={duration1-0.7},format=yuv420p",
            "-c:v", "libx264",
            "-preset", "medium",
            "-y",
            output_path
        ]
        
        try:
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            print(f"视频合并完成，并添加了转场效果")
        except subprocess.CalledProcessError as e:
            print(f"视频合并失败: {str(e)}")
            raise
    
    def _get_video_duration(self, video_path):
        """获取视频时长（秒）"""
        try:
            # 使用ffprobe获取视频时长
            result = subprocess.run(
                ["ffprobe", "-v", "error", "-show_entries", "format=duration", 
                 "-of", "default=noprint_wrappers=1:nokey=1", video_path],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
            )
            
            # 解析输出结果
            duration = float(result.stdout.strip())
            return duration
        except Exception as e:
            raise RuntimeError(f"获取视频时长失败: {str(e)}")
    
    def clean_up(self):
        """清理临时文件"""
        import shutil
        if os.path.exists(self.temp_dir):
            shutil.rmtree(self.temp_dir)
            print(f"已清理临时目录: {self.temp_dir}")
    
    def run(self):
        """执行完整流程：分割图片并合成视频"""
        try:
            self.split_image()
            self.create_video()
            return True
        except Exception as e:
            print(f"执行过程中出错: {str(e)}")
            return False
        finally:
            # 清理临时文件
            self.clean_up()
            print(f"清理临时目录: {self.temp_dir}")

def parse_args():
    """解析命令行参数"""
    parser = argparse.ArgumentParser(description='图片分割与视频合成工具')
    parser.add_argument('-i', '--input', required=True, help='输入图片路径')
    parser.add_argument('-cw', '--crop-width', required=True, type=int, help='切割宽度')
    parser.add_argument('-ch', '--crop-height', required=True, type=int, help='切割高度')
    parser.add_argument('-o', '--output', help='输出视频路径')
    parser.add_argument('-fps', '--frames-per-second', type=int, default=25, help='视频帧率')
    parser.add_argument('-s', '--size', help='输出视频分辨率，例如 1280x720')
    
    return parser.parse_args()

def main():
    """主函数"""
    # 解析命令行参数
    args = parse_args()
    
    try:
        # 创建图片分割与视频合成实例
        tool = ImageSpliterAndVideoCreator(
            input_image=args.input,
            crop_width=args.crop_width,
            crop_height=args.crop_height,
            output_video=args.output,
            fps=args.frames_per_second,
            output_size=args.size
        )
        
        # 执行完整流程
        success = tool.run()
        
        if success:
            print("\n任务完成！")
            sys.exit(0)
        else:
            print("\n任务失败，请检查错误信息")
            sys.exit(1)
            
    except Exception as e:
        print(f"错误: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()