//
//  YNAVPalyerViewController.m
//  YNAudioPlayerController
//
//  Created by qiyun on 16/6/13.
//  Copyright © 2016年 qiyun. All rights reserved.
//

#import "YNAVPalyerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/PHAssetChangeRequest.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVKit/AVPlayerViewController.h>

@interface YNAVPalyerViewController ()<AVCaptureFileOutputRecordingDelegate,UIVideoEditorControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, strong) AVCaptureMovieFileOutput  *videoOutput;
@property (nonatomic, strong) AVPlayerViewController    *avMoviePlayer;
@property (nonatomic, strong) UIVideoEditorController   *videoEditorController;

@end

@implementation YNAVPalyerViewController

#pragma mark    -   video edit

/**
 *  视频编辑控制器
 *
 *  @discussion 可以对视频进行画质设置，最长时间设置及视频片段剪切（有的视频不支持编辑，需要进行识别）
 *  @brief path->视频的路径
 */
- (UIVideoEditorController *)videoEditorController{
    
    NSString *filePath = [[self createFile] stringByAppendingString:[NSString stringWithFormat:@"/%@.mp4",@"我的视频"]];
    if (![UIVideoEditorController canEditVideoAtPath:filePath]) return nil;
    
    if (!_videoEditorController) {
        
        _videoEditorController = [[UIVideoEditorController alloc] init];
        _videoEditorController.delegate     = self;
        _videoEditorController.videoPath    = filePath;
        _videoEditorController.videoMaximumDuration = 20.0f;
        /* 高，普通，低（默认是高品质的视频），还可以调节分辨率 */
        _videoEditorController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    }
    
    return _videoEditorController;
}

#pragma mark    -   video play

/**
 *  AVPlayerViewController视频播放器
 *
 *  @discussion AVPlayerViewController不支持编辑模式，可以自定制的空间很少；如果自定义的话，需要针对player层进行设置；
 *
 *  --->        iOS9之后MPMoviePlayer已经被此控制器替代，这是苹果目前为止唯一兼容ios9之后的播放器，缺陷是最低支持iOS8
 */
- (AVPlayerViewController *)avMoviePlayer{
    
    if (!_avMoviePlayer) {
        
        _avMoviePlayer = [[AVPlayerViewController alloc] init];
        _avMoviePlayer.view.frame = self.view.frame;
        _avMoviePlayer.player = [AVPlayer playerWithURL:
                                 [NSURL fileURLWithPath:[[self createFile]
                                                         stringByAppendingString:[NSString stringWithFormat:@"/%@.mp4",@"我的视频"]]]];
        
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
    return _avMoviePlayer;
}


#pragma mark    -   video recording

/**
 *  视频录制（视频图像捕捉）
 *  
 *  @discussion 需要创建视频捕捉器的对象，及截取容器（视、音频输入，视、音频输出）,然后对图像进行输出保存
 *
 *  保存后的文件可以自定义视频格式，进行读取操作
 */
- (AVCaptureMovieFileOutput *)videoOutput{
    
    if (!_videoOutput) {
        
        _videoOutput = [[AVCaptureMovieFileOutput alloc] init];
        
        AVCaptureSession *session = [[AVCaptureSession alloc] init];
        AVCaptureDevice *device;    /* ios9之后，次对象不支持实例化，只做对象申请地址空间，不做引用 */
        AVCaptureStillImageOutput *imageOutput = [[AVCaptureStillImageOutput alloc] init];
        
        NSArray *devices = [AVCaptureDevice devices];
        NSArray *audioCaptureDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];  /* 媒体类型 */
        AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice.firstObject error:nil]; /* 视频输出类型实例化 */
        
        for (AVCaptureDevice *aDevice in devices){
            
            if (aDevice.position == AVCaptureDevicePositionBack) {
                device = aDevice;
            }
        }
        
        AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
        [session addInput:videoInput];
        [session addInput:audioInput];
        [session addOutput:imageOutput];    /* save images */
        [session addOutput:_videoOutput];
        
        AVCaptureVideoPreviewLayer *videoPlayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
        videoPlayer.frame = self.view.bounds;
        videoPlayer.videoGravity = AVLayerVideoGravityResizeAspectFill; /* 视频边界 */
        [self.view.layer addSublayer:videoPlayer];
        
        [session startRunning];
    }
    return _videoOutput;
}

