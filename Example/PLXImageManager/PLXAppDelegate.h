//
//  PLXAppDelegate.h
//  PLXImageManager
//
//  Created by Antoni Kedracki on 10/07/2015.
//  Copyright (c) 2015 Antoni Kedracki. All rights reserved.
//

@import UIKit;

@class PLXTileManager;
@class PLXImageManager;

@interface PLXAppDelegate : UIResponder <UIApplicationDelegate>

@property(strong, nonatomic) UIWindow *window;
@property(strong, readonly) PLXTileManager *tileManager;
@property(strong, readonly) PLXImageManager * imageManager;

+ (PLXAppDelegate *)appDelegate;

@end
