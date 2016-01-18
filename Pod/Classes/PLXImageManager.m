/*
 Copyright (c) 2013, Antoni Kędracki, Polidea
 All rights reserved.

 mailto: akedracki@gmail.com

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the Polidea nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY ANTONI KĘDRACKI, POLIDEA ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL ANTONI KĘDRACKI, POLIDEA BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PLXImageManager.h"
#import "PLXImageCache.h"
#import "PLXImageManagerLoadOperation.h"
#import "PLXImageManagerOpRunner.h"

@interface PLXImageManager ()

- (id)initWithProvider:(id <PLXImageManagerProvider>)provider cache:(PLXImageCache *)cache ioOpRunner:(PLXImageManagerOpRunner *)ioOpRunner downloadOpRunner:(PLXImageManagerOpRunner *)downloadOpRunner sentinelOpRunner:(PLXImageManagerOpRunner *)sentinelOpRunner;

@end

@interface PLXImageManagerRequestToken ()

- (id)initWithKey:(NSString *)key;

- (void)markReady;

@property(nonatomic, copy, readwrite) void (^onCancelBlock)();

@end

@implementation PLXImageManager {
    PLXImageManagerOpRunner *_ioQueue;
    PLXImageManagerOpRunner *_downloadQueue;
    PLXImageManagerOpRunner *_sentinelQueue;

    PLXImageCache *_imageCache;
    id <PLXImageManagerProvider> _provider;
    NSMutableDictionary *_sentinelDict;
}

- (id)initWithProvider:(id <PLXImageManagerProvider>)provider {
    return [self initWithProvider:provider cache:[PLXImageCache new] ioOpRunner:[PLXImageManagerOpRunner new] downloadOpRunner:[PLXImageManagerOpRunner new] sentinelOpRunner:[PLXImageManagerOpRunner new]];
}

//Note: this constructor is used by tests
- (id)initWithProvider:(id <PLXImageManagerProvider>)provider cache:(PLXImageCache *)cache ioOpRunner:(PLXImageManagerOpRunner *)ioOpRunner downloadOpRunner:(PLXImageManagerOpRunner *)downloadOpRunner sentinelOpRunner:(PLXImageManagerOpRunner *)sentinelOpRunner {
    self = [super init];
    if (self) {
        if (provider == nil) {
            @throw [NSException exceptionWithName:@"InvalidArgumentException" reason:@"A valid provider is missing" userInfo:nil];
        }

        _provider = provider;

        _ioQueue = ioOpRunner;
        _ioQueue.name = @"plximagemanager.io";
        _ioQueue.maxConcurrentOperationsCount = 1;
        _downloadQueue = downloadOpRunner;
        _downloadQueue.name = @"plximagemanager.download";
        _downloadQueue.maxConcurrentOperationsCount = [_provider maxConcurrentDownloadsCount];
        _sentinelQueue = sentinelOpRunner;
        _sentinelQueue.name = @"plximagemanager.sentinel";
        _sentinelQueue.maxConcurrentOperationsCount = _downloadQueue.maxConcurrentOperationsCount;

        _sentinelDict = [NSMutableDictionary new];

        _imageCache = cache;
    }

    return self;
}

- (PLXImageManagerRequestToken *)imageForIdentifier:(id <NSObject>)identifier placeholder:(UIImage *)placeholder callback:(void (^)(UIImage *image, BOOL isPlaceholder))callback {
    Class identifierClass = [_provider identifierClass];
    if (![identifier isKindOfClass:identifierClass]) {
        @throw [NSException exceptionWithName:@"InvalidArgumentException" reason:[NSString stringWithFormat:@"The provided identifier \"%@\" is of a wrong type", identifier] userInfo:nil];
    }

    NSString *const opKey = [_provider keyForIdentifier:identifier];

    PLXImageManagerRequestToken *token = [[PLXImageManagerRequestToken alloc] initWithKey:opKey];

    void (^notifyBlock)(UIImage *, BOOL) = ^(UIImage *image, BOOL isPlaceholder) {
        if (callback == nil) {
            return;
        }
        if ([NSThread currentThread] == [NSThread mainThread]) {
            callback(image, isPlaceholder);
        } else {
            //note: using NSThread would be nicer, but it doesn't support blocks so stick with GCD for now
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(image, isPlaceholder);
            });
        }
    };

    //first: fast memory only cache path
    UIImage *memoryCachedImage = [_imageCache getWithKey:opKey onlyMemoryCache:YES];
    if (memoryCachedImage != nil) {
        [token markReady];
        notifyBlock(memoryCachedImage, NO);
    } else {
        if (placeholder != nil) {
            notifyBlock(placeholder, YES);
        }

        //second: slow paths
        PLXImageManagerLoadOperation *sentinelOp = nil;
        __weak __block PLXImageManagerLoadOperation *weakSentinelOp;
        @synchronized (_sentinelDict) {
            sentinelOp = _sentinelDict[opKey];
            if (sentinelOp == nil) {
                __weak typeof(_provider) weakProvider = _provider;
                __weak typeof(_imageCache) weakImageCache = _imageCache;
                __weak typeof(_ioQueue) weakIOQueue = _ioQueue;
                __weak typeof(_sentinelDict) weakSentinelDict = _sentinelDict;

                __weak __block PLXImageManagerLoadOperation *weakDownloadOperation;
                __weak __block PLXImageManagerLoadOperation *weakFileReadOperation;

                PLXImageManagerLoadOperation *downloadOperation = [[PLXImageManagerLoadOperation alloc] initWithKey:opKey loadBlock:^UIImage * {
                    NSError *error = NULL;
                    UIImage *image = [weakProvider downloadImageWithIdentifier:identifier error:&error];

                    if (error) {
                        NSLog(@"Error downloading image: %@", error);
                        return nil;
                    }

                    return image;
                }];
                weakDownloadOperation = downloadOperation;
                downloadOperation.opId = @"net";

                downloadOperation.readyBlock = ^(UIImage *image) {
                    if (image != nil) {
                        NSBlockOperation *storeOperation = [NSBlockOperation blockOperationWithBlock:^{
                            [weakImageCache set:image forKey:opKey];
                        }];
                        storeOperation.queuePriority = NSOperationQueuePriorityHigh;
                        [weakIOQueue addOperation:storeOperation];
                    }
                };

                PLXImageManagerLoadOperation *fileReadOperation = [[PLXImageManagerLoadOperation alloc] initWithKey:opKey loadBlock:^UIImage * {
                    return [weakImageCache getWithKey:opKey onlyMemoryCache:NO];
                }];
                weakFileReadOperation = fileReadOperation;
                fileReadOperation.opId = @"file";

                fileReadOperation.readyBlock = ^(UIImage *image) {
                    if (image != nil) {
                        [weakDownloadOperation cancel];
                    }
                };

                sentinelOp = [[PLXImageManagerLoadOperation alloc] initWithKey:opKey loadBlock:^UIImage * {
                    if (weakFileReadOperation.image != nil) {
                        return weakFileReadOperation.image;
                    } else if (weakDownloadOperation.image != nil) {
                        return weakDownloadOperation.image;
                    } else {
                        if ([weakFileReadOperation isCancelled] && [weakDownloadOperation isCancelled]) {
                            [weakSentinelOp cancel];
                        }
                        return nil;
                    }
                }];
                sentinelOp.completionBlock = ^{
                    @synchronized (weakSentinelDict) {
                        [weakSentinelDict removeObjectForKey:opKey];
                    }
                };
                sentinelOp.onCancelBlock = ^{
                    @synchronized (weakSentinelDict) {
                        [weakSentinelDict removeObjectForKey:opKey];
                    }
                };
                sentinelOp.opId = @"sentinel";

                [downloadOperation addDependency:fileReadOperation];
                [sentinelOp addDependency:fileReadOperation];
                [sentinelOp addDependency:downloadOperation];

                [_downloadQueue addOperation:downloadOperation];
                [_ioQueue addOperation:fileReadOperation];
                [_sentinelQueue addOperation:sentinelOp];
                _sentinelDict[opKey] = sentinelOp;
            } else {
                [sentinelOp incrementUsage];
            }
            weakSentinelOp = sentinelOp;
        }

        token.onCancelBlock = ^{
            [weakSentinelOp decrementUsageAndCancelOnZero];
        };

        NSBlockOperation *notifyOperation = [NSBlockOperation blockOperationWithBlock:^{
            if (weakSentinelOp.isCancelled) {
                return;
            }
            [token markReady];
            notifyBlock(weakSentinelOp.image, NO);
        }];
        [notifyOperation addDependency:sentinelOp];
        notifyOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
        [_sentinelQueue addOperation:notifyOperation];
    }

    return token;
}

- (void)clearCachedImageForIdentifier:(id <NSObject>)identifier {
    Class identifierClass = [_provider identifierClass];
    if (![identifier isKindOfClass:identifierClass]) {
        @throw [NSException exceptionWithName:@"InvalidArgumentException" reason:[NSString stringWithFormat:@"The provided identifier \"%@\" is of a wrong type", identifier] userInfo:nil];
    }

    NSString *const opKey = [_provider keyForIdentifier:identifier];
    [_imageCache removeImageWithKey:opKey];
}

- (void)clearCache {
    [_imageCache clearMemoryCache];
    [_imageCache clearFileCache];
}

- (void)clearMemoryCache {
    [_imageCache clearMemoryCache];
}

- (void)clearFileCache {
    [_imageCache clearFileCache];
}

- (void)deferCurrentDownloads {
    @synchronized (_sentinelDict) {
        for (PLXImageManagerLoadOperation *op in [_sentinelDict allValues]) {
            for (PLXImageManagerLoadOperation *dependentOp in op.dependencies) {
                dependentOp.queuePriority = NSOperationQueuePriorityLow;
            }
        }
    }
}

- (NSUInteger)memoryCacheCountLimit {
    return _imageCache.memoryCacheCountLimit;
}

- (void)setMemoryCacheCountLimit:(NSUInteger)memoryCacheCountLimit {
    _imageCache.memoryCacheCountLimit = memoryCacheCountLimit;
}

- (NSUInteger)fileCacheTotalSizeLimit {
    return _imageCache.fileCacheTotalSizeLimit;
}

- (void)setFileCacheTotalSizeLimit:(NSUInteger)fileCacheTotalSizeLimit {
    _imageCache.fileCacheTotalSizeLimit = fileCacheTotalSizeLimit;
}

@end

@implementation PLXImageManagerRequestToken {

}

- (id)initWithKey:(NSString *)key {
    self = [super init];
    if (self) {
        _key = key;
        _isCanceled = NO;
        _isReady = NO;
    }
    return self;
}

- (void)markReady {
    if (_isCanceled) {
        return;
    }
    _isReady = YES;
}

- (void)cancel {
    if (_isCanceled || _isReady) {
        return;
    }
    _isCanceled = YES;
    if (_onCancelBlock) {
        _onCancelBlock();
    }
}

@end