#pragma mark    -   system delegate


- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    
    NSLog(@"didStartRecordingToOutputFileAtURL");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{

#if 0
    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputFileURL];
#else
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
    [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"保存视频到相簿过程中发生错误，错误信息：%@",error.localizedDescription);
        }

        NSLog(@"成功保存视频到相簿.");
    }];
#endif
}


- (void)videoEditorController:(UIVideoEditorController *)editor didSaveEditedVideoToPath:(NSString *)editedVideoPath // edited video is saved to a path in app's temporary directory
{
    /* mov格式 */
    NSLog(@"视频保存的路径  %@",editedVideoPath);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)videoEditorController:(UIVideoEditorController *)editor didFailWithError:(NSError *)error{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)videoEditorControllerDidCancel:(UIVideoEditorController *)editor{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark    -   life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIBarButtonItem *startItem = [[UIBarButtonItem alloc] initWithTitle:@"开始"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(startAction:)];
    self.navigationItem.rightBarButtonItem = startItem;
    
    UIBarButtonItem *stopItem = [[UIBarButtonItem alloc] initWithTitle:@"停止"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(stopAction:)];
    self.navigationItem.leftBarButtonItem = stopItem;
    
    /*
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self addChildViewController:self.avMoviePlayer];
        [self.view addSubview:self.avMoviePlayer.view];
    });
     */
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (self.videoEditorController) {
            
            [self presentViewController:self.videoEditorController animated:YES completion:^{
                
            }];
        }else NSLog(@"不支持编辑视频");
    });
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark    -   private method

- (NSString *)createFile{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *testDirectory = [documentsDirectory stringByAppendingPathComponent:@"test"];
    
    //创建目录
    BOOL success = [fileManager createDirectoryAtPath:testDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    NSLog(@"success = %@",success?@"创建成功":@"创建失败");
    return testDirectory;
}

- (void)stopAction:(UIBarButtonItem *)item{
    
    [self.videoOutput stopRecording];
}

- (void)startAction:(UIBarButtonItem *)item{
    
    NSString *fileName = [[self createFile] stringByAppendingString:[NSString stringWithFormat:@"/%@.mp4",[[NSDate date] description]]];
    [self.videoOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:fileName] recordingDelegate:self];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end


#pragma mark    -   YNImageInsertToAudio

@implementation YNImageInsertToAudio

- (CVPixelBufferRef)pixelBufferFromCGImage: (CGImageRef)image andSize:(CGSize) size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
                                          size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}


- (CVPixelBufferRef)pixelBufferFromCGImageWithPool:(CVPixelBufferPoolRef)pixelBufferPool sourceImage:(CGImageRef)sourceImage
{
    
    CVPixelBufferRef pxbuffer = NULL;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    size_t width =  CGImageGetWidth(sourceImage);
    size_t height = CGImageGetHeight(sourceImage);
    size_t bytesPerRow = CGImageGetBytesPerRow(sourceImage);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(sourceImage);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(sourceImage);
    void *pxdata = NULL;
    
    if (pixelBufferPool == NULL)
        NSLog(@"pixelBufferPool is null!");
    
    CVReturn status = CVPixelBufferPoolCreatePixelBuffer (NULL, pixelBufferPool, &pxbuffer);
    if (pxbuffer == NULL) {
        status = CVPixelBufferCreate(kCFAllocatorDefault, width,
                                     height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                     &pxbuffer);
    }
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    NSParameterAssert(pxdata != NULL);
    
    if(/* DISABLES CODE */ (1)){
        
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(pxdata, width,
                                                     height,bitsPerComponent,bytesPerRow, rgbColorSpace,
                                                     bitmapInfo);
        NSParameterAssert(context);
        CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
        CGContextDrawImage(context, CGRectMake(0, 0, width,height), sourceImage);
        CGColorSpaceRelease(rgbColorSpace);
        CGContextRelease(context);
    }else{
        
        
        CFDataRef  dataFromImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(sourceImage));
        CFIndex length = CFDataGetLength(dataFromImageDataProvider);
        GLubyte  *imageData = (GLubyte *)CFDataGetBytePtr(dataFromImageDataProvider);
        memcpy(pxdata,imageData,length);
        
        CFRelease(dataFromImageDataProvider);
    }
    
    return pxbuffer;
}


