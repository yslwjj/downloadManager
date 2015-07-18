//
//  SAMDownloadManager.m
//  大文件断点下载
//
//  Created by 杨森 on 15/7/17.
//  Copyright (c) 2015年 samyang. All rights reserved.
//

#import "SAMDownloadManager.h"
#import "NSString+Hash.h"


// 文件的存放路径
#define SAMDownloadFilePath(name) [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:name]

// 存储文件总长度的文件路径(caches)
#define SAMTotalLengthFullpath [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"totalLength.plist"]

// 存储是否下载的文件路径(caches)
#define SAMIsDownloadFullpath [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"isDownload.plist"]

// 文件的已下载长度
#define SAMDownloadLength(name) [[[NSFileManager defaultManager] attributesOfItemAtPath:SAMDownloadFilePath(name) error:nil][NSFileSize] integerValue]


@interface SAMDownloadManager ()<NSURLSessionDataDelegate>

/** session */
@property (nonatomic, strong) NSURLSession *session;

/** 下载任务 */
@property (nonatomic, strong) NSURLSessionDataTask *task;

/** 写文件的流对象 */
@property (nonatomic, strong) NSOutputStream *stream;

/** 文件的总长度 */
@property (nonatomic, assign) NSInteger totalLength;

/** 记录传进来的url */
@property (nonatomic, strong) NSURL *downloadURL;

/** 沙盒中的文件名 */
@property (nonatomic, copy) NSString *fileName;

/** 文件名类型 */
@property (nonatomic, strong) NSString *type;

@end

@implementation SAMDownloadManager

/**
 *  单例构造对象方法
 */
SAMSingletonM(DownloadManager)


#pragma mark - 重写url的set方法，给存入沙盒的文件名赋值

- (void)setDownloadURL:(NSURL *)downloadURL
{
    _downloadURL = downloadURL;
    self.fileName = downloadURL.absoluteString.md5String;
}


#pragma mark - 传入一个URL下载过程中返回下载进度，完成之后返回下载路径
- (void)downloadWithURL:(NSURL *)url progress:(SAMDownloadManagerProgressBlock)progressBlock completion:(SAMDownloadManagerCompletionBlock)completionBlock
{
    self.downloadURL = url;
    [self.task resume];
    
    self.callProgressBlock =^(CGFloat progress){
        progressBlock(progress);
    };
    
    self.callCompletionBlock =^(NSError *error, NSString *filePath){
        completionBlock(error, filePath);
    };
}



- (NSURLSession *)session
{
    if (_session == nil) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    }
    return _session;
}



- (NSOutputStream *)stream
{
    if (!_stream) {
        _stream = [NSOutputStream outputStreamToFileAtPath:SAMDownloadFilePath(self.fileName) append:YES];
    }
    return _stream;
}



- (NSURLSessionDataTask *)task
{
    if (!_task) {
        NSInteger totalLength = [[NSDictionary dictionaryWithContentsOfFile:SAMTotalLengthFullpath][self.fileName] integerValue];
        // 判断文件是否已经下载，（排除一开始都为0的情况下）
        
        BOOL isDownload = [NSDictionary dictionaryWithContentsOfFile:SAMIsDownloadFullpath][self.fileName];
        if (isDownload) {
            NSLog(@"File has been downloaded");
            return nil;
        }
        if (totalLength && SAMDownloadLength(self.fileName) == totalLength){
            NSLog(@"File has been downloaded");
            return nil;
        }
        
        // 创建请求
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.downloadURL];
        // 设置请求头
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-", SAMDownloadLength(self.fileName)];
        [request setValue:range forHTTPHeaderField:@"Range"];
        //创建一个Data任务
        _task = [self.session dataTaskWithRequest:request];
    }
    
    return _task;
}



#pragma mark - <NSURLSessionDataDelegate>
/**
 *  接收到响应,
 *  此处要使用(NSHTTPURLResponse *)response，response真实类型就是NSHTTPURLResponse
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    // 打开流
    [self.stream open];
    
    NSLog(@"%@",response.allHeaderFields);
    
    // 获得服务器这次请求，返回数据的总长度
    self.totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + SAMDownloadLength(self.fileName);
    // 取出文件类型
    self.type = [[response.allHeaderFields[@"Content-Type"] componentsSeparatedByString:@"/"] lastObject];
    
    // 存储总长度
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:SAMTotalLengthFullpath];
    if (dict == nil) {
        dict = [NSMutableDictionary dictionary];
    }
    // 以文件名key,总长度为value
    dict[self.fileName] = @(self.totalLength);
    [dict writeToFile:SAMTotalLengthFullpath atomically:YES];
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}



/**
 *  接收到服务器返回的数据（这个方法可能会被调用N次）
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{ 
    // 写入数据
    [self.stream write:data.bytes maxLength:data.length];
    CGFloat progress = 1.0 * SAMDownloadLength(self.fileName) / self.totalLength;
    self.callProgressBlock(progress);
}



/**
 *  请求结束（成功、失败都会调用）
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if ( SAMDownloadLength(self.fileName) == _totalLength) {
        // 存储是否已经下载
        NSMutableDictionary *typeDict = [NSMutableDictionary dictionaryWithContentsOfFile:SAMIsDownloadFullpath];
        if (typeDict == nil) {
            typeDict = [NSMutableDictionary dictionary];
        }
        // 以文件名key,value为是否已经下载
        typeDict[self.fileName] = @YES;
        [typeDict writeToFile:SAMIsDownloadFullpath atomically:YES];
        
        // 把文件转换成相应的格式
        NSString *finalFileName = [NSString stringWithFormat:@"%@.%@",self.fileName,_type];
        NSFileManager *mgr = [NSFileManager defaultManager];
        // 下载完成之后转成相应格式
        [mgr moveItemAtPath:SAMDownloadFilePath(_fileName) toPath:SAMDownloadFilePath(finalFileName) error:nil];
        
        // 回调block
        self.callCompletionBlock(error,SAMDownloadFilePath(self.fileName));
    }
    
    //关闭流
    [self.stream close];
    self.stream = nil;
    
    // 清除任务
    self.task = nil;
}


@end
