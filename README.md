# FFmpegDemo
FFmpeg在iOS上使用实践
网上很多FFmpeg例子教程的API已经给废弃，为了方便新人学习，故写了最新FFmpeg 3.2在iOS上使用的例子
该工程完成 视频文件（output.mp4）获取码流再解码获取像素帧（YUV/RGB）
项目依赖库：FFmpeg 3.2  CoreMedia.framework CoreGraphics.framework AudioToolbox.framework libz.tbd libz2.tbd libiconv.tbd VideoToolbox.framework
该项目目前移除FFmpeg 3.2类库，请自行编译加入FFmpeg3.2再运行
