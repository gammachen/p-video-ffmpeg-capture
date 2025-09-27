#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""图片网格合并工具

此工具支持两种模式：
1. 目录模式：将指定目录下的所有图片合并为网格图片
2. 多图片模式：将指定的多张图片合并为网格图片
3. 可选生成视频：将合并过程制作成带转场特效的视频

python image_grid_creator_simple.py -d 视频制作解决方案/captured -o output-join.jpg
"""

import os
import sys
import argparse
import math
import subprocess
import tempfile
import glob
from typing import List, Tuple, Optional

# 尝试导入PIL库，如果没有安装则提供友好的错误信息
try:
    from PIL import Image
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False


class ImageGridCreator:
    def __init__(self, 
                 output_file: str, 
                 max_width: int = 1920, 
                 max_height: int = 1080, 
                 create_video: bool = False, 
                 video_duration: float = 5.0, 
                 fps: float = 30.0):
        """初始化图片网格创建器

        Args:
            output_file: 输出文件路径
            max_width: 最大宽度
            max_height: 最大高度
            create_video: 是否创建视频
            video_duration: 视频持续时间（秒）
            fps: 视频帧率
        """
        self.output_file = output_file
        self.max_width = max_width
        self.max_height = max_height
        self.create_video = create_video
        self.video_duration = video_duration
        self.fps = fps
        self.temp_dir = tempfile.mkdtemp()
        
    def __del__(self):
        """清理临时目录"""
        if hasattr(self, 'temp_dir') and os.path.exists(self.temp_dir):
            try:
                # 清理临时文件
                for file in os.listdir(self.temp_dir):
                    os.remove(os.path.join(self.temp_dir, file))
                os.rmdir(self.temp_dir)
            except Exception as e:
                print(f"警告：清理临时目录失败: {str(e)}")

    def check_ffmpeg(self) -> bool:
        """检查FFmpeg是否安装

        Returns:
            bool: 是否安装了FFmpeg
        """
        try:
            subprocess.run(['ffmpeg', '-version'], check=True, 
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            return True
        except (subprocess.SubprocessError, FileNotFoundError):
            print("错误：未找到ffmpeg，请先安装ffmpeg！")
            return False

    def get_image_files_from_dir(self, dir_path: str) -> List[str]:
        """从目录中获取所有图片文件

        Args:
            dir_path: 目录路径

        Returns:
            List[str]: 图片文件路径列表
        """
        if not os.path.isdir(dir_path):
            print(f"错误：目录不存在: {dir_path}")
            return []
        
        # 支持的图片格式
        image_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.gif']
        image_files = []
        
        for ext in image_extensions:
            # 使用glob模式匹配所有图片文件
            pattern = os.path.join(dir_path, f'*{ext}')
            image_files.extend(glob.glob(pattern))
            # 处理大写扩展名
            pattern = os.path.join(dir_path, f'*{ext.upper()}')
            image_files.extend(glob.glob(pattern))
        
        # 按文件名排序
        image_files.sort()
        return image_files

    def calculate_grid_size(self, num_images: int) -> Tuple[int, int]:
        """根据图片数量计算合适的行列数

        Args:
            num_images: 图片数量

        Returns:
            Tuple[int, int]: (行数, 列数)
        """
        if num_images <= 0:
            return 0, 0
        
        # 计算平方根，确定大致的行列数
        sqrt = math.sqrt(num_images)
        cols = math.ceil(sqrt)
        rows = math.ceil(num_images / cols)
        
        return rows, cols

    def create_grid_image(self, image_files: List[str], output_path: str) -> bool:
        """创建网格图片

        Args:
            image_files: 图片文件列表
            output_path: 输出文件路径

        Returns:
            bool: 是否成功创建
        """
        num_images = len(image_files)
        if num_images == 0:
            print("错误：没有找到图片文件！")
            return False
        
        # 计算行列数
        rows, cols = self.calculate_grid_size(num_images)
        print(f"使用 {rows}x{cols} 的网格布局合并 {num_images} 张图片")
        
        # 计算每个单元格的尺寸
        cell_width = self.max_width // cols
        cell_height = self.max_height // rows
        
        # 确保尺寸是偶数（H.264要求）
        cell_width = cell_width // 2 * 2
        cell_height = cell_height // 2 * 2
        
        try:
            # 优先使用PIL库来处理图片网格创建，这更可靠
            if PIL_AVAILABLE:
                print("使用PIL库创建网格图片...")
                
                # 创建空白背景图片
                grid_image = Image.new('RGB', (self.max_width, self.max_height), color='black')
                
                # 处理并放置每张图片
                for i in range(rows * cols):
                    row = i // cols
                    col = i % cols
                    x_pos = col * cell_width
                    y_pos = row * cell_height
                    
                    try:
                        if i < num_images:
                            # 打开并处理实际图片
                            with Image.open(image_files[i]) as img:
                                # 计算缩放比例以保持宽高比
                                img_ratio = img.width / img.height
                                cell_ratio = cell_width / cell_height
                                
                                if img_ratio > cell_ratio:
                                    # 宽度优先
                                    new_width = cell_width
                                    new_height = int(cell_width / img_ratio)
                                else:
                                    # 高度优先
                                    new_height = cell_height
                                    new_width = int(cell_height * img_ratio)
                                
                                # 缩放图片
                                img = img.resize((new_width, new_height), Image.LANCZOS)
                                
                                # 计算居中位置
                                paste_x = x_pos + (cell_width - new_width) // 2
                                paste_y = y_pos + (cell_height - new_height) // 2
                                
                                # 粘贴到网格中
                                grid_image.paste(img, (paste_x, paste_y))
                        else:
                            # 空白单元格，保持黑色背景
                            pass
                    except Exception as e:
                        print(f"警告：处理图片 {i} 失败: {str(e)}")
                        # 继续处理其他图片
                        continue
                
                # 保存最终的网格图片
                grid_image.save(output_path, quality=95)
                print(f"成功创建网格图片: {output_path}")
                return True
            else:
                # 如果没有PIL库，回退到使用FFmpeg的方法，但进行简化以避免命令行过长
                print("PIL库不可用，回退到FFmpeg方法...")
                
                # 使用更简单的FFmpeg方法：创建一个小的网格来测试
                # 限制最大图片数量以避免命令行过长
                max_images = 50  # 限制处理的图片数量
                if num_images > max_images:
                    print(f"警告：图片数量过多（{num_images}张），将只处理前{max_images}张图片")
                    image_files = image_files[:max_images]
                    num_images = max_images
                    # 重新计算行列数
                    rows, cols = self.calculate_grid_size(num_images)
                    print(f"使用调整后的 {rows}x{cols} 网格布局")
                
                # 构建FFmpeg命令
                cmd = ['ffmpeg']
                
                # 添加输入文件
                for img_path in image_files:
                    cmd.extend(['-i', img_path])
                
                # 添加足够的黑色背景
                for _ in range(num_images, rows * cols):
                    cmd.extend(['-f', 'lavfi', '-i', f'color=c=black:s=1x1:r=1'])
                
                # 构建滤镜
                filter_complex = []
                
                # 处理每个图片，缩放到单元格大小并居中
                for i in range(rows * cols):
                    filter_complex.append(
                        f'[{i}:v]scale={cell_width}:{cell_height}:force_original_aspect_ratio=decrease:flags=lanczos,pad={cell_width}:{cell_height}:(ow-iw)/2:(oh-ih)/2:black[img{i}]'
                    )
                
                # 构建网格堆叠滤镜
                grid_filters = []
                for row in range(rows):
                    row_inputs = ''.join([f'[img{row*cols + col}]' for col in range(cols)])
                    grid_filters.append(f'{row_inputs}hstack=inputs={cols}[row{row}]')
                
                # 垂直堆叠所有行
                rows_input = ''.join([f'[row{r}]' for r in range(rows)])
                grid_filters.append(f'{rows_input}vstack=inputs={rows}[final]')
                
                # 添加滤镜参数
                cmd.extend(['-filter_complex', ';'.join(filter_complex + grid_filters)])
                
                # 设置输出参数
                cmd.extend(['-map', '[final]', '-q:v', '2', '-y', output_path])
                
                print(f"正在创建网格图片: {output_path}")
                subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                print(f"成功创建网格图片: {output_path}")
                print("提示：安装PIL库（pip install pillow）可以获得更好的性能和稳定性！")
                return True
        except Exception as e:
            print(f"创建网格图片失败: {str(e)}")
            # 尝试打印详细的错误输出以帮助调试
            if hasattr(e, 'stderr'):
                try:
                    stderr_output = e.stderr.decode('utf-8')
                    print(f"FFmpeg错误输出: {stderr_output[:500]}...")  # 只打印前500个字符
                except:
                    pass
            return False

    def create_transition_video(self, image_files: List[str], output_path: str) -> bool:
        """创建带转场特效的视频

        Args:
            image_files: 图片文件列表
            output_path: 输出文件路径

        Returns:
            bool: 是否成功创建
        """
        num_images = len(image_files)
        if num_images == 0:
            print("错误：没有找到图片文件！")
            return False
        
        # 对于大量图片，简化视频生成逻辑以避免命令行过长
        if num_images > 50:
            print(f"警告：图片数量过多（{num_images}张），将使用简化的视频生成方法")
            return self.create_simple_video(image_files, output_path)
        
        # 强制使用3x4的网格布局
        rows, cols = 3, 4
        print(f"使用 {rows}x{cols} 的网格布局创建视频，转场特效为最简单的淡入效果")
        
        # 计算每个单元格的尺寸
        cell_width = self.max_width // cols
        cell_height = self.max_height // rows
        
        # 确保尺寸是偶数
        cell_width = cell_width // 2 * 2
        cell_height = cell_height // 2 * 2
        
        try:
            # 1. 先创建临时文件夹存储处理后的图片
            processed_dir = os.path.join(self.temp_dir, 'processed_images')
            os.makedirs(processed_dir, exist_ok=True)
            
            # 2. 处理每张图片并保存为临时文件
            processed_files = []
            for i, img_path in enumerate(image_files):
                processed_img = os.path.join(processed_dir, f'processed_{i}.jpg')
                
                # 缩放到单元格大小并居中
                process_cmd = [
                    'ffmpeg', '-i', img_path,
                    '-vf', f'scale={cell_width}:{cell_height}:force_original_aspect_ratio=decrease:flags=lanczos,pad={cell_width}:{cell_height}:(ow-iw)/2:(oh-ih)/2:black',
                    '-q:v', '2', '-y', processed_img
                ]
                
                # 添加错误处理，避免单个图片处理失败影响整体
                try:
                    subprocess.run(process_cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                    processed_files.append(processed_img)
                except Exception as e:
                    print(f"处理图片 {i+1} 失败，跳过: {str(e)}")
                    # 创建一个空白图片作为替代
                    blank_cmd = [
                        'ffmpeg', '-f', 'lavfi', '-i', f'color=c=black:s={cell_width}x{cell_height}:r=1',
                        '-frames:v', '1', '-q:v', '2', '-y', processed_img
                    ]
                    subprocess.run(blank_cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                    processed_files.append(processed_img)
            
            # 3. 计算每张图片的出现时间
            transition_duration = 0.3  # 每个图片的淡入时间
            image_delay = 0.2  # 图片之间的延迟时间
            
            # 4. 创建一个视频脚本文件，使用filter_complex
            concat_file = os.path.join(self.temp_dir, 'video_concat.txt')
            with open(concat_file, 'w') as f:
                for i, processed_img in enumerate(processed_files):
                    f.write(f"file '{os.path.abspath(processed_img)}'\n")
                    # 每个图片显示一小段时间
                    f.write(f"duration 1.0\n")
                # 最后一个文件不需要duration
                if processed_files:
                    f.write(f"file '{os.path.abspath(processed_files[-1])}'\n")
            
            # 5. 使用filter_complex创建最简单的转场效果
            # 先创建一个空背景
            create_video_cmd = [
                'ffmpeg',
                '-f', 'concat', '-safe', '0', '-i', concat_file,
                '-f', 'lavfi', '-i', f'color=c=black:s={self.max_width}x{self.max_height}:r={self.fps}',
                '-filter_complex', (
                    # 对每个输入图片应用淡入效果和定位
                    f'[0:v]scale={cell_width}:{cell_height}:force_original_aspect_ratio=decrease:flags=lanczos,'
                    f'pad={self.max_width}:{self.max_height}:(ow-iw)/2:(oh-ih)/2:black,'
                    f'fade=in:st=0:d={transition_duration},fade=out:st={self.video_duration-transition_duration}:d={transition_duration}[img]'
                ),
                '-map', '[img]',
                '-c:v', 'libx264', '-preset', 'medium', '-crf', '28',
                '-pix_fmt', 'yuv420p', '-t', str(self.video_duration), '-r', str(self.fps), '-y', output_path
            ]
            
            print(f"正在创建视频: {output_path}")
            print(f"视频时长: {self.video_duration}秒, 帧率: {self.fps}fps")
            print(f"使用最简单的淡入淡出效果")
            
            subprocess.run(create_video_cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            print(f"成功创建视频: {output_path}")
            return True
        except Exception as e:
            print(f"创建视频失败: {str(e)}")
            # 尝试打印详细的错误输出以帮助调试
            if hasattr(e, 'stderr'):
                try:
                    stderr_output = e.stderr.decode('utf-8')
                    print(f"FFmpeg错误输出: {stderr_output[:500]}...")  # 只打印前500个字符
                except:
                    pass
            return False
    
    def create_simple_video(self, image_files: List[str], output_path: str) -> bool:
        """为大量图片创建简化的视频
        
        Args:
            image_files: 图片文件列表
            output_path: 输出文件路径
        
        Returns:
            bool: 是否成功创建
        """
        try:
            # 1. 创建一个大的网格图片（使用我们已经优化过的PIL方法）
            grid_image_path = os.path.join(self.temp_dir, 'grid_image.jpg')
            if not self.create_grid_image(image_files, grid_image_path):
                print("创建网格图片失败，无法继续创建视频")
                return False
            
            # 2. 使用这个网格图片创建一个简单的视频
            # 添加一些简单的效果，如淡入淡出或轻微缩放
            create_video_cmd = [
                'ffmpeg', '-loop', '1', '-i', grid_image_path,
                '-vf', f"fade=in:st=0:d=1,fade=out:st={self.video_duration-1}:d=1,scale={self.max_width}:{self.max_height}",
                '-c:v', 'libx264', '-preset', 'medium', '-crf', '23', 
                '-pix_fmt', 'yuv420p', '-t', str(self.video_duration), '-r', str(self.fps), '-y', output_path
            ]
            
            print(f"正在创建简化视频: {output_path}")
            print(f"视频时长: {self.video_duration}秒, 帧率: {self.fps}fps")
            
            subprocess.run(create_video_cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            print(f"成功创建简化视频: {output_path}")
            return True
        except Exception as e:
            print(f"创建简化视频失败: {str(e)}")
            return False

    def process_directory(self, dir_path: str) -> bool:
        """处理目录模式

        Args:
            dir_path: 目录路径

        Returns:
            bool: 是否成功处理
        """
        # 获取目录中的图片文件
        image_files = self.get_image_files_from_dir(dir_path)
        if not image_files:
            return False
        
        return self.process_images(image_files)

    def process_images(self, image_files: List[str]) -> bool:
        """处理图片列表

        Args:
            image_files: 图片文件列表

        Returns:
            bool: 是否成功处理
        """
        if self.create_video:
            # 创建视频
            if not self.check_ffmpeg():
                return False
            
            # 确定输出文件扩展名
            output_ext = os.path.splitext(self.output_file)[1].lower()
            if not output_ext or output_ext not in ['.mp4', '.mov', '.avi']:
                video_output = os.path.splitext(self.output_file)[0] + '.mp4'
            else:
                video_output = self.output_file
            
            return self.create_transition_video(image_files, video_output)
        else:
            # 创建图片
            # 确定输出文件扩展名
            output_ext = os.path.splitext(self.output_file)[1].lower()
            if not output_ext or output_ext not in ['.jpg', '.jpeg', '.png', '.bmp']:
                image_output = os.path.splitext(self.output_file)[0] + '.jpg'
            else:
                image_output = self.output_file
            
            if not self.check_ffmpeg():
                return False
            
            return self.create_grid_image(image_files, image_output)


def main():
    """主函数"""
    # 解析命令行参数
    parser = argparse.ArgumentParser(description='图片网格合并工具')
    
    # 模式选择：目录模式或多图片模式
    mode_group = parser.add_mutually_exclusive_group(required=True)
    mode_group.add_argument('-d', '--directory', help='目录路径（目录模式）')
    mode_group.add_argument('-i', '--images', nargs='+', help='图片文件列表（多图片模式）')
    
    # 通用参数
    parser.add_argument('-o', '--output', required=True, help='输出文件路径')
    parser.add_argument('-w', '--width', type=int, default=1920, help='输出最大宽度（默认：1920）')
    parser.add_argument('-hh', '--height', type=int, default=1080, help='输出最大高度（默认：1080）')
    parser.add_argument('-v', '--video', action='store_true', help='生成视频而不是图片')
    parser.add_argument('-t', '--duration', type=float, default=5.0, help='视频持续时间（秒，默认：5.0）')
    parser.add_argument('--fps', type=float, default=30.0, help='视频帧率（默认：30.0）')
    
    args = parser.parse_args()
    
    # 创建图片网格创建器
    creator = ImageGridCreator(
        output_file=args.output,
        max_width=args.width,
        max_height=args.height,
        create_video=args.video,
        video_duration=args.duration,
        fps=args.fps
    )
    
    # 处理输入
    success = False
    if args.directory:
        # 目录模式
        success = creator.process_directory(args.directory)
    elif args.images:
        # 多图片模式
        # 验证图片文件是否存在
        valid_images = []
        for img_path in args.images:
            if os.path.isfile(img_path):
                valid_images.append(img_path)
            else:
                print(f"警告：图片文件不存在: {img_path}")
        
        if valid_images:
            success = creator.process_images(valid_images)
        else:
            print("错误：没有有效的图片文件！")
    
    # 输出结果
    if success:
        print(f"任务完成！输出文件已保存至: {args.output}")
        return 0
    else:
        print("任务失败！")
        return 1


if __name__ == '__main__':
    sys.exit(main())