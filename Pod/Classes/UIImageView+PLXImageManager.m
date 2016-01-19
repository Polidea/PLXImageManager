//
//  UIImageView+UIImageView_PLXImageManager.m
//  Pods
//
//  Created by Antoni Kedracki on 18/01/16.
//
//

#import "UIImageView+PLXImageManager.h"
#import "PLXImageManager.h"
#import <objc/runtime.h>
#import "NSObject+PLXImageManagerTokenStorage.h"


@implementation UIImageView (PLXImageManager)

static char *const kUIImageViewPlusPLXImageManagerTargetHashKey = "UIImageViewPlusPLXImageManagerTargetKey";

- (void)plx_storeTargetHash:(NSUInteger)targetHash {
    objc_setAssociatedObject(self, kUIImageViewPlusPLXImageManagerTargetHashKey, @(targetHash), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSUInteger)plx_retrieveTargetHash {
    NSNumber *hash = (NSNumber *) objc_getAssociatedObject(self, kUIImageViewPlusPLXImageManagerTargetHashKey);
    return [hash unsignedIntegerValue];
}

- (void)plx_setImageUsingManager:(PLXImageManager *)manager withIdentifier:(id <NSObject>)identifier placeholderImage:(UIImage *)placeholderImage {
    [self plx_setImageUsingManager:manager withIdentifier:identifier placeholderImage:placeholderImage callback:nil];
}

- (void)plx_setImageUsingManager:(PLXImageManager *)manager withIdentifier:(id <NSObject>)identifier placeholderImage:(UIImage *)placeholderImage callback:(void (^)(UIImage *image, BOOL isPlaceholder))callback {
    NSUInteger targetHash = [identifier hash];

    if (callback == nil) {
        callback = ^(UIImage *image, BOOL isPlaceholder) {
            self.image = image;
        };
    }

    if (targetHash == [self plx_retrieveTargetHash]) {
        return;
    }

    [self plx_storeTargetHash:targetHash];

    PLXImageManagerRequestToken *token = [self plx_retrieveToken];
    [token cancel];
    token = [manager imageForIdentifier:identifier
                            placeholder:placeholderImage
                               callback:^(UIImage *image, BOOL isPlaceholder) {
                                   if (targetHash != [self plx_retrieveTargetHash]) {
                                       return;
                                   }

                                   if (!isPlaceholder) {
                                       [self plx_storeTargetHash:0];
                                   }

                                   callback(image, isPlaceholder);
                               }];
    [self plx_storeToken:token];
}

@end
