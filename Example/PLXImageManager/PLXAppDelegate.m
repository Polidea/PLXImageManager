#import <PLXImageManager/PLXImageManager.h>
#import "PLXAppDelegate.h"
#import "PLXTileManager.h"
#import "PLXTileListViewController.h"
#import "PLXURLImageProvider.h"

@implementation PLXAppDelegate

+ (PLXAppDelegate *)appDelegate {
    return [UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _tileManager = [PLXTileManager new];
    _imageManager = [[PLXImageManager alloc] initWithProvider:[PLXURLImageProvider new]];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    PLXTileListViewController * listVC = [[PLXTileListViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:listVC];
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
 
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
 
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
