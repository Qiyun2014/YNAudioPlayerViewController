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

/* 将一张图片转化成一帧的格式
 * 从image到CVPixelBuffer需要注意性能，如果使用context的话和使用memcpy都有一样的性能支出;
 * 但是使用CVPixelBufferCreateWithBytes这个可以在时间上提高好几个数量级别，这是因为这里没有渲染也没有内存拷贝能耗时的操作而只是将data的指针进行了修改。
 */
- (CVPixelBufferRef)pixelBufferFromCGImage: (CGImageRef)image andSize:(CGSize) size;
- (CVPixelBufferRef)pixelBufferFromCGImageWithPool:(CVPixelBufferPoolRef)pixelBufferPool sourceImage:(CGImageRef)sourceImage;



/* 将图片写入到视频中，并设置其大小和显示的帧率 */
- (void)writeImages:(NSArray *)imagesArray
      ToMovieAtPath:(NSString *)path
           withSize:(CGSize) size
         inDuration:(float)duration
              byFPS:(int32_t)fps;



/* 多张图片合成一段视频 */
- (void)compressionSessionWithImages:(NSArray *)images;



@end