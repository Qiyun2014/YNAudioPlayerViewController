//
//  ViewController.m
//  YNAudioPlayerController
//
//  Created by qiyun on 16/6/13.
//  Copyright © 2016年 qiyun. All rights reserved.
//

#import "ViewController.h"
#import "YNAVPalyerViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:[[YNAVPalyerViewController alloc] init]];
        [self presentViewController:navi animated:YES completion:^{
            
        }];
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
