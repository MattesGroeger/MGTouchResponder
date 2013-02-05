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

@protocol MGTouchResponder;

@protocol MGTouchResponderCallback

/**
* Store any data you want to pass from one responder to the next one in this
* dictionary. It will be cleared for the next touch interaction.
*/
@property (nonatomic, strong, readonly) NSMutableDictionary *userInfo;

/**
* Call this if the responder doesn't care about the touches. All touches will
* be delegated and replayed on the next TouchResponder.
*/
- (void)touchIgnored:(id <MGTouchResponder>)originator;

/**
* Call this if the responder used/consumed the touches. Further delegation is
* not necessary. All following responders will never know about the touches.
*/
- (void)touchConsumed:(id <MGTouchResponder>)originator;

@end