//
//  SimpleSceneController.h
//
//
// Created by Tommaso Piazza on 12/02/13.
// Copyright (c) 2013 Wooga GmbH. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "ccTypes.h"

@class CCScene;
@class MGTouchResponderGroup;


@interface SimpleSceneController : NSObject

@property(nonatomic, strong) CCScene *scene;
@property(nonatomic, strong, readonly) MGTouchResponderGroup *touchResponderGroup;

- (id)initWithTouchPriority:(NSInteger)touchPriority;

- (void)update:(NSNotification *)delta;

@end