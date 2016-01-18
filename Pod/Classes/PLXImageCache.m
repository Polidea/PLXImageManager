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

#import "PLXImageCache.h"
#import <CommonCrypto/CommonDigest.h>

@interface PLXImageCache ()

- (id)initWithCache:(NSCache *)cache fileManager:(NSFileManager *)manager;

- (NSString *)filePathForKey:(NSString *)key;
- (void)validateKey:(NSString *)key;
- (NSURL *)imageCacheDirectory;

@end

@implementation PLXImageCache {
@private
    NSCache *_memoryCache;
    NSFileManager *_fileManager;
}

- (id)init {
    NSCache *cache = [[NSCache alloc] init];
    cache.name = @"PLXImageCache";
    cache.countLimit = 25;
    return [self initWithCache:cache fileManager:[NSFileManager defaultManager]];
}

- (id)initWithCache:(NSCache *)cache fileManager:(NSFileManager *)manager {
    self = [super init];
    if (self) {
        _fileManager = manager;
        _memoryCache = cache;
    }

    return self;
}

- (UIImage *)getWithKey:(NSString *)key onlyMemoryCache:(BOOL)onlyMemory {
    [self validateKey:key];

    NSString *filePath = [self filePathForKey:key];

    UIImage *image = [_memoryCache objectForKey:key];
    if (image == nil && !onlyMemory) {
        image = [UIImage imageWithContentsOfFile:filePath];
        if (image != nil) {
            [_memoryCache setObject:image forKey:key];
        }
    }

    return image;
}

- (void)set:(UIImage *)image forKey:(NSString *)key {
    [self validateKey:key];

    NSString *filePath = [self filePathForKey:key];

    if (image == nil) {
        [_memoryCache removeObjectForKey:key];
        if ([_fileManager fileExistsAtPath:filePath]) {
            [_fileManager removeItemAtPath:filePath error:NULL];
        }

    } else {
        [_memoryCache setObject:image forKey:key];
        [_fileManager createFileAtPath:filePath contents:UIImagePNGRepresentation(image) attributes:nil];
    }
}

- (void)removeImageWithKey:(NSString *)key {
    [self set:nil forKey:key];
}

- (void)clearMemoryCache {
    [_memoryCache removeAllObjects];
}

- (void)clearFileCache {
    [_fileManager removeItemAtPath:[[self imageCacheDirectory] path] error:nil];
}

-(NSUInteger)memoryCacheSizeLimit {
    return _memoryCache.countLimit;
}

-(void)setMemoryCacheSizeLimit:(NSUInteger)memoryCacheSizeLimit {
    _memoryCache.countLimit = memoryCacheSizeLimit;
}

#pragma mark internal helpers

- (NSString *)filePathForKey:(NSString *)key {
    return [[[self imageCacheDirectory] URLByAppendingPathComponent:[self _sha1HashOfString:key]] path];
}

- (void)validateKey:(NSString *)key {
    if (key == nil) {
        @throw [NSException exceptionWithName:@"InvalidArgumentException" reason:[NSString stringWithFormat:@"The provided key \"%@\" is not valid", key] userInfo:nil];
    }
}

- (NSURL *)imageCacheDirectory {
    static NSURL *cacheDirectory;
    if (cacheDirectory == nil) {
        NSArray *urls = [_fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
        NSURL *libraryUrl = [urls count] > 0 ? urls[0] : nil;

        if (libraryUrl != nil) {
            cacheDirectory = [[libraryUrl URLByAppendingPathComponent:@"Caches"] URLByAppendingPathComponent:@"PLXImageCache"];
            [_fileManager createDirectoryAtPath:[cacheDirectory path] withIntermediateDirectories:YES attributes:nil error:NULL];
        }
    }
    return cacheDirectory;
}

- (NSString *)_sha1HashOfString:(NSString *)string {
    const char *str = [string UTF8String];
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(str, (uint32_t) strlen(str), result);

    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x", result[i]];
    }
    return ret;
}

@end