//
//  AppDelegate.h
//  MGTouchResponderExample
//
//  Created by Mattes Groeger on 24.12.12.
//  Copyright (c) 2012 Mattes Groeger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate, CCDirectorDelegate>

@property(strong, nonatomic) UIWindow *window;

@property(weak, nonatomic, readonly) CCDirectorIOS *director;
@property(nonatomic) UINavigationController *navController;

@property(nonatomic) BOOL useRetinaDisplay;

@end
