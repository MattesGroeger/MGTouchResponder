/*
 * Copyright (c) 2012 Mattes Groeger
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "MGTouchResponder.h"
#import "MGTouchResponderGroup.h"

@implementation TouchData

@synthesize touch = _touch, event = _event;

- (id)initWithTouch:(UITouch *)touch andEvent:(UIEvent *)event
{
	self = [super init];

	if (self)
	{
		_touch = touch;
		_event = event;
	}

	return self;
}
@end

@implementation PrioritizedTouchResponder

@synthesize touchResponder = _touchResponder;
@synthesize priority = _priority;

- (id)initWithTouchResponder:(id <MGTouchResponder>)touchResponder priority:(NSUInteger)priority
{
	self = [super init];

	if (self)
	{
		_touchResponder = touchResponder;
		_priority = priority;
	}

	return self;
}

@end

@implementation MGTouchResponderGroup

- (id)init
{
	self = [super init];

	if (self)
	{
		_responders = [NSMutableArray array];
		_currentResponderIndex = 0;
		_currentTouches = [NSMutableArray array];
		_userInfo = [NSMutableDictionary dictionary];
	}

	return self;
}

- (void)addResponder:(id <MGTouchResponder>)responder withPriority:(NSUInteger)priority
{
	NSAssert(![self prioritizedTouchResponderForPriority:priority],
		@"Can't add responder with priority '%d'. Responder for this priority is already existent!", priority);

	[responder setTouchResponderCallback:self];
	NSMutableArray *responders = [NSMutableArray arrayWithObject:[[PrioritizedTouchResponder alloc]
									      initWithTouchResponder:responder
													    priority:priority]];
	[responders addObjectsFromArray:_responders];
	[self resortResponders:responders];
}

- (void)resortResponders:(NSArray *)responders
{
	NSArray *sortedArray = [responders sortedArrayUsingComparator:^(id a, id b)
	{
		NSNumber *first = [NSNumber numberWithInteger:[(PrioritizedTouchResponder *) a priority]];
		NSNumber *second = [NSNumber numberWithInteger:[(PrioritizedTouchResponder *) b priority]];

		return [first compare:second];
	}];

	_responders = [NSMutableArray arrayWithArray:sortedArray];
}

- (void)removeResponder:(id <MGTouchResponder>)responder
{
	[_responders removeObject:
		[self prioritizedTouchResponderForTouchResponder:responder]];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if ([_responders count] == 0)
	{
		return NO;
	}

	[self storeTouch:touch withEvent:event];
	[[self currentResponder] touchBegan:touch withEvent:event];

	return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	if ([self isProcessingTheTouch:touch])
	{
		id <MGTouchResponder> responder = [self currentResponder];

		if ([(NSObject *) responder respondsToSelector:@selector(touchMoved:withEvent:)])
		{
			[responder touchMoved:touch withEvent:event];
		}
	}
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
 	if ([self isProcessingTheTouch:touch])
	{
		id <MGTouchResponder> currentResponder = [self currentResponder];

		if ([(NSObject *) currentResponder respondsToSelector:@selector(touchEnded:withEvent:)])
		{
			[currentResponder touchEnded:touch withEvent:event];
		}

		NSUInteger currentResponderIndex = _currentResponderIndex;
		id <MGTouchResponder> newResponder = [self currentResponder];

		while (newResponder != nil && newResponder != currentResponder)
		{
			if ([(NSObject *) newResponder respondsToSelector:@selector(touchEnded:withEvent:)])
			{
				[newResponder touchEnded:touch withEvent:event];
			}

			currentResponder = newResponder;

			// BUGFIX for issue #5 where the reset of the _currentResponderIndex lead to this
			// logic to run in an endless loop as it started with the first responder again.
			// Now we check if the _currentResponderIndex increased, because this means it was
			// not reset while calling `touchIgnored` from the current responder.
			if (_currentResponderIndex > currentResponderIndex)
			{
				newResponder = [self currentResponder];
				currentResponderIndex = _currentResponderIndex;
			}
		}

		[self finishTouch:touch];
	}
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	if ([self isProcessingTheTouch:touch])
	{
		id <MGTouchResponder> responder = [self currentResponder];

		if ([(NSObject *) responder respondsToSelector:@selector(touchCancelled:withEvent:)])
		{
			[responder touchCancelled:touch withEvent:event];
		}

		[self finishTouch:touch];
	}
}

- (void)touchIgnored:(id <MGTouchResponder>)originator;
{
	NSAssert(originator == [self currentResponder] || ![self hasActiveTouches],
		@"You tried to ignore a touch from a responder which is currently not active!");

	if (_currentResponderIndex == [_responders count] - 1)
	{
		[self finishAllTouches];
	}
	else
	{
		_currentResponderIndex += 1;
	}

	if ([self hasActiveTouches])
	{
		const NSUInteger currentResponderIndex = _currentResponderIndex;
		id <MGTouchResponder> const currentResponder = [self currentResponder];

		for (TouchData *touchData in _currentTouches)
		{
			[currentResponder touchBegan:touchData.touch withEvent:touchData.event];

			if (currentResponderIndex != _currentResponderIndex)
			{
				// This can happen if a responder ignores the touch within the
				// 'touchBegan' method and therefore triggers another 'touchIgnored'
				break;
			}
		}
	}
}

- (void)touchConsumed:(id <MGTouchResponder>)originator;
{
	NSAssert(![self hasActiveTouches] || originator == [self currentResponder],
		@"You tried to consume a touch from a responder which is currently not active!");

	[self finishAllTouches];
}

#pragma mark private

- (PrioritizedTouchResponder *)prioritizedTouchResponderForTouchResponder:(id <MGTouchResponder>)touchResponder
{
	for (PrioritizedTouchResponder *currentResponder in _responders)
	{
		if (currentResponder.touchResponder == touchResponder)
		{
			return currentResponder;
		}
	}

	return nil;
}

- (PrioritizedTouchResponder *)prioritizedTouchResponderForPriority:(NSUInteger)priority
{
	for (PrioritizedTouchResponder *currentResponder in _responders)
	{
		if (currentResponder.priority == priority)
		{
			return currentResponder;
		}
	}

	return nil;
}

- (id <MGTouchResponder>)currentResponder
{
	if (_currentResponderIndex >= [_responders count])
		return nil;

	return [[_responders objectAtIndex:_currentResponderIndex] touchResponder];
}

- (BOOL)hasActiveTouches
{
	return _currentTouches.count > 0;
}

- (BOOL)isProcessingTheTouch:(UITouch *)touch
{
	NSArray *touchData = [self touchDataForTouch:touch];
	return [self hasActiveTouches] && [touchData count] > 0;
}

- (void)storeTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[_currentTouches addObject:[[TouchData alloc] initWithTouch:touch andEvent:event]];
}

- (void)removeTouch:(UITouch *)touch
{
	NSArray *touchData = [self touchDataForTouch:touch];
	[_currentTouches removeObjectsInArray:touchData];
}

- (NSArray *)touchDataForTouch:(UITouch *)touch
{
	NSMutableArray *array = [NSMutableArray array];

	for (TouchData *data in _currentTouches)
	{
		if (data.touch == touch)
			[array addObject:data];
	}

	return array;
}

- (void)finishTouch:(UITouch *)touch
{
	[self removeTouch:touch];

	if ([_currentTouches count] == 0)
	{
		[_userInfo removeAllObjects];
		_currentResponderIndex = 0;
	}
}

- (void)finishAllTouches
{
	[_userInfo removeAllObjects];
	[_currentTouches removeAllObjects];
	_currentResponderIndex = 0;
}

@end