#import <Foundation/Foundation.h>
#import "PLXImageManagerOpRunner.h"

@interface PLXImageMangerOpRunnerFake : PLXImageManagerOpRunner

@property (nonatomic, assign, readonly) BOOL isExecuting;
- (BOOL)step;

@end