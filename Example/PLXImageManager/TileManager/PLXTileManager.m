#import "PLXTileManager.h"
#import <PLXImageManager/PLXURLImageProvider.h>


@implementation PLXTileManager {

}

- (NSString*)URLStringForTileAtZoomLevel:(NSUInteger)zoom tileX:(NSInteger)tileX tileY:(NSInteger)tileY {
    return [NSString stringWithFormat:@"http://otile1.mqcdn.com/tiles/1.0.0/osm/%ld/%ld/%ld.png", (long)zoom, (long)tileX, (long)tileY];
}

@end