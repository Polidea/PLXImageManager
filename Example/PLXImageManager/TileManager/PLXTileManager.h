#import <Foundation/Foundation.h>
#import <PLXImageManager/PLXImageManager.h>


@interface PLXTileManager : PLXImageManager

- (PLXImageManagerRequestToken *)tileForZoomLevel:(NSUInteger)zoom latDeg:(double)latDeg lonDeg:(double)lonDeg callback:(void (^)(UIImage *, NSUInteger, double, double))callback;
- (PLXImageManagerRequestToken *)tileForZoomLevel:(NSUInteger)zoom tileX:(NSInteger)tileX tileY:(NSInteger)tileY callback:(void (^)(UIImage *, NSUInteger, NSInteger, NSInteger))callback;

@end