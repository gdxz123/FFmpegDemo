//
//  ViewController.m
//  FFmpegDemo
//
//  Created by gdxz on 17/2/27.
//  Copyright © 2017年 gdxz. All rights reserved.
//

#import "ViewController.h"
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //封装格式<-(封装)->视频流<-(编解码)－>像素数据
    
    //初始化需要使用的对象
    AVFormatContext *qFormatCtx = NULL;      //封装格式上下文
    AVCodecContext *qCodeCtx = NULL;         //解析器上下文
    AVCodec *qCodec = NULL;                  //解析器
    AVPacket qPacket;                        //流数据 类型枚举见AVCodecID
    AVFrame *qFrame = NULL;                  //像素数据YUV
    AVFrame *qFrameRGB = NULL;               //像素数据RGB
    struct SwsContext *qSwsCtx;              //数据处理上下文
    uint8_t *buffer = NULL;                  //buffer数据
    
    //获取文件路径
    const char *filePath = [[[NSBundle mainBundle] pathForResource:@"output" ofType:@"mp4"] UTF8String];
    if (filePath == nil) {
        NSLog(@"文件路径无效");
        return;
    }
    //注册FFmpeg组件
    av_register_all();
    //打开音视频文件
    if (avformat_open_input(&qFormatCtx, filePath, NULL, NULL) != 0) {
        NSLog(@"FFmpeg打开视频文件失败");
        return;
    }
    //获取音视频文件流信息
    if (avformat_find_stream_info(qFormatCtx, NULL) < 0) {
        NSLog(@"找不到流信息");
        return;
    }
    //Dump视频文件信息
    av_dump_format(qFormatCtx, 0, filePath, 0);
    
    //寻找视频流index
    //原来的codec方法已废弃，使用codecpar代替
    int videoStream = -1;
    for (int i = 0;i < qFormatCtx->nb_streams;i++) {
        if (qFormatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStream = i;
            break;
        }
    }
    if (videoStream == -1) {
        NSLog(@"该文件没有找到视频流");
        return;
    }
    
    //获取解析器上下文指针,codec已废弃
    qCodeCtx = avcodec_alloc_context3(NULL);
    if (avcodec_parameters_to_context(qCodeCtx, qFormatCtx->streams[videoStream]->codecpar) < 0) {
        NSLog(@"获取解析器上下文指针失败");
        return;
    }
    qCodec = avcodec_find_decoder(qCodeCtx->codec_id);
    if (qCodeCtx == NULL) {
        NSLog(@"不支持的解码格式");
        return;
    }
    if (avcodec_open2(qCodeCtx, qCodec, NULL) < 0) {
        NSLog(@"打开解析器失败");
        return;
    }
    
    //创建视频像素帧
    qFrame = av_frame_alloc();
    qFrameRGB = av_frame_alloc();//AVPicture已废弃
    if (qFrame == NULL || qFrameRGB == NULL) {
        NSLog(@"创建像素帧失败");
        return;
    }
    //获取buffer字节大小
    int numBytes = av_image_get_buffer_size(AV_PIX_FMT_RGB24, qCodeCtx->width, qCodeCtx->height, 1);
    //创建并获取buffer
    buffer = (uint8_t *)av_malloc(numBytes * sizeof(uint8_t));
    av_image_fill_arrays(qFrameRGB->data, qFrameRGB->linesize, buffer, AV_PIX_FMT_RGB24, qCodeCtx->width, qCodeCtx->height, 1);
    qSwsCtx = sws_getContext(qCodeCtx->width, qCodeCtx->height, qCodeCtx->pix_fmt, qCodeCtx->width, qCodeCtx->height, AV_PIX_FMT_RGB24, SWS_BILINEAR, NULL, NULL, NULL);
    //读取视频帧
    while (av_read_frame(qFormatCtx, &qPacket) >= 0) {
        if (qPacket.stream_index == videoStream) {
            //解码视频帧
            //avcodec_decode_video2 已废弃。使用avcodec_send_packet和avcodec_receive_frame代替
            int ret = avcodec_send_packet(qCodeCtx, &qPacket);
            if (ret < 0) {
                NSLog(@"获取该帧流文件失败");
                return;
            }
            ret = avcodec_receive_frame(qCodeCtx, qFrame);
            if (ret != AVERROR_EOF) {
                //将像素帧数据转化为RGB格式
                sws_scale(qSwsCtx, (uint8_t const * const *)qFrame->data, qFrame->linesize, 0, qCodeCtx->height, qFrameRGB->data, qFrameRGB->linesize);
                /*
                    获取到RGB像素帧进行自己想要的操作
                */
            }
        }
        //释放qPacket, av_free_packet 已废弃
        av_packet_unref(&qPacket);
    }
    //释放对象
    av_free(buffer);
    av_frame_free(&qFrameRGB);
    av_frame_free(&qFrame);
    avcodec_close(qCodeCtx);
    avformat_close_input(&qFormatCtx);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end























