
(TraeAI-6) ~/Code/cursor-projects/p-video-ffmpeg-capture [0] $ ffmpeg -loop 1 -i "/var/folders/9l/kbk_mdlj0x5bcvscm_41pmbm0000gn/T/tmp_q6vahfw/processed_images/prev_bg_0.jpg" \
       -loop 1 -i "/var/folders/9l/kbk_mdlj0x5bcvscm_41pmbm0000gn/T/tmp_q6vahfw/processed_images/processed_0.jpg" \
       -filter_complex \
       "[1:v]format=rgba,pad=iw+10:ih+10:(ow-iw)/2:(oh-ih)/2:color=black@0[img_padded];
        [img_padded]fade=in:st=0:d=0.5,trim=duration=0.5,setpts=PTS-STARTPTS[img_flip];
        [img_flip]translate=w*((0.5-t)/0.5):0[img_translated];
        [0:v][img_translated]overlay=x=0:y=0:shortest=1[out];
        [out]split[out1][out2]" \
       -map "[out1]" \
       -c:v libx264 -preset ultrafast -crf 25 -pix_fmt yuv420p -r 30.0 \
       -y "/var/folders/9l/kbk_mdlj0x5bcvscm_41pmbm0000gn/T/tmp_q6vahfw/processed_images/step_0.mp4" \
       -map "[out2]" -frames:v 1 -q:v 2 \
       "/var/folders/9l/kbk_mdlj0x5bcvscm_41pmbm0000gn/T/tmp_q6vahfw/processed_images/bg_0.jpg"
ffmpeg version 7.1.1 Copyright (c) 2000-2025 the FFmpeg developers
  built with Apple clang version 16.0.0 (clang-1600.0.26.6)
  configuration: --prefix=/opt/homebrew/Cellar/ffmpeg/7.1.1_1 --enable-shared --enable-pthreads --enable-version3 --cc=clang --host-cflags= --host-ldflags='-Wl,-ld_classic' --enable-ffplay --enable-gnutls --enable-gpl --enable-libaom --enable-libaribb24 --enable-libbluray --enable-libdav1d --enable-libharfbuzz --enable-libjxl --enable-libmp3lame --enable-libopus --enable-librav1e --enable-librist --enable-librubberband --enable-libsnappy --enable-libsrt --enable-libssh --enable-libsvtav1 --enable-libtesseract --enable-libtheora --enable-libvidstab --enable-libvmaf --enable-libvorbis --enable-libvpx --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxml2 --enable-libxvid --enable-lzma --enable-libfontconfig --enable-libfreetype --enable-frei0r --enable-libass --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libopenjpeg --enable-libspeex --enable-libsoxr --enable-libzmq --enable-libzimg --disable-libjack --disable-indev=jack --enable-videotoolbox --enable-audiotoolbox --enable-neon
  libavutil      59. 39.100 / 59. 39.100
  libavcodec     61. 19.101 / 61. 19.101
  libavformat    61.  7.100 / 61.  7.100
  libavdevice    61.  3.100 / 61.  3.100
  libavfilter    10.  4.100 / 10.  4.100
  libswscale      8.  3.100 /  8.  3.100
  libswresample   5.  3.100 /  5.  3.100
  libpostproc    58.  3.100 / 58.  3.100
[AVFilterGraph @ 0x1269040d0] No option name near 'w*((0.5-t)/0.5):0'
[AVFilterGraph @ 0x1269040d0] Error parsing a filter description around: [img_translated];
        [0:v][img_translated]overlay=x=0:y=0:shortest=1[out];
        [out]split[out1][out2]
[AVFilterGraph @ 0x1269040d0] Error parsing filterchain '[img_flip]translate=w*((0.5-t)/0.5):0[img_translated];
        [0:v][img_translated]overlay=x=0:y=0:shortest=1[out];
        [out]split[out1][out2]' around: [img_translated];
        [0:v][img_translated]overlay=x=0:y=0:shortest=1[out];
        [out]split[out1][out2]
Failed to set value '[1:v]format=rgba,pad=iw+10:ih+10:(ow-iw)/2:(oh-ih)/2:color=black@0[img_padded];
        [img_padded]fade=in:st=0:d=0.5,trim=duration=0.5,setpts=PTS-STARTPTS[img_flip];
        [img_flip]translate=w*((0.5-t)/0.5):0[img_translated];
        [0:v][img_translated]overlay=x=0:y=0:shortest=1[out];
        [out]split[out1][out2]' for option 'filter_complex': Invalid argument
Error parsing global options: Invalid argument

