//
//  ViewController.m
//  downloadDemo
//
//  Created by 杨森 on 15/7/17.
//  Copyright (c) 2015年 samyang. All rights reserved.
//

#import "ViewController.h"
#import "SAMDownloadManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    SAMDownloadManager *download = [SAMDownloadManager sharedDownloadManager];
    
    NSURL *url = [NSURL URLWithString:@"http://120.25.226.186:32812/resources/videos/minion_01.mp4"];
    
    [download downloadWithURL:url progress:^(CGFloat progress) {
        // 下载进度
        NSLog(@"progress-------%f", progress);
        
    } completion:^(NSError *error, NSString *filePath) {
        
        
    }];
}

@end
