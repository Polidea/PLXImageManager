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

#import "PLXImageManagerLoadOperation.h"

@implementation PLXImageManagerLoadOperation {
@private
    UIImage * (^_loadBlock)();
    NSUInteger _usageCount;
}


- (id)initWithKey:(NSString *)aKey loadBlock:(UIImage * (^)())aLoadBlock {
    self = [super init];
    if (self) {
        _key = aKey;
        _loadBlock = aLoadBlock;
        _usageCount = 1;
    }

    return self;
}

- (void)main {
    if (self.isCancelled){
        return;
    }
    if (_loadBlock) {
        _image = _loadBlock();
    } else {
        NSLog(@"no work block was set");
    }
    if (_readyBlock != nil){
        _readyBlock(_image);
    }
}

- (void)cancel {
    [super cancel];
    if (_onCancelBlock != nil){
        _onCancelBlock();
    }
}

- (void)incrementUsage {
    _usageCount++;
}

- (void)decrementUsageAndCancelOnZero {
    if (_usageCount <= 0){
        return;
    }

    --_usageCount;
    if (_usageCount == 0){
        for (NSOperation * op in self.dependencies){
            [op cancel];
        }
        [self cancel];
    }
}


@end