(TraeAI-6) ~/Code/cursor-projects/p-video-ffmpeg-capture [234] $ ffmpeg -loop 1 -i "/var/folders/9l/kbk_mdlj0x5bcvscm_41pmbm0000gn/T/tmp_q6vahfw/processed_images/prev_bg_0.jpg" \
       -loop 1 -i "/var/folders/9l/kbk_mdlj0x5bcvscm_41pmbm0000gn/T/tmp_q6vahfw/processed_images/processed_0.jpg" \
       -filter_complex \
       "[1:v]trim=duration=0.5,setpts=PTS-STARTPTS,format=rgba,
        pad=iw+10:ih+10:(ow-iw)/2:(oh-ih)/2:color=black@0[img_padded];
        [img_padded]fade=in:st=0:d=0.5[img_fade];
        [img_fade]translate='if(lte(t,0.5),w*(0.5-t)/0.5,0)':0[img_translated];
        [0:v][img_translated]overlay=x=0:y=0:shortest=1[out];
        [out]split[out1][out2]" \
       -map "[out1]" \
       -c:v libx264 -preset ultrafast -crf 25 -pix_fmt yuv420p -r 30.0 -t 0.5 \
       -y "/var/folders/9l/kbk_mdlj0x5bcvscm_41pmbm0000gn/T/tmp_q6vahfw/processed_images/step_0.mp4" \
       -map "[out2]" -frames:v 1 -q:v 2 \
       "/var/folders/9l/kbk_mdlj0x5bcvscm_41pmbm0000gn/T/tmp_q6vahfw/processed_images/bg_0.jpg"
ffmpeg version 7.1.1 Copyright (c) 2000-2025 the FFmpeg developers
  built with Apple clang version 16.0.0 (clang-1600.0.26.6)
  configuration: --prefix=/opt/homebrew/Cellar/ffmpeg/7.1.1_1 --enable-shared --enable-pthreads --enable-version3 --cc=clang --host-cflags= --host-ldflags='-Wl,-ld_classic' --enable-ffplay --enable-gnutls --enable-gpl --enable-libaom --enable-libaribb24 --enable-libbluray --enable-libdav1d --enable-libharfbuzz --enable-libjxl --enable-libmp3lame --enable-libopus --enable-librav1e --enable-librist --enable-librubberband --enable-libsnappy --enable-libsrt --enable-libssh --enable-libsvtav1 --enable-libtesseract --enable-libtheora --enable-libvidstab --enable-libvmaf --enable-libvorbis --enable-libvpx --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxml2 --enable-libxvid --enable-lzma --enable-libfontconfig --enable-libfreetype --enable-frei0r --enable-libass --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libopenjpeg --enable-libspeex --enable-libsoxr --enable-libzmq --enable-libzimg --disable-libjack --disable-indev=jack --enable-videotoolbox --enable-audiotoolbox --enable-neon
  libavutil      59. 39.100 / 59. 39.100
  libavcodec     61. 19.101 / 61. 19.101
  libavformat    61.  7.100 / 61.  7.100
  libavdevice    61.  3.100 / 61.  3.100
  libavfilter    10.  4.100 / 10.  4.100
  libswscale      8.  3.100 /  8.  3.100
  libswresample   5.  3.100 /  5.  3.100
  libpostproc    58.  3.100 / 58.  3.100
[AVFilterGraph @ 0x13d104240] No option name near 'if(lte(t,0.5),w*(0.5-t)/0.5,0):0'
[AVFilterGraph @ 0x13d104240] Error parsing a filter description around: [img_translated];
        [0:v][img_translated]overlay=x=0:y=0:shortest=1[out];
        [out]split[out1][out2]
[AVFilterGraph @ 0x13d104240] Error parsing filterchain '[img_fade]translate='if(lte(t,0.5),w*(0.5-t)/0.5,0)':0[img_translated];
        [0:v][img_translated]overlay=x=0:y=0:shortest=1[out];
        [out]split[out1][out2]' around: [img_translated];
        [0:v][img_translated]overlay=x=0:y=0:shortest=1[out];
        [out]split[out1][out2]
Failed to set value '[1:v]trim=duration=0.5,setpts=PTS-STARTPTS,format=rgba,
        pad=iw+10:ih+10:(ow-iw)/2:(oh-ih)/2:color=black@0[img_padded];
        [img_padded]fade=in:st=0:d=0.5[img_fade];
        [img_fade]translate='if(lte(t,0.5),w*(0.5-t)/0.5,0)':0[img_translated];
        [0:v][img_translated]overlay=x=0:y=0:shortest=1[out];
        [out]split[out1][out2]' for option 'filter_complex': Invalid argument
Error parsing global options: Invalid argument

