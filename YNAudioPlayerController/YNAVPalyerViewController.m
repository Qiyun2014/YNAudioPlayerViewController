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
