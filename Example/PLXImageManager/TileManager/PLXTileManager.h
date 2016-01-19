#import <Foundation/Foundation.h>
#import <PLXImageManager/PLXImageManager.h>

@interface PLXTileManager : NSObject

- (NSString*)URLStringForTileAtZoomLevel:(NSUInteger)zoom tileX:(NSInteger)tileX tileY:(NSInteger)tileY;

@end