//
//  SAMDownloadManager.h
//  大文件断点下载
//
//  Created by 杨森 on 15/7/17.
//  Copyright (c) 2015年 samyang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SAMSingleton.h"

@class SAMDownloadManager;

typedef void(^SAMDownloadManagerProgressBlock)(CGFloat progress);


typedef void(^SAMDownloadManagerCompletionBlock)(NSError *error, NSString *filePath);

@interface SAMDownloadManager : NSObject

/**
 *  单例构造对象方法
 */
SAMSingletonH(DownloadManager)

/** call progressBlock */
@property (nonatomic, strong) SAMDownloadManagerProgressBlock callProgressBlock;
/** call completionBlock */
@property (nonatomic, strong) SAMDownloadManagerCompletionBlock callCompletionBlock;



- (void)downloadWithURL:(NSURL *)url
               progress:(SAMDownloadManagerProgressBlock)progressBlock
             completion:(SAMDownloadManagerCompletionBlock)completionBlock
                            ;
@end
