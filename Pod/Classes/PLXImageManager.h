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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class PLXImageCache;
@protocol PLXImageManagerProvider;
@class PLXImageManagerRequestToken;

/**
PLXImageManager is a sophisticated and extensible image manager. It covers the part of the job that is common for most use cases.
The responsibility for the 'other' part is left to a PLXImageManagerProvider (a constructor argument).

It implements a asynchronous interface using a callback, with a optional 'placeholder' image argument. The callback is always called on the main thread.

There are three main paths of execution:

1. fast memory cache path: if the requested image is available in memory, it will be delivered immediately (still using the callback)
2. file cache path: if available from flash memory, it will be loaded and delivered asynchronously.
3. network path: in the worst case it will be downloaded, stored, and delivered asynchronously.

The underlying thread schema assures that:

1. no more then ONE IO operation is performed at once. This is to prevent the IO from degrading the main thread performance.
2. downloads are performed in parallel on up to maxConcurrentDownloadsCount threads (value taken from PLXImageManagerProvider).
3. multiple requests for the same image are handled by a single download.
*/
@interface PLXImageManager : NSObject

- (id)initWithProvider:(id <PLXImageManagerProvider>)provider;

/**
Requests a image.

Depending on the availability of the image the placeholder will be called:

1. fast memory cache path: synchronously with the method call.
2. file cache path and network path: asynchronously when the image is available. Additionally, if a placeholder is provided, the callback will be called synchronously with it before returning from the method.
3. in case of error the callback will be called with nil as the image parameter.
4. on error: the callback will be called with nil and isPlaceholder set to NO.

@param identifier a identifier that uniquely represents the image

@param placeholder optional image that will be used with the callback for "slow" path scenarios. Providing nil will disable this behaviour

@param callback used to report request progress

@return token that can be used to cancel the request. See [PLXImageManagerRequestToken cancel] for more info

@exception InvalidArgumentException if the provided identifier has a type other then [PLXImageManagerProvider identifierClass]

*/
- (PLXImageManagerRequestToken *)imageForIdentifier:(id <NSObject>)identifier placeholder:(UIImage *)placeholder callback:(void (^)(UIImage *image, BOOL isPlaceholder))callback;

/**
Remove a image represented by identifier from the cache. Note: this performs a IO operation, and therefor should not be called from the main thread.

@param identifier a identifier that uniquely represents the image

@exception InvalidArgumentException if the provided identifier has a type other then [PLXImageManagerProvider identifierClass]
*/
- (void)clearCachedImageForIdentifier:(id <NSObject>)identifier;

/**
Removes all cached images. Note: this performs a IO operation, and therefor should not be called from the main thread.
*/
- (void)clearCache DEPRECATED_ATTRIBUTE;

/**
 Clears the contents of the in-memory cache. This method can be run from the main-thread.
 */
-(void) clearMemoryCache;

/**
 Clears the contents of the file cache. Note: this performs a IO operation, and therefor should not be called from the main thread.
 */
-(void) clearFileCache;

/**
Calling this method will lower the priority of all previously scheduled requests. As a result new requests
(and subsequent calls to already scheduled ones) will be handled first.
*/
- (void)deferCurrentDownloads;

/**
 Limits the amount of items that will be stored in the in-memory cache. A value of 0 means there is no limit. Defaults to 25.
 */
@property (nonatomic, assign, readwrite) NSUInteger memoryCacheCountLimit;

/**
 Limits the amount of space (in mega-bytes) that will be used for the file cache. A value of 0 means there is not limit. Defaults to 150MB.

 Note: Once the size limit is reached, the least-recent files will be removed, until a the cache holds around 3/4 the limit of images.
 */
@property (nonatomic, assign, readwrite) NSUInteger fileCacheTotalSizeLimit;

@end

/**
A hook for PLXImageManager, used to provide all use case specific data.
*/
@protocol PLXImageManagerProvider <NSObject>
@required

/**
maxConcurrentDownloadsCount controls how many threads will be used to download images. Note: a high value can
significantly slow down the whole application.
*/
- (NSUInteger)maxConcurrentDownloadsCount;

/**
Used at runtime to validate the identifiers provided to the PLXImageManager methods.
*/
- (Class)identifierClass;

/**
As PLXImageManager is identifier type agnostic, it's up to the PLXImageManagerProvider to provide a key for internal use.
*/
- (NSString *)keyForIdentifier:(id <NSObject>)identifier;

/**
Should perform the actual download of the image for identifier. As a rule, this method should block until it returns.
*/
- (UIImage *)downloadImageWithIdentifier:(id <NSObject>)identifier error:(NSError **)error;

@end

/**
Represents a concrete request for a image. It allows tracking of the progress, and canceling the request.
*/
@interface PLXImageManagerRequestToken : NSObject

@property (nonatomic, strong, readonly) NSString * key;
@property (nonatomic, assign, readonly) BOOL isCanceled;
@property (nonatomic, assign, readonly) BOOL isReady;

/**
Cancels the exact request for a image this token was returned for. The processing of the image will be canceled if all
request for it has been canceled.
*/
-(void) cancel;

@end