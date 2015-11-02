#import "PLXTileManager.h"
#import <PLXImageManager/PLXURLImageProvider.h>


@implementation PLXTileManager {

}

- (id)init {
    self = [super initWithProvider:[PLXURLImageProvider new]];
    if (self) {

    }

    return self;
}

- (PLXImageManagerRequestToken *)tileForZoomLevel:(NSUInteger)zoom latDeg:(double)latDeg lonDeg:(double)lonDeg callback:(void (^)(UIImage *, NSUInteger, double, double))callback {
    return [self tileForZoomLevel:zoom tileX:[PLXTileManager tileForLon:lonDeg zoom:zoom]
                            tileY:[PLXTileManager tileForLat:latDeg zoom:zoom]
                         callback:^(UIImage *image, NSUInteger z, NSInteger x, NSInteger y) {
                             callback(image, zoom, latDeg, lonDeg);
                         }];
}

- (PLXImageManagerRequestToken *)tileForZoomLevel:(NSUInteger)zoom tileX:(NSInteger)tileX tileY:(NSInteger)tileY callback:(void (^)(UIImage *, NSUInteger, NSInteger, NSInteger))callback {
    NSString *url = [NSString stringWithFormat:@"http://otile1.mqcdn.com/tiles/1.0.0/osm/%ld/%ld/%ld.png", (long)zoom, (long)tileX, (long)tileY];

    return [self imageForIdentifier:url placeholder:nil callback:^(UIImage *image, BOOL isPlaceholder) {
        callback(image, zoom, tileX, tileY);
    }];
}

+ (NSInteger)tileForLon:(double)lonDeg zoom:(NSUInteger)zoom {
    return (int) (floor((lonDeg + 180.0) / 360.0 * pow(2.0, zoom)));
}

+ (NSInteger)tileForLat:(double)latDeg zoom:(NSUInteger)zoom {
    return (int) (floor((1.0 - log(tan(latDeg * M_PI / 180.0) + 1.0 / cos(latDeg * M_PI / 180.0)) / M_PI) / 2.0 * pow(2.0, zoom)));
}

@end