- (void)writeImages:(NSArray *)imagesArray ToMovieAtPath:(NSString *)path withSize:(CGSize) size
          inDuration:(float)duration byFPS:(int32_t)fps{
    
    //Wire the writer:
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                            fileType:AVFileTypeQuickTimeMovie
                                                               error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                             assetWriterInputWithMediaType:AVMediaTypeVideo
                                             outputSettings:videoSettings];
    
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    [videoWriter addInput:videoWriterInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //Write some samples:
    CVPixelBufferRef buffer = NULL;
    
    int frameCount = 0;
    
    NSInteger imagesCount = [imagesArray count];
    float averageTime = duration/imagesCount;
    int averageFrame = (int)(averageTime * fps);
    
    for(UIImage * img in imagesArray)
    {
        buffer = [self pixelBufferFromCGImage:[img CGImage] andSize:size];
        
        BOOL append_ok = NO;
        int j = 0;
        while (!append_ok && j < 30)
        {
            if (adaptor.assetWriterInput.readyForMoreMediaData)
            {
                printf("appending %d attemp %d\n", frameCount, j);
                
                /* CMTimeMake(a,b)    a当前第几帧, b每秒钟多少帧.当前播放时间a/b */
                CMTime frameTime = CMTimeMake(frameCount,(int32_t) fps);
                float frameSeconds = CMTimeGetSeconds(frameTime);
                NSLog(@"frameCount:%d,kRecordingFPS:%d,frameSeconds:%f",frameCount,fps,frameSeconds);
                append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                
                if(buffer)
                    [NSThread sleepForTimeInterval:0.05];
            }
            else
            {
                printf("adaptor not ready %d, %d\n", frameCount, j);
                [NSThread sleepForTimeInterval:0.1];
            }
            j++;
        }
        if (!append_ok) {
            printf("error appending image %d times %d\n", frameCount, j);
        }
        
        frameCount = frameCount + averageFrame;
    }
    
    //Finish the session:
    [videoWriterInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        
    }];
    NSLog(@"finishWriting");
}

- (void)compressionSessionWithImages:(NSArray *)images
{
    NSString *moviePath = [[NSBundle mainBundle] pathForResource:@"视频" ofType:@"mp4"];
    CGSize size = CGSizeMake(320,400);//定义视频的大小
    NSError *error = nil;
    
    NSString *betaCompressionDirectory = moviePath;
    
    /* 删除文件 */
    //unlink([betaCompressionDirectory UTF8String]);
    
    //—-initialize compression engine
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:betaCompressionDirectory]
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(videoWriter);
    if(error)
        NSLog(@"error = %@", [error localizedDescription]);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey, nil];
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    
    /* 是否可以合成文件 */
    if ([videoWriter canAddInput:writerInput]) NSLog(@"可以合成文件");
    else  NSLog(@"不可以合成文件");
    
    [videoWriter addInput:writerInput];
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //合成多张图片为一个视频文件
    dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);
    int __block frame = 0;
    
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        
        while ([writerInput isReadyForMoreMediaData])
        {
            if(++frame >= [images count]*10)
            {
                [writerInput markAsFinished];
                [videoWriter finishWritingWithCompletionHandler:^{
                    
                }];
                break;
            }
            
            CVPixelBufferRef buffer = NULL;
            
            int idx = frame/10;
            
            buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:[[images objectAtIndex:idx] CGImage] andSize:size];
            
            if (buffer)
            {
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame, 10)])
                    NSLog(@"FAIL");
                else
                    CFRelease(buffer);
            }
        }
    }];
}

/* Writing video and audio via AVAssetWriter */
- (void)writingVideoOfAssetWriter{
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:@"file://user/local"] options:nil];

    AVMutableMetadataItem *newItem = [[AVMutableMetadataItem alloc] init];
    newItem.identifier = AVMetadataIdentifierQuickTimeMetadataLocationISO6709;
    newItem.dataType = AVMetadataIdentifierQuickTimeMetadataLocationISO6709;
    newItem.duration = asset.duration;
    newItem.value = @"location:湖北武汉";
    
    
}

@end


