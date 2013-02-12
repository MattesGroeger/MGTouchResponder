//
//  GestureRecognizer.h
//
// Created by Tommaso Piazza on 12/02/13.
// Copyright (c) 2013 Wooga GmbH. All rights reserved.
//

#import "MGTouchResponderCallback.h"
#import "MGTouchResponder.h"
#import "GestureRecognizer.h"

@interface GestureRecognizer ()

@property(nonatomic, strong) NSMutableArray *touches;

@end

@implementation GestureRecognizer

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
	self = [super init];

	if (self)
	{
		_touches = [NSMutableArray arrayWithCapacity:10];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emptyTouches:) name:UIApplicationWillResignActiveNotification object:nil];
	}

	return self;
}

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	// Add the touches
	[_touches addObject:touch];

	if (_touches.count > 1)
	{
		// If there is more than one touch
		[_touchResponderCallback.userInfo setObject:[NSNumber numberWithInt:GesturePinch] forKey:GESTURE_RECOGNIZER_KEY];

		// In this particular example there are no other touch handling layers interested in the touch so
		//  _touchResponderCallback.userInfo will be emptied as soon a the touch ends.
		// to pass the information on to the scene we use a notification
		[[NSNotificationCenter defaultCenter] postNotificationName:GESTURE_RECOGNIZER_KEY object:self userInfo:[_touchResponderCallback.userInfo copy]];
		[self.touches removeAllObjects];
		[_touchResponderCallback touchIgnored:self];
	}
}

- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	// if there were two or more touches we would have already ignored the touch
	if (_touches.count == 1)
	{
		// if there was only one touch and now it's moving, then it's a swipe
		id sanityCheck = [_touchResponderCallback.userInfo objectForKey:GESTURE_RECOGNIZER_KEY];
		NSAssert(sanityCheck == nil, @"Mutiple Gestures recognized");

		[_touchResponderCallback.userInfo setObject:[NSNumber numberWithInt:GestureSwipe] forKey:GESTURE_RECOGNIZER_KEY];
		// In this particular example there are no other touch handling layers interested in the touch so
		//  _touchResponderCallback.userInfo will be emptied as soon a the touch ends.
		// to pass the information on to the scene we use a notification
		[[NSNotificationCenter defaultCenter] postNotificationName:GESTURE_RECOGNIZER_KEY object:self userInfo:[_touchResponderCallback.userInfo copy]];
		[self.touches removeAllObjects];
		[_touchResponderCallback touchIgnored:self];
	}
	else
	{
		NSAssert(NO, @"Gesture Recognizer failure in %s", __PRETTY_FUNCTION__);
	}
}

- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	// if we are then the touch did not move. It's a tap. If the touches were 3 it would be... a TRAP!
	if (_touches.count == 1)
	{
		id sanityCheck = [_touchResponderCallback.userInfo objectForKey:GESTURE_RECOGNIZER_KEY];
		NSAssert(sanityCheck == nil, @"Mutiple Gestures recognized");

		[_touchResponderCallback.userInfo setObject:[NSNumber numberWithInt:GestureTap] forKey:GESTURE_RECOGNIZER_KEY];
		// In this particular example there are no other touch handling layers interested in the touch so
		//  _touchResponderCallback.userInfo will be emptied as soon a the touch ends.
		// to pass the information on to the scene we use a notification
		[[NSNotificationCenter defaultCenter] postNotificationName:GESTURE_RECOGNIZER_KEY object:self userInfo:[_touchResponderCallback.userInfo copy]];
		[self.touches removeAllObjects];
		[_touchResponderCallback touchIgnored:self];
	}
}

- (void)emptyTouches:(NSNotification *)notification
{
	[_touches removeAllObjects];
}

@end