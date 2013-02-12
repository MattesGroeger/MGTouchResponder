//
//  AppDelegate.m
//  MGTouchResponderExample
//
//  Created by Mattes Groeger on 24.12.12.
//  Copyright (c) 2012 Mattes Groeger. All rights reserved.
//

#import "AppDelegate.h"
#import "SimpleSceneController.h"

@interface AppDelegate ()

@property (nonatomic, strong) SimpleSceneController *sceneController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setMultipleTouchEnabled:YES];

    [self initCocos];

    self.sceneController = [[SimpleSceneController alloc] initWithTouchPriority:INT8_MAX];

    [[CCDirector sharedDirector] runWithScene:self.sceneController.scene];

    // Navigation Controller
    _navController = [[UINavigationController alloc] initWithRootViewController:_director];
    _navController.navigationBarHidden = YES;

	[_window setRootViewController:_navController];

    [_window makeKeyAndVisible];

    return YES;

}

- (void) initCocos {

    _director = (CCDirectorIOS*)[CCDirector sharedDirector];
    [_director setDisplayStats:NO];
    [_director setAnimationInterval:1.0/60];

    // GL View
    CCGLView *__glView = [CCGLView viewWithFrame:[_window bounds]
                                     pixelFormat:kEAGLColorFormatRGB565
                                     depthFormat:0 /* GL_DEPTH_COMPONENT24_OES */
                              preserveBackbuffer:NO
                                      sharegroup:nil
                                   multiSampling:NO
                                 numberOfSamples:0
    ];

    [__glView setMultipleTouchEnabled:YES];

    [_director setView:__glView];
    [_director setDelegate:self];
    _director.wantsFullScreenLayout = YES;

    // Retina Display ?
    [_director enableRetinaDisplay:_useRetinaDisplay];

}

// getting a call, pause the game
-(void) applicationWillResignActive:(UIApplication *)application
{
    if( [_navController visibleViewController] == _director )
        [_director pause];
}

// call got rejected
-(void) applicationDidBecomeActive:(UIApplication *)application
{
    if( [_navController visibleViewController] == _director )
        [_director resume];
}

-(void) applicationDidEnterBackground:(UIApplication*)application
{
    if( [_navController visibleViewController] == _director )
        [_director stopAnimation];
}

-(void) applicationWillEnterForeground:(UIApplication*)application
{
    if( [_navController visibleViewController] == _director )
        [_director startAnimation];
}

// application will be killed
- (void)applicationWillTerminate:(UIApplication *)application
{

    CC_DIRECTOR_END();
}

@end
