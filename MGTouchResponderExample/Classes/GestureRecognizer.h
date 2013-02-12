//
//  GestureRecognizer.h
//
// Created by Tommaso Piazza on 12/02/13.
// Copyright (c) 2013 Wooga GmbH. All rights reserved.
//


#import <Foundation/Foundation.h>

@protocol MGTouchResponder;
@protocol MGTouchResponderCallback;

#define GESTURE_RECOGNIZER_KEY @"GestureRocognizer"

typedef enum _Gesture
{
	GestureUndefined = 0,
	GesturePinch = 10,
	GestureSwipe,
	GestureTap

} Gesture;

@interface GestureRecognizer : NSObject <MGTouchResponder>

@property(nonatomic, weak) id <MGTouchResponderCallback> touchResponderCallback;

@end