//
//  SimpleSceneController.h
//
//
// Created by Tommaso Piazza on 12/02/13.
// Copyright (c) 2013 Wooga GmbH. All rights reserved.
//


#import "SimpleSceneController.h"
#import "CCScene.h"
#import "MGTouchResponderGroup.h"
#import "CCDirectorIOS.h"
#import "CCTouchDispatcher.h"
#import "CCLabelTTF.h"
#import "MGTouchResponder.h"
#import "GestureRecognizer.h"


@interface SimpleSceneController ()

@property (nonatomic, strong, readwrite) MGTouchResponderGroup *touchResponderGroup;
@property (nonatomic, strong) CCLabelTTF *aLabel;

@end

@implementation SimpleSceneController {

}


- (id) initWithTouchPriority:(NSInteger) touchPriority {

    self = [super init];

    if (self) {

        CGSize winSize = [CCDirector sharedDirector].winSize;

        _touchResponderGroup = [[MGTouchResponderGroup alloc] init];

        [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:_touchResponderGroup
                                                                  priority:touchPriority
                                                           swallowsTouches:YES];

        GestureRecognizer *gestureRecognizer = [[GestureRecognizer alloc] init];

        [_touchResponderGroup addResponder:gestureRecognizer withPriority:INT8_MAX];


        _scene = [[CCScene alloc] init];
        _aLabel = [[CCLabelTTF alloc] initWithString:@"Perform a gesture" fontName:@"Arial" fontSize:32.0f];
        _aLabel.anchorPoint = (CGPoint){0.5f, 0.5f};
        _aLabel.color = ccc3(0, 255, 0);
        _aLabel.position = (CGPoint){winSize.height/2, winSize.width/2};
        [_scene addChild:_aLabel];


        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update:) name:GESTURE_RECOGNIZER_KEY object:nil];

    }

    return self;
}

- (void) update:(NSNotification *) notification {

    Gesture gestureKind = [[notification.userInfo objectForKey:GESTURE_RECOGNIZER_KEY] intValue];

    switch (gestureKind){
        case GesturePinch:
            self.aLabel.string = @"Pinch";
            break;
        case GestureSwipe:
            self.aLabel.string = @"Swipe";
            break;
        case GestureTap:
            self.aLabel.string = @"Tap";
            break;
        case GestureUndefined:
        default:
            self.aLabel.string = @"Perform a gesture";
            break;
    }

}

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:_touchResponderGroup];
}

@end