(TraeAI-6) ~/Code/cursor-projects/p-video-ffmpeg-capture [234] $ ffmpeg -loop 1 -i "/var/folders/9l/kbk_mdlj0x5bcvscm_41pmbm0000gn/T/tmp_q6vahfw/processed_images/prev_bg_0.jpg" \
       -loop 1 -i "/var/folders/9l/kbk_mdlj0x5bcvscm_41pmbm0000gn/T/tmp_q6vahfw/processed_images/processed_0.jpg" \
       -filter_complex \
       "[1:v]trim=duration=0.5,setpts=PTS-STARTPTS,format=rgba,
        pad=iw+10:ih+10:(ow-iw)/2:(oh-ih)/2:color=black@0,
        fade=in:st=0:d=0.5,
        translate='min(0,w*(0.5-t)/0.5)':0[animated];
        [0:v][animated]overlay=0:0:shortest=1[out];
        [out]split[out1][out2]" \
       -map "[out1]" \
       -c:v libx264 -preset ultrafast -crf 25 -pix_fmt yuv420p -r 30.0 \
       -y "/var/folders/9l/kbk_mdlj0x5bcvscm_41pmbm0000gn/T/tmp_q6vahfw/processed_images/step_0.mp4" \
       -map "[out2]" -frames:v 1 -q:v 2 \
       "/var/folders/9l/kbk_mdlj0x5bcvscm_41pmbm0000gn/T/tmp_q6vahfw/processed_images/bg_0.jpg"
ffmpeg version 7.1.1 Copyright (c) 2000-2025 the FFmpeg developers
  built with Apple clang version 16.0.0 (clang-1600.0.26.6)
  configuration: --prefix=/opt/homebrew/Cellar/ffmpeg/7.1.1_1 --enable-shared --enable-pthreads --enable-version3 --cc=clang --host-cflags= --host-ldflags='-Wl,-ld_classic' --enable-ffplay --enable-gnutls --enable-gpl --enable-libaom --enable-libaribb24 --enable-libbluray --enable-libdav1d --enable-libharfbuzz --enable-libjxl --enable-libmp3lame --enable-libopus --enable-librav1e --enable-librist --enable-librubberband --enable-libsnappy --enable-libsrt --enable-libssh --enable-libsvtav1 --enable-libtesseract --enable-libtheora --enable-libvidstab --enable-libvmaf --enable-libvorbis --enable-libvpx --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxml2 --enable-libxvid --enable-lzma --enable-libfontconfig --enable-libfreetype --enable-frei0r --enable-libass --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libopenjpeg --enable-libspeex --enable-libsoxr --enable-libzmq --enable-libzimg --disable-libjack --disable-indev=jack --enable-videotoolbox --enable-audiotoolbox --enable-neon
  libavutil      59. 39.100 / 59. 39.100
  libavcodec     61. 19.101 / 61. 19.101
  libavformat    61.  7.100 / 61.  7.100
  libavdevice    61.  3.100 / 61.  3.100
  libavfilter    10.  4.100 / 10.  4.100
  libswscale      8.  3.100 /  8.  3.100
  libswresample   5.  3.100 /  5.  3.100
  libpostproc    58.  3.100 / 58.  3.100
[AVFilterGraph @ 0x123f21c30] No option name near 'min(0,w*(0.5-t)/0.5):0'
[AVFilterGraph @ 0x123f21c30] Error parsing a filter description around: [animated];
        [0:v][animated]overlay=0:0:shortest=1[out];
        [out]split[out1][out2]
[AVFilterGraph @ 0x123f21c30] Error parsing filterchain '[1:v]trim=duration=0.5,setpts=PTS-STARTPTS,format=rgba,
        pad=iw+10:ih+10:(ow-iw)/2:(oh-ih)/2:color=black@0,
        fade=in:st=0:d=0.5,
        translate='min(0,w*(0.5-t)/0.5)':0[animated];
        [0:v][animated]overlay=0:0:shortest=1[out];
        [out]split[out1][out2]' around: [animated];
        [0:v][animated]overlay=0:0:shortest=1[out];
        [out]split[out1][out2]
Failed to set value '[1:v]trim=duration=0.5,setpts=PTS-STARTPTS,format=rgba,
        pad=iw+10:ih+10:(ow-iw)/2:(oh-ih)/2:color=black@0,
        fade=in:st=0:d=0.5,
        translate='min(0,w*(0.5-t)/0.5)':0[animated];
        [0:v][animated]overlay=0:0:shortest=1[out];
        [out]split[out1][out2]' for option 'filter_complex': Invalid argument
Error parsing global options: Invalid argument