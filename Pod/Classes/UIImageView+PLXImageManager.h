//
//  UIImageView+UIImageView_PLXImageManager.h
//  Pods
//
//  Created by Antoni Kedracki on 18/01/16.
//
//

#import <UIKit/UIKit.h>

@class PLXImageManager;


@interface UIImageView (PLXImageManager)

/**
 * Convenience method for downloading and setting the image of the target UIImageView. The download token is handled internally.
 *
 * @param manager the manager that will be used to download the image
 *
 * @param identifier the identifier for the image to be downloaded (or retrieved from cache if possible)
 *
 * @param placeholderImage if the image can't be retrieved directly from cache, the placeholder image will be used for the time of the download
 */
- (void)plx_setImageUsingManager:(PLXImageManager*)manager withIdentifier:(id <NSObject>)identifier placeholderImage:(UIImage*)placeholderImage;

/**
 * Convenience method for downloading (and optionally setting) the image of the target UIImageView. The download token is handled internally.
 *
 * @param manager the manager that will be used to download the image
 *
 * @param identifier the identifier for the image to be downloaded (or retrieved from cache if possible)
 *
 * @param placeholderImage if the image can't be retrieved directly from cache, the placeholder image will be used for the time of the download
 *
 * @param callback once a image (placeholder or final image) is ready to be set on the UIImageView this callback will be called. You are responsible for setting the UIImageView image property inside. If nil is provided the image will be set with no other modifications.
 */
- (void)plx_setImageUsingManager:(PLXImageManager*)manager withIdentifier:(id <NSObject>)identifier placeholderImage:(UIImage*)placeholderImage callback:(void (^)(UIImage *image, BOOL isPlaceholder))callback;

@end
