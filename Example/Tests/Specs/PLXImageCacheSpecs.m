#import "PLXImageCache.h"
#import "UIImage+RandomImage.h"

@interface PLXImageCache ()

- (id)initWithCache:(NSCache *)cache fileManager:(NSFileManager *)manager;
- (NSURL *)imageCacheDirectory;

@end

SpecBegin(PLXImageCacheSpecs)

describe(@"PLXImageCache", ^{
    describe(@"setting a image", ^{
        __block PLXImageCache * imageCache;
        __block NSFileManager * fileManagerStub;
        __block NSCache * memoryCacheStub;
        NSString * const key = @"abcde";
        
        beforeEach(^{
            fileManagerStub = MKTMock([NSFileManager class]);
            memoryCacheStub = MKTMock([NSCache class]);
            imageCache = [[PLXImageCache alloc] initWithCache:memoryCacheStub
                                                  fileManager:fileManagerStub];
        });
        
        context(@"when non-nil", ^{
            __block UIImage* imageMock;
            
            beforeAll(^{
                imageMock = [UIImage randomImage];
            });
            
            it(@"should store it in the file cache", ^{
                [imageCache set:imageMock
                         forKey:key];
                
                [MKTVerify(fileManagerStub) createFileAtPath:anything()
                                                    contents:anything()
                                                  attributes:anything()];
            });
            
            it(@"should store it in the memory cache", ^{
                [imageCache set:imageMock
                         forKey:key];
                
                [MKTVerify(memoryCacheStub) setObject:imageMock
                                               forKey:key];
            });
        });
        
        context(@"when nil", ^{
            it(@"should remove it from the file cache", ^{
                [imageCache set:nil
                         forKey:key];
                
                [MKTVerify(fileManagerStub) removeItemAtPath:anything()
                                                       error:nil];
            });
            
            it(@"should remove it from the memory cache", ^{
                [imageCache set:nil
                         forKey:key];
                
                
                [MKTVerify(memoryCacheStub) removeObjectForKey:key];
            });
        });
    });
    
    describe(@"removing a image", ^{
        __block PLXImageCache * imageCache;
        __block NSFileManager * fileManagerStub;
        __block NSCache * memoryCacheStub;
        NSString * const key = @"abcde";
        
        beforeEach(^{
            fileManagerStub = MKTMock([NSFileManager class]);
            memoryCacheStub = MKTMock([NSCache class]);
            imageCache = [[PLXImageCache alloc] initWithCache:memoryCacheStub
                                                  fileManager:fileManagerStub];
        });
        
        it(@"should remove it from the file cache", ^{
            [imageCache removeImageWithKey:key];
            
            [MKTVerify(fileManagerStub) removeItemAtPath:anything()
                                                   error:nil];
        });
        
        it(@"should remove it from the memory cache", ^{
            [imageCache removeImageWithKey:key];
            
            [MKTVerify(memoryCacheStub) removeObjectForKey:key];
        });
    });
    
    describe(@"clearing", ^{
        __block PLXImageCache * imageCache;
        __block NSFileManager * fileManagerStub;
        __block NSCache * memoryCacheStub;
        
        
        beforeEach(^{
            fileManagerStub = MKTMock([NSFileManager class]);
            memoryCacheStub = MKTMock([NSCache class]);
            imageCache = [[PLXImageCache alloc] initWithCache:memoryCacheStub
                                                  fileManager:fileManagerStub];
        });
        
        it(@"should work for the file cache", ^{
            [imageCache clearFileCache];
            
            [MKTVerify(fileManagerStub) removeItemAtPath:[[imageCache imageCacheDirectory] path]
                                                   error:nil];
        });
        
        it(@"should work for the memory cache", ^{
            [imageCache clearMemoryCache];
            
            [MKTVerify(memoryCacheStub) removeAllObjects];
        });
    });
    
    describe(@"memory cache limit property", ^{
        __block PLXImageCache * imageCache;
        __block NSFileManager * fileManagerStub;
        __block NSCache * memoryCacheStub;
        
        
        beforeEach(^{
            fileManagerStub = MKTMock([NSFileManager class]);
            memoryCacheStub = MKTMock([NSCache class]);
            imageCache = [[PLXImageCache alloc] initWithCache:memoryCacheStub
                                                  fileManager:fileManagerStub];
        });
        
        it(@"read should proxy to the buildin cache", ^{
            __unused NSInteger sizeLimit = imageCache.memoryCacheSizeLimit;
            
            [MKTVerify(memoryCacheStub) countLimit];
        });
        
        it(@"write should proxy to the buildin cache", ^{
            imageCache.memoryCacheSizeLimit = 10;
            
            [MKTVerify(memoryCacheStub) setCountLimit:10];
        });
    });
});

SpecEnd