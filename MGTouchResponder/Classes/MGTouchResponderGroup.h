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

#import <Foundation/Foundation.h>
#import "CCTouchDelegateProtocol.h"

@protocol MGTouchResponder;

@protocol TouchResponderCallback

@property (nonatomic, strong) id touchedObject;

- (void)touchIgnored:(id <MGTouchResponder>)originator;

- (void)touchConsumed:(id <MGTouchResponder>)originator;

@end

@interface TouchData : NSObject
{
@private
	UITouch *_touch;
	UIEvent *_event;
}
@property(nonatomic, strong) UITouch *touch;
@property(nonatomic, strong) UIEvent *event;

- (id)initWithTouch:(UITouch *)touch andEvent:(UIEvent *)event;

@end

@interface PrioritizedTouchResponder : NSObject
{
	id <MGTouchResponder> _touchResponder;
	NSUInteger _priority;
}

@property (nonatomic, strong) id <MGTouchResponder> touchResponder;
@property (nonatomic, assign) NSUInteger priority;

- (id)initWithTouchResponder:(id <MGTouchResponder>)touchResponder priority:(NSUInteger)priority;

@end

@protocol MGTouchResponder;

@interface MGTouchResponderGroup : NSObject <CCTargetedTouchDelegate, TouchResponderCallback>
{
@private
	NSMutableArray *_responders;
	NSUInteger _currentResponderIndex;
	NSMutableArray *_currentTouches;
	id _touchedObject;
}

- (id)initWithPriority:(int)priority;

- (void)addResponder:(id <MGTouchResponder>)responder withPriority:(NSUInteger)priority;

- (void)removeResponder:(id <MGTouchResponder>)responder;

@end