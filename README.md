# downloadManager
## 中文
- 支持断点续传，你只需要传入一个url就可以在下载过程中返回一个下载进度，下载完之后，返回一个下载路径，如果失败也会返回一个错误
- 调用方法

```objc

- (void)downloadWithURL:(NSURL *)url
               progress:(SAMDownloadManagerProgressBlock)progressBlock
             completion:(SAMDownloadManagerCompletionBlock)completionBlock
```

## English
- Support breakpoint continuingly, you only need to pass in a url can return a download progress in the process of download, download finished, return to a download path, if failure will return an error
- A method is called

```objc

- (void)downloadWithURL:(NSURL *)url
               progress:(SAMDownloadManagerProgressBlock)progressBlock
             completion:(SAMDownloadManagerCompletionBlock)completionBlock

```