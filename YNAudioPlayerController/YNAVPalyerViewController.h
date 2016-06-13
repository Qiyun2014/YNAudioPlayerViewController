//
//  YNAVPalyerViewController.h
//  YNAudioPlayerController
//
//  Created by qiyun on 16/6/13.
//  Copyright © 2016年 qiyun. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface YNAVPalyerViewController : UIViewController

@end


@interface YNImageInsertToAudio : NSObject

/* 将一张图片转化成一帧的格式 */
- (CVPixelBufferRef)pixelBufferFromCGImage: (CGImageRef)image andSize:(CGSize) size;

/* 将图片写入到视频中，并设置其大小和显示的帧率 */
- (void)writeImages:(NSArray *)imagesArray ToMovieAtPath:(NSString *)path withSize:(CGSize) size
         inDuration:(float)duration byFPS:(int32_t)fps;

/* 多张图片合成一段视频 */
- (void)compressionSessionWithImages:(NSArray *)images;

@end