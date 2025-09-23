# FFmpeg视频截图工具

创建一个使用FFmpeg进行视频截图的HTML页面，包含界面和功能说明。

## 设计思路

这个页面需要包含：
1. FFmpeg命令说明和示例
2. 参数配置区域
3. 可视化命令生成器
4. 响应式设计确保良好显示

下面是完整的实现代码：

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FFmpeg视频截图工具</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        
        body {
            background: linear-gradient(135deg, #1a2a6c, #b21f1f, #fdbb2d);
            color: #333;
            line-height: 1.6;
            padding: 20px;
            min-height: 100vh;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.95);
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            overflow: hidden;
        }
        
        header {
            background: #2c3e50;
            color: white;
            padding: 30px 20px;
            text-align: center;
        }
        
        h1 {
            font-size: 2.8rem;
            margin-bottom: 10px;
        }
        
        .subtitle {
            font-size: 1.2rem;
            opacity: 0.9;
        }
        
        .content {
            display: flex;
            flex-wrap: wrap;
            padding: 20px;
        }
        
        .main-content {
            flex: 3;
            min-width: 300px;
            padding: 20px;
        }
        
        .sidebar {
            flex: 1;
            min-width: 250px;
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            margin: 10px;
        }
        
        section {
            margin-bottom: 30px;
        }
        
        h2 {
            color: #2c3e50;
            margin-bottom: 15px;
            padding-bottom: 8px;
            border-bottom: 2px solid #eaeaea;
        }
        
        h3 {
            color: #3498db;
            margin: 15px 0 10px;
        }
        
        p {
            margin-bottom: 15px;
            font-size: 1.05rem;
        }
        
        .code-block {
            background: #2d2d2d;
            color: #f8f8f2;
            padding: 16px;
            border-radius: 8px;
            font-family: 'Consolas', 'Monaco', monospace;
            overflow-x: auto;
            margin: 15px 0;
            line-height: 1.5;
            font-size: 1rem;
        }
        
        .command-builder {
            background: #e8f4fc;
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        
        .form-group {
            margin-bottom: 15px;
        }
        
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #2c3e50;
        }
        
        input, select {
            width: 100%;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 1rem;
        }
        
        button {
            background: #3498db;
            color: white;
            border: none;
            padding: 12px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 1rem;
            font-weight: bold;
            transition: background 0.3s;
            margin-right: 10px;
        }
        
        button:hover {
            background: #2980b9;
        }
        
        .output-command {
            background: #2c3e50;
            color: white;
            padding: 15px;
            border-radius: 8px;
            margin-top: 20px;
            font-family: monospace;
            white-space: pre-wrap;
        }
        
        .example {
            background: #fff9e6;
            border-left: 4px solid #ffcc00;
            padding: 15px;
            margin: 20px 0;
            border-radius: 0 4px 4px 0;
        }
        
        .tip {
            background: #e8f4fc;
            border-left: 4px solid #3498db;
            padding: 15px;
            margin: 20px 0;
            border-radius: 0 4px 4px 0;
        }
        
        .warning {
            background: #fde8e8;
            border-left: 4px solid #e74c3c;
            padding: 15px;
            margin: 20px 0;
            border-radius: 0 4px 4px 0;
        }
        
        .fa-li {
            color: #3498db;
        }
        
        footer {
            text-align: center;
            padding: 20px;
            background: #2c3e50;
            color: #ecf0f1;
            font-size: 0.9rem;
        }
        
        @media (max-width: 768px) {
            .content {
                flex-direction: column;
            }
            
            h1 {
                font-size: 2.2rem;
            }
            
            .main-content, .sidebar {
                width: 100%;
                margin: 0;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>FFmpeg视频截图工具</h1>
            <p class="subtitle">使用FFmpeg从视频中提取高质量截图</p>
        </header>
        
        <div class="content">
            <div class="main-content">
                <section>
                    <h2>FFmpeg截图功能</h2>
                    <p>FFmpeg是一个强大的多媒体处理工具，可以用来从视频中提取截图。以下是一些常用的截图命令：p>
                    
                    <h3>基本截图命令</h3>
                    <div class="code-block">
# 在指定时间点截取一张图
ffmpeg -i input.mp4 -ss 00:01:30 -vframes 1 output.jpg
                    </div>
                    
                    <h3>批量截图命令</h3>
                    <div class="code-block">
# 每10秒截取一张图
ffmpeg -i input.mp4 -vf "fps=1/10" output_%03d.jpg

# 每秒截取一张图
ffmpeg -i input.mp4 -vf "fps=1" output_%03d.jpg
                    </div>
                    
                    <h3>高质量截图</h3>
                    <div class="code-block">
# 使用高质量参数截图
ffmpeg -i input.mp4 -ss 00:02:00 -vframes 1 -qscale:v 2 output.jpg
                    </div>
                </section>
                
                <section class="command-builder">
                    <h2>FFmpeg命令生成器</h2>
                    
                    <div class="form-group">
                        <label for="inputFile">输入文件:</label>
                        <input type="text" id="inputFile" placeholder="输入视频文件路径" value="input.mp4">
                    </div>
                    
                    <div class="form-group">
                        <label for="timePoint">时间点 (HH:MM:SS):</label>
                        <input type="text" id="timePoint" placeholder="00:01:30" value="00:01:30">
                    </div>
                    
                    <div class="form-group">
                        <label for="outputFile">输出文件:</label>
                        <input type="text" id="outputFile" placeholder="输出图片路径" value="screenshot.jpg">
                    </div>
                    
                    <div class="form-group">
                        <label for="quality">图片质量 (1-31, 1为最高质量):</label>
                        <input type="number" id="quality" min="1" max="31" value="2">
                    </div>
                    
                    <button onclick="generateCommand()">生成命令</button>
                    <button onclick="copyCommand()">复制命令</button>
                    
                    <div class="output-command" id="outputCommand">
                        # 生成的命令将显示在这里
                    </div>
                </section>
                
                <section>
                    <h2>使用说明</h2>
                    
                    <div class="tip">
                        <h3><i class="fas fa-lightbulb"></i> 提示</h3>
                        <p>1. 确保已安装FFmpeg并添加到系统PATH环境变量中</p>
                        <p>2. 使用绝对路径可以避免文件路径错误</p>
                        <p>3. 对于长视频，先使用-ss参数定位时间点可以提高效率</p>
                    </div>
                    
                    <div class="example">
                        <h3><i class="fas fa-code"></i> 示例</h3>
                        <p>从视频"my_video.mp4"的1分30秒处截取高质量图片：</p>
                        <div class="code-block">
ffmpeg -i my_video.mp4 -ss 00:01:30 -vframes 1 -qscale:v 2 screenshot.jpg
                        </div>
                    </div>
                    
                    <div class="warning">
                        <h3><i class="fas fa-exclamation-triangle"></i> 注意事项</h3>
                        <p>1. 确保输出目录有写入权限</p>
                        <p>2. 如果使用Windows系统，注意路径中使用反斜杠(\)</p>
                        <p>3. 某些视频格式可能需要额外参数</p>
                    </div>
                </section>
            </div>
            
            <div class="sidebar">
                <h2>常用参数</h2>
                
                <h3><i class="fas fa-cog"></i> 主要参数</h3>
                <ul class="fa-ul">
                    <li><span class="fa-li"><i class="fas fa-check"></i></span><strong>-i</strong> 输入文件</li>
                    <li><span class="fa-li"><i class="fas fa-check"></i></span><strong>-ss</strong> 定位时间点</li>
                    <li><span class="fa-li"><i class="fas fa-check"></i></span><strong>-vframes</strong> 帧数</li>
                    <li><span class="fa-li"><i class="fas fa-check"></i></span><strong>-qscale:v</strong> 图像质量</li>
                </ul>
                
                <h3><i class="fas fa-image"></i> 输出格式</h3>
                <ul class="fa-ul">
                    <li><span class="fa-li"><i class="fas fa-file-image"></i></span><strong>.jpg</strong> JPEG格式</li>
                    <li><span class="fa-li"><i class="fas fa-file-image"></i></span><strong>.png</strong> PNG格式</li>
                    <li><span class="fa-li"><i class="fas fa-file-image"></i></span><strong>.bmp</strong> BMP格式</li>
                </ul>
                
                <h3><i class="fas fa-terminal"></i> 使用技巧</h3>
                <p>1. 使用通配符处理多个文件</p>
                <p>2. 结合脚本批量处理视频</p>
                <p>3. 使用-filter_complex进行高级处理</p>
                
                <div class="tip">
                    <h3><i class="fas fa-download"></i> 安装FFmpeg</h3>
                    <p>Ubuntu/Debian:</p>
                    <div class="code-block">sudo apt install ffmpeg</div>
                    <p>Windows:</p>
                    <p>从官网下载编译版本</p>
                </div>
            </div>
        </div>
        
        <footer>
            <p>© 2023 FFmpeg视频截图工具 | 本工具仅提供命令参考，实际执行需要在命令行中运行</p>
        </footer>
    </div>

    <script>
        function generateCommand() {
            const inputFile = document.getElementById('inputFile').value || 'input.mp4';
            const timePoint = document.getElementById('timePoint').value || '00:01:30';
            const outputFile = document.getElementById('outputFile').value || 'output.jpg';
            const quality = document.getElementById('quality').value || '2';
            
            const command = `ffmpeg -i ${inputFile} -ss ${timePoint} -vframes 1 -qscale:v ${quality} ${outputFile}`;
            
            document.getElementById('outputCommand').textContent = command;
        }
        
        function copyCommand() {
            const commandText = document.getElementById('outputCommand').textContent;
            
            if (commandText && commandText !== '# 生成的命令将显示在这里') {
                navigator.clipboard.writeText(commandText).then(() => {
                    alert('命令已复制到剪贴板！');
                }).catch(err => {
                    console.error('无法复制文本: ', err);
                });
            } else {
                alert('请先生成命令！');
            }
        }
        
        // 初始化生成一个命令
        window.onload = generateCommand;
    </script>
</body>
</html>
```

## 功能说明

这个页面提供了以下功能：

1. **FFmpeg命令示例**：展示常用的视频截图命令
2. **命令生成器**：通过表单输入生成定制化的FFmpeg命令
3. **参数说明**：解释常用参数的作用和用法
4. **使用提示**：提供使用FFmpeg的实用技巧和注意事项
5. **命令复制**：一键复制生成的命令到剪贴板

## 使用方法

1. 在表单中输入您的视频文件路径、时间点、输出文件名和质量参数
2. 点击"生成命令"按钮生成FFmpeg命令
3. 点击"复制命令"按钮将命令复制到剪贴板
4. 在命令行终端中运行复制的命令

这个页面完全响应式，可以在手机、平板和电脑上正常显示和使用。