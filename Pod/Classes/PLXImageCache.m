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
    NSUInteger _totalFileCacheSize;
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
        _totalFileCacheSize = NSUIntegerMax;
        _fileCacheTotalSizeLimit = 150;
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

            // little hack: as we can't retrieve the access data of a file, we use the modification date, and update it manually every time we access the file
            NSDate *date = [NSDate date];
            NSURL *url = [NSURL fileURLWithPath:filePath];
            [url setResourceValue:date forKey:NSURLContentModificationDateKey error:NULL];
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
            if (_totalFileCacheSize != NSUIntegerMax) {
                _totalFileCacheSize -= [self sizeOfFileAtPath:filePath];
            }
            [_fileManager removeItemAtPath:filePath error:NULL];
        }

    } else {
        [_memoryCache setObject:image forKey:key];
        [_fileManager createFileAtPath:filePath contents:UIImagePNGRepresentation(image) attributes:nil];

        if (_totalFileCacheSize != NSUIntegerMax){
            _totalFileCacheSize += [self sizeOfFileAtPath:filePath];
        }

        [self shrinkFileCacheToSizeLimit];
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
    _totalFileCacheSize = NSUIntegerMax;
}

- (NSUInteger)memoryCacheCountLimit {
    return _memoryCache.countLimit;
}

- (void)setMemoryCacheCountLimit:(NSUInteger)memoryCacheCountLimit {
    _memoryCache.countLimit = memoryCacheCountLimit;
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

- (NSUInteger)sizeOfFileAtPath:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:path];

    NSNumber *size;
    [url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];

    return [size unsignedIntegerValue];
}

- (void)shrinkFileCacheToSizeLimit {
    if (_fileCacheTotalSizeLimit == 0) {
        //no limit, no need/sense to do anything
        return;
    }

    NSUInteger fileCacheSizeLimit = _fileCacheTotalSizeLimit * 1024 * 1024;

    // if we have calculated the cache size already, check if we fit into it
    if (_totalFileCacheSize != NSUIntegerMax && _totalFileCacheSize < fileCacheSizeLimit) {
        return;
    }

    static NSString *const urlKey = @"url";
    static NSString *const modificationDateKey = @"date";
    static NSString *const sizeKey = @"size";

    NSArray *urls = [_fileManager contentsOfDirectoryAtURL:[self imageCacheDirectory]
                                includingPropertiesForKeys:@[NSURLContentModificationDateKey, NSURLFileSizeKey]
                                                   options:NSDirectoryEnumerationSkipsHiddenFiles
                                                     error:NULL];

    NSMutableArray *files = [NSMutableArray arrayWithCapacity:urls.count];

    _totalFileCacheSize = 0;

    for (NSURL *url in urls) {
        NSNumber *size;
        [url getResourceValue:&size forKey:NSURLFileSizeKey error:NULL];

        NSDate *modificationDate;
        [url getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:NULL];

        [files addObject:@{
                urlKey : url,
                sizeKey : size,
                modificationDateKey : modificationDate
        }];

        _totalFileCacheSize += [size unsignedIntegerValue];
    }

    [files sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:modificationDateKey ascending:NO]]];

    while (_totalFileCacheSize > fileCacheSizeLimit * 3 / 4){
        NSDictionary * file = [files lastObject];
        [files removeLastObject];

        NSLog(@"will remove file: %@", file[urlKey]);

        _totalFileCacheSize -= [file[sizeKey] unsignedIntegerValue];

        [_fileManager removeItemAtURL:file[urlKey] error:NULL];
    }
}


@end