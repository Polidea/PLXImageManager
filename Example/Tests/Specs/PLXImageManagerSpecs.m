#import "PLXImageManager.h"
#import "PLXImageCache.h"
#import "UIImage+RandomImage.h"
#import "PLXImageManagerOpRunner.h"
#import "PLXImageMangerOpRunnerFake.h"
#import "NSInvocation+OCMockito.h"

@interface PLXImageManager ()

- (id)initWithProvider:(id <PLXImageManagerProvider>)aProvider cache:(PLXImageCache *)aCache ioOpRunner:(PLXImageManagerOpRunner *)ioOpRunner downloadOpRunner:(PLXImageManagerOpRunner *)downloadOpRunner sentinelOpRunner:(PLXImageManagerOpRunner *)sentinelOpRunner;

@end

SpecBegin(PLXImageManagerSpecs)

describe(@"PLXImageManager", ^{
    __block UIImage * quickImage;
    __block UIImage * quickImage2;
    
    beforeAll(^{
        quickImage = [UIImage randomImageWithSize:CGSizeMake(32, 32)];
        quickImage2 = [UIImage randomImageWithSize:CGSizeMake(16, 16)];
    });
    
    describe(@"during creation", ^{
        __block PLXImageManager * imageManager;
        
        it(@"should complain about missing provider", ^{
            expect(^{
                imageManager = [[PLXImageManager alloc] initWithProvider:nil];
            }).to.raise(@"InvalidArgumentException");
        });
        
        it(@"should ask the provider for the maxConcurrentDownloadsCount", ^{
            id<PLXImageManagerProvider> provider = MKTMockProtocol(@protocol(PLXImageManagerProvider));
            
            imageManager = [[PLXImageManager alloc] initWithProvider:provider];
            
            [MKTVerify(provider) maxConcurrentDownloadsCount];
        });
    });
    
    describe(@"memory cache limit property", ^{
        __block Class identifierClass;
        __block PLXImageManager * imageManager;
        __block id<PLXImageManagerProvider> providerMock;
        __block PLXImageCache * cacheMock;
        
        beforeAll(^{
            identifierClass = [NSString class];
        });
        
        beforeEach(^{
            providerMock = MKTMockProtocol(@protocol(PLXImageManagerProvider));
            cacheMock = MKTMock([PLXImageCache class]);
            
            [MKTGiven([providerMock identifierClass]) willReturn:identifierClass];
            [MKTGiven([providerMock keyForIdentifier:anything()]) willDo:^id(NSInvocation * invocation) {
                NSArray * args = [invocation mkt_arguments];
                return args[0];
            }];
            
            imageManager = [[PLXImageManager alloc] initWithProvider:providerMock cache:cacheMock ioOpRunner:NULL downloadOpRunner:NULL sentinelOpRunner:NULL];
        });
        
        it(@"reads should proxy to image cache", ^{
            __unused NSInteger sizeLimit = imageManager.memoryCacheSizeLimit;
            
            [MKTVerify(cacheMock) memoryCacheSizeLimit];
        });
    
        it(@"writes should proxy to image cache", ^{
            imageManager.memoryCacheSizeLimit = 5;
            
            [MKTVerify(cacheMock) setMemoryCacheSizeLimit:5];
        });
    });
    
    describe(@"clearing", ^{
        __block Class identifierClass;
        __block PLXImageManager * imageManager;
        __block id<PLXImageManagerProvider> providerMock;
        __block PLXImageCache * cacheMock;
        
        beforeAll(^{
            identifierClass = [NSString class];
        });
        
        beforeEach(^{
            providerMock = MKTMockProtocol(@protocol(PLXImageManagerProvider));
            cacheMock = MKTMock([PLXImageCache class]);
            
            [MKTGiven([providerMock identifierClass]) willReturn:identifierClass];
            [MKTGiven([providerMock keyForIdentifier:anything()]) willDo:^id(NSInvocation * invocation) {
                NSArray * args = [invocation mkt_arguments];
                return args[0];
            }];
            
            imageManager = [[PLXImageManager alloc] initWithProvider:providerMock cache:cacheMock ioOpRunner:NULL downloadOpRunner:NULL sentinelOpRunner:NULL];
        });
        
        it(@"a image should call the proper image cache methods", ^{
            NSString * const identifier = @"example_id";
            
            [imageManager clearCachedImageForIdentifier:identifier];
            
            [MKTVerify(cacheMock) removeImageWithKey:identifier];
        });
        
        #pragma GCC diagnostic push
        #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        it(@"all images should call the proper image cache methods", ^{
            [imageManager clearCache];
            
            [MKTVerify(cacheMock) clearMemoryCache];
            [MKTVerify(cacheMock) clearFileCache];
        });
        #pragma GCC diagnostic pop
        
        it(@"images in memory should call the proper image cache methods", ^{
            [imageManager clearMemoryCache];
            
            [MKTVerify(cacheMock) clearMemoryCache];
        });
        
        it(@"images in file storage should call the proper image cache methods", ^{
            [imageManager clearFileCache];
            
            [MKTVerify(cacheMock) clearFileCache];
        });
    });

    describe(@"requesting a image", ^{
        __block Class identifierClass = [NSString class];
        __block NSString * identifier = @"example_id";
        __block PLXImageManager * imageManager;
        __block id providerMock;
        __block id cacheMock;
        __block PLXImageMangerOpRunnerFake * ioOpRunner;
        __block PLXImageMangerOpRunnerFake * downloadOpRunner;
        __block PLXImageMangerOpRunnerFake * sentinelOpRunner;
        
        __block BOOL (^drainOpRunners)(NSUInteger) = ^(NSUInteger limit){
            NSUInteger i = limit;
            while(i > 0){
                
                NSUInteger exec = 0;
                exec += [ioOpRunner step] ? 1 : 0;
                exec += [downloadOpRunner step] ? 1 : 0;
                exec += [sentinelOpRunner step] ? 1 : 0;
                NSLog(@"exec[%lu]: %lu", i, (unsigned long)exec);
                if(exec == 0){
                    return YES;
                }
                --i;
                [NSThread sleepForTimeInterval:0.001];
            };
            return NO;
        };
        
        beforeEach(^{
            providerMock = MKTMockProtocol(@protocol(PLXImageManagerProvider));
            
            cacheMock = MKTMock([PLXImageCache class]);
            
            [MKTGiven([providerMock identifierClass]) willReturn:identifierClass];
            [MKTGiven([providerMock keyForIdentifier:anything()]) willDo:^id(NSInvocation * invocation) {
                NSArray * args = [invocation mkt_arguments];
                return args[0];
            }];
            [MKTGiven([providerMock maxConcurrentDownloadsCount]) willReturnInt:1];
            
            ioOpRunner = [PLXImageMangerOpRunnerFake new];
            downloadOpRunner = [PLXImageMangerOpRunnerFake new];
            sentinelOpRunner = [PLXImageMangerOpRunnerFake new];
            
            imageManager = [[PLXImageManager alloc] initWithProvider:providerMock
                                                               cache:cacheMock
                                                          ioOpRunner:ioOpRunner
                                                    downloadOpRunner:downloadOpRunner
                                                    sentinelOpRunner:sentinelOpRunner];
        });
        
        describe(@"should ask the provider", ^{
            it(@"for the identifier class", ^{
                [imageManager imageForIdentifier:identifier placeholder:nil callback:nil];
                
                drainOpRunners(20);
                
                [MKTVerify(providerMock) identifierClass];
            });
            
            it(@"for the idenfifier class and throw an exception on missmatch", ^{
                expect(^{
                    [imageManager imageForIdentifier:[NSDate date] placeholder:nil callback:nil];

                    drainOpRunners(20);
                }).to.raise(@"InvalidArgumentException");
            });
            
            it(@"for the key resulting from the identifier", ^{
                [imageManager imageForIdentifier:identifier placeholder:nil callback:nil];
                
                drainOpRunners(20);
                
                [MKTVerify(providerMock) keyForIdentifier:identifier];
            });
        });

        
        context(@"when already in the memory cache", ^{
            beforeEach(^{
                [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:YES]) willReturn:quickImage];
            });
            
            it(@"should ask about the memory copy", ^{
                [imageManager imageForIdentifier:identifier placeholder:nil callback:^(UIImage *image, BOOL isPlaceholder) {
                    expect(image).to.equal(quickImage);
                }];
                
                [MKTVerify(cacheMock) getWithKey:identifier onlyMemoryCache:YES];
            });
            
            it(@"should not ask about the file copy", ^{
                [imageManager imageForIdentifier:identifier placeholder:nil callback:nil];
                
                drainOpRunners(20);
                
                [MKTVerifyCount(cacheMock, MKTNever()) getWithKey:identifier onlyMemoryCache:NO];
            });
            
            it(@"should not fetch from the network", ^{
                [imageManager imageForIdentifier:identifier placeholder:nil callback:nil];
                
                drainOpRunners(20);
                
                NSError * error;
                [[MKTVerifyCount(providerMock, MKTNever()) withMatcher:anything() forArgument:1] downloadImageWithIdentifier:anything() error:&error];
            });
        });
        
        context(@"when already in the file cache", ^{
            beforeEach(^{
                [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:YES]) willReturn:nil];
                [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:NO]) willReturn:quickImage];
            });
            
            it(@"should ask about the memory copy", ^{
                [imageManager imageForIdentifier:identifier placeholder:nil callback:^(UIImage *image, BOOL isPlaceholder) {
                    expect(image).to.equal(quickImage);
                }];
                
                [MKTVerify(cacheMock) getWithKey:identifier onlyMemoryCache:YES];
            });
            
            it(@"should ask about the file copy", ^{
                [imageManager imageForIdentifier:identifier placeholder:nil callback:^(UIImage *image, BOOL isPlaceholder) {
                    expect(image).to.equal(quickImage);
                }];
                
                drainOpRunners(20);
                
                [MKTVerify(cacheMock) getWithKey:identifier onlyMemoryCache:NO];
            });
            
            it(@"should not fetch from the network", ^{
                [imageManager imageForIdentifier:identifier placeholder:nil callback:nil];
                
                drainOpRunners(20);
            
                [[MKTVerifyCount(providerMock, MKTNever()) withMatcher:anything() forArgument:1] downloadImageWithIdentifier:anything() error:NULL];
            });
        });
        
        context(@"should return a token", ^{
            it(@"that is not nil", ^{
                PLXImageManagerRequestToken *token = [imageManager imageForIdentifier:identifier
                                                                          placeholder:nil
                                                                             callback:nil];
                
                assertThat(token, notNilValue());
            });
            
            context(@"that properly reports it's isReady state", ^{
                it(@"in quick path scenario", ^{
                    //force quick path
                    [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:YES]) willReturn:quickImage];
                    
                    PLXImageManagerRequestToken *token = [imageManager imageForIdentifier:identifier
                                                                              placeholder:nil
                                                                                 callback:nil];
                    assertThatBool(token.isReady, isTrue());
                });
                
                
                it(@"in slow path (file) scenario", ^{
                    //force slow file path
                    [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:YES]) willReturn:nil];
                    [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:NO]) willReturn:quickImage];
                    
                    PLXImageManagerRequestToken *token = [imageManager imageForIdentifier:identifier
                                                                              placeholder:nil
                                                                                 callback:nil];
                    
                    assertThatBool(token.isReady, isFalse());
                    
                    drainOpRunners(20);
                    
                    assertThatBool(token.isReady, isTrue());
                });

                it(@"in slow path (network) scenario", ^{
                    //force slow network path
                    [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:YES]) willReturn:nil];
                    [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:NO]) willReturn:nil];
                    
                    PLXImageManagerRequestToken *token = [imageManager imageForIdentifier:identifier
                                                                              placeholder:nil
                                                                                 callback:nil];
                    
                    assertThatBool(token.isReady, isFalse());
                    
                    drainOpRunners(20);
                    
                    assertThatBool(token.isReady, isTrue());
                });
            });
            
            context(@"that can be used to cancel a request", ^{
                it(@"in slow path (file) scenario", ^{
                    //force slow file path
                    [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:YES]) willReturn:nil];
                    [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:NO]) willReturn:quickImage];
                    
                    PLXImageManagerRequestToken *token = [imageManager imageForIdentifier:identifier
                                                                              placeholder:nil
                                                                                 callback:nil];
                    
                    [token cancel];
                    
                    drainOpRunners(20);
                    
                    [MKTVerifyCount(cacheMock, MKTNever()) getWithKey:anything() onlyMemoryCache:NO];
                });
                
                it(@"in slow path (network) scenario", ^{
                    //force slow network path
                    [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:YES]) willReturn:nil];
                    [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:NO]) willReturn:nil];
                    
                    PLXImageManagerRequestToken *token = [imageManager imageForIdentifier:identifier
                                                                              placeholder:nil
                                                                                 callback:nil];
                    
                    [token cancel];
                    
                    drainOpRunners(20);
                    
                    [[MKTVerifyCount(providerMock, MKTNever()) withMatcher:anything() forArgument:1] downloadImageWithIdentifier:anything() error:NULL];
                });
            });
        });
        
        context(@"should use the notification callback", ^{
            __block UIImage * placeholderImage;
            
            beforeAll(^{
                placeholderImage = [UIImage randomImageWithSize:CGSizeMake(16, 16)];
            });
            
            it(@"in quick flow scenario", ^{
                //force quick path
                [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:YES]) willReturn:quickImage];
                
                __block BOOL wasCalled = NO;
                [imageManager imageForIdentifier:identifier
                                     placeholder:placeholderImage
                                        callback:^(UIImage *image, BOOL isPlaceholder) {
                                            wasCalled = YES;
                                            assertThat(image, equalTo(quickImage));
                                            assertThatBool(isPlaceholder, isFalse());
                                        }];
                
                //should be called synchronously => at this point already executed
                assertThatBool(wasCalled, isTrue());
            });
            
            it(@"in slow path (file) scenario", ^{
                //force slow file path
                [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:YES]) willReturn:nil];
                [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:NO]) willReturn:quickImage];

                __block NSUInteger numberOfCalls = 0;
                
                [imageManager imageForIdentifier:identifier
                                     placeholder:placeholderImage
                                        callback:^(UIImage *image, BOOL isPlaceholder) {
                                            if (numberOfCalls == 0) {
                                                assertThat(image, equalTo(placeholderImage));
                                                assertThatBool(isPlaceholder, isTrue());
                                            } else if (numberOfCalls == 1) {
                                                assertThat(image, equalTo(quickImage));
                                                assertThatBool(isPlaceholder, isFalse());
                                            }
                                            ++numberOfCalls;
                                        }];
                assertThatInteger(numberOfCalls, equalToInteger(1)); //placeholder invocation should happen imidietly
                
                drainOpRunners(20);
                
                assertThatInteger(numberOfCalls, equalToInteger(2)); //after the image is fetched from file cache
            });
            
            it(@"in slow path (network) scenario", ^{
                //force slow network path
                [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:YES]) willReturn:nil];
                [MKTGiven([cacheMock getWithKey:anything() onlyMemoryCache:NO]) willReturn:nil];
                [[MKTGiven([providerMock downloadImageWithIdentifier:anything() error:NULL]) withMatcher:anything() forArgument:1] willReturn:quickImage];
                
                __block NSUInteger numberOfCalls = 0;
                
                [imageManager imageForIdentifier:identifier
                                     placeholder:placeholderImage
                                        callback:^(UIImage *image, BOOL isPlaceholder) {
                                            if (numberOfCalls == 0) {
                                                assertThat(image, equalTo(placeholderImage));
                                                assertThatBool(isPlaceholder, isTrue());
                                            } else if (numberOfCalls == 1) {
                                                assertThat(image, equalTo(quickImage));
                                                assertThatBool(isPlaceholder, isFalse());
                                            }
                                            ++numberOfCalls;
                                        }];
                
                assertThatInteger(numberOfCalls, equalToInteger(1)); //placeholder invocation should happen imidietly
                
                drainOpRunners(20);
                
                assertThatInteger(numberOfCalls, equalToInteger(2)); //after the image is downloaded
            });
        });

    });
});

SpecEnd