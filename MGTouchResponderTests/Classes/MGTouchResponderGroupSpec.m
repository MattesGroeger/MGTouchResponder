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

#import "Kiwi.h"
#import "MGTouchResponder.h"
#import "TouchResponderGroupFixtures.h"

SPEC_BEGIN(MGTouchResponderGroupSpec)

describe(@"MGTouchResponderGroup", ^
{
	__block MGTouchResponderGroup *touchResponderGroup;
	__block UITouch *touch = [[UITouch alloc] init];
	__block UIEvent *event = [[UIEvent alloc] init];

	context(@"with no responder", ^
	{
		beforeEach(^
		{
			CALL_COUNT = 0;
			touchResponderGroup = [[MGTouchResponderGroup alloc] init];
		});

		it(@"shouldn't fail", ^
		{
			BOOL result = [touchResponderGroup ccTouchBegan:touch withEvent:event];

			[[theValue(result) should] beNo];
		});

		it(@"should add responders according to priority", ^
		{
			ResponderIgnoreOnEnded *responder1 = [[ResponderIgnoreOnEnded alloc] init];
			ResponderIgnoreOnEnded *responder2 = [[ResponderIgnoreOnEnded alloc] init];

			[touchResponderGroup addResponder:responder1 withPriority:10];
			[touchResponderGroup addResponder:responder2 withPriority:0];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchEnded:touch withEvent:event];

			[[theValue(responder1.callIndex) should] equal:theValue(1)];
			[[theValue(responder2.callIndex) should] equal:theValue(0)];
		});

		it(@"should remove previously added responder", ^
		{
			ResponderIgnoreOnEnded *responder1 = [[ResponderIgnoreOnEnded alloc] init];
			id responder2 = [KWMock mockForProtocol:@protocol(MGTouchResponder)];
			[[responder2 should] receive:@selector(setTouchResponderCallback:) withArguments:touchResponderGroup];
			[[responder2 should] receive:@selector(touchBegan:withEvent:) withCount:0];

			[touchResponderGroup addResponder:responder1 withPriority:10];
			[touchResponderGroup addResponder:responder2 withPriority:0];
			[touchResponderGroup removeResponder:responder2];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchEnded:touch withEvent:event];
		});

		it(@"should fail to add responder with existing priority", ^
		{
			ResponderIgnoreOnEnded *responder1 = [[ResponderIgnoreOnEnded alloc] init];
			ResponderIgnoreOnEnded *responder2 = [[ResponderIgnoreOnEnded alloc] init];

			[touchResponderGroup addResponder:responder1 withPriority:0];

			[[theBlock(^
			{
				[touchResponderGroup addResponder:responder2 withPriority:0];
			}) should] raiseWithReason:@"Can't add responder with priority '0'. Responder for this priority is already existent!"];
		});
	});

	context(@"with first responder that ignores touch when touchEnded", ^
	{
		__block ResponderIgnoreOnEnded *responder1 = [[ResponderIgnoreOnEnded alloc] init];
		__block id responder2 = [KWMock mockForProtocol:@protocol(MGTouchResponder)];

		beforeEach(^
		{
			touchResponderGroup = [[MGTouchResponderGroup alloc] init];

			[[responder2 should] receive:@selector(setTouchResponderCallback:) withArguments:touchResponderGroup];

			[touchResponderGroup addResponder:responder1 withPriority:0];
			[touchResponderGroup addResponder:responder2 withPriority:1];
		});

		it(@"should replay touchBegan on second responder", ^
		{
			[[responder2 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
			[[responder2 should] receive:@selector(touchEnded:withEvent:) withArguments:touch,event];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchEnded:touch withEvent:event]; // calls ignore here!
		});

		it(@"should not replay cancelled touch on second responder", ^
		{
			UITouch *touch2 = [[UITouch alloc] init];
			UIEvent *event2 = [[UIEvent alloc] init];

			[[responder2 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
			[[responder2 should] receive:@selector(touchEnded:withEvent:) withArguments:touch,event];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchBegan:touch2 withEvent:event2]; // swallowed by responder1
			[touchResponderGroup ccTouchMoved:touch2 withEvent:event2]; // swallowed by responder1
			[touchResponderGroup ccTouchCancelled:touch2 withEvent:event2]; // swallowed by responder1
			[touchResponderGroup ccTouchEnded:touch withEvent:event]; // calls ignored here! Next responder..
		});
	});

	context(@"with three responders", ^
	{
		__block id responder1;
		__block id responder2;
		__block id responder3;

		beforeEach(^
		{
			touchResponderGroup = [[MGTouchResponderGroup alloc] init];

			responder1 = [KWMock mockForProtocol:@protocol(MGTouchResponder)];
			responder2 = [[ResponderIgnoreOnEnded alloc] init];
			responder3 = [KWMock mockForProtocol:@protocol(MGTouchResponder)];

			[[responder1 should] receive:@selector(setTouchResponderCallback:) withArguments:touchResponderGroup];
			[[responder3 should] receive:@selector(setTouchResponderCallback:) withArguments:touchResponderGroup];

			[touchResponderGroup addResponder:responder1 withPriority:0];
			[touchResponderGroup addResponder:responder2 withPriority:1];
			[touchResponderGroup addResponder:responder3 withPriority:2];
		});

		it(@"should start with first responder after finishing touch", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withCount:2];
			[[responder3 should] receive:@selector(touchBegan:withEvent:) withCount:1];
			[[responder3 should] receive:@selector(touchEnded:withEvent:) withCount:1];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup touchIgnored:responder1]; // goes to second responder where it ignores in touchEnded
			[touchResponderGroup ccTouchEnded:touch withEvent:event]; // finishes this touch sequence at last responder
			[touchResponderGroup ccTouchBegan:touch withEvent:event]; // should go to first responder again
		});
	});

	context(@"with two ignoring responders", ^
	{
		__block id responder1;
		__block id responder2;
		__block id responder3;
		__block id responder4;

		beforeEach(^
		{
			touchResponderGroup = [[MGTouchResponderGroup alloc] init];

			responder1 = [KWMock mockForProtocol:@protocol(MGTouchResponder)];
			responder2 = [[ResponderIgnoreOnBegin alloc] init];
			responder3 = [[ResponderIgnoreOnBegin alloc] init];
			responder4 = [KWMock mockForProtocol:@protocol(MGTouchResponder)];

			[[responder1 should] receive:@selector(setTouchResponderCallback:) withArguments:touchResponderGroup];
			[[responder4 should] receive:@selector(setTouchResponderCallback:) withArguments:touchResponderGroup];

			[touchResponderGroup addResponder:responder1 withPriority:0];
			[touchResponderGroup addResponder:responder2 withPriority:1];
			[touchResponderGroup addResponder:responder3 withPriority:2];
			[touchResponderGroup addResponder:responder4 withPriority:3];
		});

		it(@"should ignore touches within two responders in begin", ^
		{
			UITouch *touch2 = [[UITouch alloc] init];
			UIEvent *event2 = [[UIEvent alloc] init];

			[[responder1 should] receive:@selector(touchBegan:withEvent:) withCount:3];
			[[responder4 should] receive:@selector(touchBegan:withEvent:) withCount:2];
			[[responder4 should] receive:@selector(touchEnded:withEvent:) withCount:2];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchBegan:touch2 withEvent:event2];
			[touchResponderGroup touchIgnored:responder1]; // goes to second and third responder where it ignores in touchBegin
			[touchResponderGroup ccTouchEnded:touch withEvent:event]; // finishes this touch sequence at last responder
			[touchResponderGroup ccTouchEnded:touch2 withEvent:event2]; // finishes this touch sequence at last responder
			[touchResponderGroup ccTouchBegan:touch withEvent:event]; // should go to first responder again
		});
	});

	context(@"with three responders", ^
	{
		__block id responder1;
		__block id responder2;
		__block id responder3;

		beforeEach(^
		{
			touchResponderGroup = [[MGTouchResponderGroup alloc] init];

			responder1 = [[ResponderIgnoreOnEnded alloc] init];
			responder2 = [[ResponderIgnoreOnEnded alloc] init];
			responder3 = [KWMock mockForProtocol:@protocol(MGTouchResponder)];

			[[responder3 should] receive:@selector(setTouchResponderCallback:) withArguments:touchResponderGroup];

			[touchResponderGroup addResponder:responder1 withPriority:0];
			[touchResponderGroup addResponder:responder2 withPriority:1];
			[touchResponderGroup addResponder:responder3 withPriority:2];
		});

		it(@"should call touchEnded on last responder", ^
		{
			[[responder3 should] receive:@selector(touchBegan:withEvent:) withCount:1];
			[[responder3 should] receive:@selector(touchEnded:withEvent:) withCount:1];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchEnded:touch withEvent:event]; // goes to second responder where it ignores in touchEnded, should replay in 3rd responder start and end
		});
	});

	context(@"with one responder", ^
	{
		__block id responder = [[ResponderMinimal alloc] init];

		beforeEach(^
		{
			touchResponderGroup = [[MGTouchResponderGroup alloc] init];
			[touchResponderGroup addResponder:responder withPriority:0];
		});

		it(@"should call the callback", ^
		{
			[[responder should] receive:@selector(setTouchResponderCallback:) withArguments:touchResponderGroup];

			[touchResponderGroup addResponder:responder withPriority:1];
		});

		it(@"should not fail when touchMoved is not implemented in responder", ^
		{
			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchMoved:touch withEvent:event];
		});

		it(@"should not fail when touchCancelled is not implemented in responder", ^
		{
			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchCancelled:touch withEvent:event];
		});

		it(@"should not fail when touchEnded is not implemented in responder", ^
		{
			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchEnded:touch withEvent:event];
		});
	});

	context(@"with two responders", ^
	{
		__block id responder1 = [KWMock mockForProtocol:@protocol(MGTouchResponder)];
		__block id responder2 = [KWMock mockForProtocol:@protocol(MGTouchResponder)];
		__block UITouch *const touch2 = [[UITouch alloc] init];
		__block UIEvent *const event2 = [[UIEvent alloc] init];

		beforeEach(^
		{
			touchResponderGroup = [[MGTouchResponderGroup alloc] init];

			[[responder1 should] receive:@selector(setTouchResponderCallback:) withArguments:touchResponderGroup];
			[[responder2 should] receive:@selector(setTouchResponderCallback:) withArguments:touchResponderGroup];

			[touchResponderGroup addResponder:responder1 withPriority:0];
			[touchResponderGroup addResponder:responder2 withPriority:1];
		});

		it(@"should call first responder", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
			[[responder2 should] receive:@selector(touchBegan:withEvent:) withCount:0];

			BOOL result = [touchResponderGroup ccTouchBegan:touch withEvent:event];

			[[theValue(result) should] beYes];
		});

		it(@"should fail when consuming from a non active responder", ^
		{
			[touchResponderGroup ccTouchBegan:touch withEvent:event];

			[[theBlock(^
			{
				[touchResponderGroup touchConsumed:responder2];
			}) should] raiseWithReason:@"You tried to consume a touch from a responder which is currently not active!"];
		});

		it(@"should fail when ignoring from a non active responder", ^
		{
			[touchResponderGroup ccTouchBegan:touch withEvent:event];

			[[theBlock(^
			{
				[touchResponderGroup touchIgnored:responder2];
			}) should] raiseWithReason:@"You tried to ignore a touch from a responder which is currently not active!"];
		});

		it(@"should call second responder", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withCount:0];
			[[responder2 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];

			[touchResponderGroup touchIgnored:responder1];
			BOOL result = [touchResponderGroup ccTouchBegan:touch withEvent:event];

			[[theValue(result) should] beYes];
		});

		it(@"should not call second responder", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withCount:1];
			[[responder2 should] receive:@selector(touchBegan:withEvent:) withCount:0];

			BOOL result = [touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup touchConsumed:responder1];

			[[theValue(result) should] beYes];
		});

		it(@"should call first responder again", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withCount:2];
			[[responder2 should] receive:@selector(touchBegan:withEvent:) withCount:0];

			BOOL result1 = [touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup touchConsumed:responder1];
			BOOL result2 = [touchResponderGroup ccTouchBegan:touch2 withEvent:event2];

			[[theValue(result1) should] beYes];
			[[theValue(result2) should] beYes];
		});

		it(@"should replay touchBegan on second responder after touch ignore in first responder", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
			[[responder2 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup touchIgnored:responder1];
		});

		it(@"should replay both touchBegan on second responder after touch ignore in first responder", ^
		{
            [[responder1 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
            [[responder1 should] receive:@selector(touchBegan:withEvent:) withArguments:touch2,event2];
			[[responder2 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
            [[responder2 should] receive:@selector(touchBegan:withEvent:) withArguments:touch2,event2];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchBegan:touch2 withEvent:event2];
			[touchResponderGroup touchIgnored:responder1];
		});

		it(@"should replay unfinished touchBegan on second responder after touch ignore in first responder", ^
		{
            [[responder1 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
            [[responder1 should] receive:@selector(touchBegan:withEvent:) withArguments:touch2,event2];
            [[responder1 should] receive:@selector(touchEnded:withEvent:) withArguments:touch2,event2];
			[[responder2 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchBegan:touch2 withEvent:event2];
			[touchResponderGroup ccTouchEnded:touch2 withEvent:event2];
			[touchResponderGroup touchIgnored:responder1];
		});

		it(@"should not fail when ignoring touch in both responders", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
			[[responder2 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup touchIgnored:responder1];
			[touchResponderGroup touchIgnored:responder2];
		});

		context(@"getting a different touch", ^
		{
			it(@"should delegate different touch even before previous touch ended", ^
			{
                [[responder1 should] receive:@selector(touchBegan:withEvent:) withCount:3];
				[[responder1 should] receive:@selector(touchEnded:withEvent:) withCount:1];

				[touchResponderGroup ccTouchBegan:touch withEvent:event];
				BOOL result = [touchResponderGroup ccTouchBegan:[[UITouch alloc] init] withEvent:event];
				[touchResponderGroup ccTouchEnded:touch withEvent:event];
				[touchResponderGroup ccTouchBegan:touch withEvent:event];

				[[theValue(result) should] beYes];
			});

			it(@"should delegate moved even before previous touch ended and new one started", ^
			{
				[[responder1 should] receive:@selector(touchBegan:withEvent:) withCount:2 arguments:touch,event];
				[[responder1 should] receive:@selector(touchBegan:withEvent:) withCount:1 arguments:touch2,event2];
				[[responder1 should] receive:@selector(touchMoved:withEvent:) withCount:1 arguments:touch,event];
				[[responder1 should] receive:@selector(touchMoved:withEvent:) withCount:1 arguments:touch2,event2];

				[touchResponderGroup ccTouchBegan:touch withEvent:event];
				[touchResponderGroup ccTouchBegan:touch2 withEvent:event2];
				[touchResponderGroup ccTouchMoved:touch2 withEvent:event2];
				[touchResponderGroup ccTouchEnded:touch withEvent:event];
				[touchResponderGroup ccTouchBegan:touch withEvent:event];
				[touchResponderGroup ccTouchMoved:touch withEvent:event];
			});

			it(@"should delegate cancelled even before previous touch ended and new one started", ^
			{
				[[responder1 should] receive:@selector(touchBegan:withEvent:) withCount:3];
				[[responder1 should] receive:@selector(touchCancelled:withEvent:) withCount:2];

				[touchResponderGroup ccTouchBegan:touch withEvent:event];
				[touchResponderGroup ccTouchBegan:touch2 withEvent:event2];
				[touchResponderGroup ccTouchCancelled:touch2 withEvent:event2];
				[touchResponderGroup ccTouchEnded:touch withEvent:event];
				[touchResponderGroup ccTouchBegan:touch withEvent:event];// new init
				[touchResponderGroup ccTouchCancelled:touch withEvent:event];
			});
		});

		it(@"should delegate moved to responder", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
			[[responder1 should] receive:@selector(touchMoved:withEvent:) withArguments:touch,event];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchMoved:touch withEvent:event];
		});

		it(@"should ignore moved if already consumed", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
			[[responder1 should] receive:@selector(touchMoved:withEvent:) withCount:0];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup touchConsumed:responder1];
			[touchResponderGroup ccTouchMoved:touch withEvent:event];
		});

		it(@"should ignore moved if not began", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
			[[responder1 should] receive:@selector(touchEnded:withEvent:) withArguments:touch,event];
			[[responder1 should] receive:@selector(touchMoved:withEvent:) withCount:0];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchEnded:touch withEvent:event];
			[touchResponderGroup ccTouchMoved:touch withEvent:event];
		});

		it(@"should delegate ended to responder", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
			[[responder1 should] receive:@selector(touchEnded:withEvent:) withArguments:touch,event];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchEnded:touch withEvent:event];
		});

		it(@"should ignore ended if already consumed", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
			[[responder1 should] receive:@selector(touchEnded:withEvent:) withCount:0];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup touchConsumed:responder1];
			[touchResponderGroup ccTouchEnded:touch withEvent:event];
		});

		it(@"should ignore ended after ended first touch", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withCount:1];
			[[responder1 should] receive:@selector(touchEnded:withEvent:) withCount:1];
			[[responder1 should] receive:@selector(touchCancelled:withEvent:) withCount:0];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchEnded:touch withEvent:event];
			[touchResponderGroup ccTouchCancelled:touch withEvent:event];
		});

		it(@"should ignore ended if not began", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
			[[responder1 should] receive:@selector(touchEnded:withEvent:) withCount:1];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchEnded:touch withEvent:event];
			[touchResponderGroup ccTouchEnded:touch withEvent:event];
		});

		it(@"should delegate cancelled to responder", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
			[[responder1 should] receive:@selector(touchCancelled:withEvent:) withArguments:touch,event];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchCancelled:touch withEvent:event];
		});

		it(@"should ignore cancelled if already consumed", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withCount:1];
			[[responder1 should] receive:@selector(touchCancelled:withEvent:) withCount:0];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup touchConsumed:responder1];
			[touchResponderGroup ccTouchCancelled:touch withEvent:event];
		});

		it(@"should ignore cancelled after cancel first touch", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:)];
			[[responder1 should] receive:@selector(touchCancelled:withEvent:) withCount:1];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchCancelled:touch withEvent:event];
			[touchResponderGroup ccTouchCancelled:touch withEvent:event];
		});

		it(@"should ignore cancelled if not began", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withArguments:touch,event];
			[[responder1 should] receive:@selector(touchEnded:withEvent:) withCount:1];
			[[responder1 should] receive:@selector(touchCancelled:withEvent:) withCount:0];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchEnded:touch withEvent:event];
			[touchResponderGroup ccTouchCancelled:touch withEvent:event];
		});

		it(@"should start with first responder after finishing with first touch", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withCount:2];
			[[responder2 should] receive:@selector(touchEnded:withEvent:) withCount:0];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup ccTouchEnded:touch withEvent:event];
			[touchResponderGroup ccTouchBegan:touch withEvent:event];
		});

		it(@"should start with first responder after finishing with second touch", ^
		{
			[[responder1 should] receive:@selector(touchBegan:withEvent:) withCount:2];
			[[responder2 should] receive:@selector(touchEnded:withEvent:) withCount:1];

			[touchResponderGroup ccTouchBegan:touch withEvent:event];
			[touchResponderGroup touchIgnored:responder1];
			[touchResponderGroup ccTouchEnded:touch withEvent:event];
			[touchResponderGroup ccTouchBegan:touch withEvent:event];
		});
	});
});

SPEC_END