#import "PLXTileListViewController.h"
#import "PLXAppDelegate.h"
#import "PLXTileManager.h"
#import <PLXImageManager/NSObject+PLXImageManagerTokenStorage.h>


@implementation PLXTileListViewController {

}

NSInteger const tileYMin = 326;
NSInteger const tileYMax = 351;
NSInteger const tileXMin = 551;
NSInteger const tileXMax = 580;

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {

    }

    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 100;
    self.title = @"Tiles";
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, 0, 0);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (tileXMax - tileXMin) * (tileYMax - tileYMin);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"TileCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }

    NSUInteger const hash = [indexPath hash];
    cell.tag = hash;

    NSInteger ix = indexPath.row % (tileYMax - tileYMin) + tileXMin;
    NSInteger iy =indexPath.row / (tileYMax - tileYMin) + tileYMin;
    
    cell.textLabel.text = [NSString stringWithFormat:@"y: %ld x: %ld", (long)iy, (long)ix];

    cell.imageView.backgroundColor = [UIColor blackColor];
    cell.imageView.image = nil;

    [[cell plx_retrieveToken] cancel];

    PLXImageManagerRequestToken *token = [[PLXAppDelegate appDelegate].tileManager tileForZoomLevel:10 tileX:tileXMin + indexPath.row
                                                                                            tileY:tileYMin + indexPath.section
                                                                                         callback:^(UIImage *image, NSUInteger zoom, NSInteger tileX, NSInteger tileY) {
                                                                                             if (cell.tag == hash) {
                                                                                                 cell.imageView.image = image;
                                                                                                 [cell setNeedsLayout];
                                                                                             }
                                                                                         }];
    [cell plx_storeToken:token];

    return cell;
}

@end