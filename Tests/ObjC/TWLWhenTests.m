//
//  TWLWhenTests.m
//  TomorrowlandTests
//
//  Created by Lily Ballard on 1/7/18.
//  Copyright © 2018 Lily Ballard.
//
//  Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
//  http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
//  <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
//  option. This file may not be copied, modified, or distributed
//  except according to those terms.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+TWLPromise.h"
@import Tomorrowland;
#import <stdatomic.h>

@interface TWLWhenTests : XCTestCase

@end

@implementation TWLWhenTests

- (void)testWhen {
    NSMutableArray<TWLPromise<NSNumber*,NSString*> *> *promises = [NSMutableArray array];
    for (NSUInteger i = 1; i <= 5; ++i) {
        [promises addObject:[TWLPromise<NSNumber*,NSString*> newOnContext:TWLContext.utility withBlock:^(TWLResolver<NSNumber*,NSString*> * _Nonnull resolver) {
            [resolver fulfillWithValue:@(i*2)];
        }]];
    }
    TWLPromise<NSArray<NSNumber*>*,NSString*> *promise = [TWLPromise<NSNumber*,NSString*> whenFulfilled:promises];
    XCTestExpectation *expectation = TWLExpectationSuccessWithValue(promise, (@[@2,@4,@6,@8,@10]));
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testWhenRejected {
    NSMutableArray<TWLPromise<NSNumber*,NSString*> *> *promises = [NSMutableArray array];
    for (NSUInteger i = 1; i <= 5; ++i) {
        [promises addObject:[TWLPromise<NSNumber*,NSString*> newOnContext:TWLContext.utility withBlock:^(TWLResolver<NSNumber*,NSString*> * _Nonnull resolver) {
            if (i == 3) {
                [resolver rejectWithError:@"error"];
            } else {
                [resolver fulfillWithValue:@(i*2)];
            }
        }]];
    }
    TWLPromise<NSArray<NSNumber*>*,NSString*> *promise = [TWLPromise<NSNumber*,NSString*> whenFulfilled:promises];
    XCTestExpectation *expectation = TWLExpectationErrorWithError(promise, @"error");
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testWhenCancelled {
    NSMutableArray<TWLPromise<NSNumber*,NSString*> *> *promises = [NSMutableArray array];
    for (NSUInteger i = 1; i <= 5; ++i) {
        [promises addObject:[TWLPromise<NSNumber*,NSString*> newOnContext:TWLContext.utility withBlock:^(TWLResolver<NSNumber*,NSString*> * _Nonnull resolver) {
            if (i == 3) {
                [resolver cancel];
            } else {
                [resolver fulfillWithValue:@(i*2)];
            }
        }]];
    }
    TWLPromise<NSArray<NSNumber*>*,NSString*> *promise = [TWLPromise<NSNumber*,NSString*> whenFulfilled:promises];
    XCTestExpectation *expectation = TWLExpectationCancel(promise);
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testWhenRejectedWithCancelOnFailureCancelsInput {
    dispatch_semaphore_t sema = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    NSMutableArray<TWLPromise*> *promises = [NSMutableArray array];
    NSMutableArray<XCTestExpectation*> *expectations = [NSMutableArray array];
    for (NSUInteger i = 1; i <= 5; ++i) {
        XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:[NSString stringWithFormat:@"promise %tu", i]];
        TWLPromise *promise = [TWLPromise<NSNumber*,NSString*> newOnContext:TWLContext.utility withBlock:^(TWLResolver<NSNumber *,NSString *> * _Nonnull resolver) {
            if (i == 3) {
                [resolver rejectWithError:@"error"];
                [expectation fulfill];
            } else {
                [resolver whenCancelRequestedOnContext:TWLContext.immediate handler:^(TWLResolver<NSNumber *,NSString *> * _Nonnull resolver) {
                    [resolver cancel];
                }];
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                dispatch_semaphore_signal(sema);
                [resolver fulfillWithValue:@(i*2)];
            }
        }];
        if (i != 3) {
            [promise whenCancelledOnContext:TWLContext.utility handler:^{
                [expectation fulfill];
            }];
        }
        [expectations addObject:expectation];
        [promises addObject:promise];
    }
    TWLPromise *promise = [TWLPromise whenFulfilled:promises cancelOnFailure:YES];
    XCTestExpectation *expectation = TWLExpectationErrorWithError(promise, @"error");
    [expectations addObject:expectation];
    [self waitForExpectations:@[expectation] timeout:1];
    dispatch_semaphore_signal(sema); // let the promises empty out
}

- (void)testWhenCancelledWithCancelOnFailureCancelsInput {
    dispatch_semaphore_t sema = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    NSMutableArray<TWLPromise*> *promises = [NSMutableArray array];
    NSMutableArray<XCTestExpectation*> *expectations = [NSMutableArray array];
    for (NSUInteger i = 1; i <= 5; ++i) {
        XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:[NSString stringWithFormat:@"promise %tu", i]];
        TWLPromise *promise = [TWLPromise<NSNumber*,NSString*> newOnContext:TWLContext.utility withBlock:^(TWLResolver<NSNumber *,NSString *> * _Nonnull resolver) {
            if (i == 3) {
                [resolver cancel];
                [expectation fulfill];
            } else {
                [resolver whenCancelRequestedOnContext:TWLContext.immediate handler:^(TWLResolver<NSNumber *,NSString *> * _Nonnull resolver) {
                    [resolver cancel];
                }];
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                dispatch_semaphore_signal(sema);
                [resolver fulfillWithValue:@(i*2)];
            }
        }];
        if (i != 3) {
            [promise whenCancelledOnContext:TWLContext.utility handler:^{
                [expectation fulfill];
            }];
        }
        [expectations addObject:expectation];
        [promises addObject:promise];
    }
    TWLPromise *promise = [TWLPromise whenFulfilled:promises cancelOnFailure:YES];
    XCTestExpectation *expectation = TWLExpectationCancel(promise);
    [expectations addObject:expectation];
    [self waitForExpectations:@[expectation] timeout:1];
    dispatch_semaphore_signal(sema); // let the promises empty out
}

- (void)testWhenCancelledByDefaultDoesntCancelInput {
    dispatch_semaphore_t sema = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    NSMutableArray<TWLPromise*> *promises = [NSMutableArray array];
    NSMutableArray<XCTestExpectation*> *expectations = [NSMutableArray array];
    for (NSUInteger i = 1; i <= 5; ++i) {
        XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:[NSString stringWithFormat:@"promise %tu", i]];
        TWLPromise<NSNumber*,NSString*> *promise = [TWLPromise<NSNumber*,NSString*> newOnContext:TWLContext.utility withBlock:^(TWLResolver<NSNumber *,NSString *> * _Nonnull resolver) {
            if (i == 3) {
                [resolver cancel];
                [expectation fulfill];
            } else {
                [resolver whenCancelRequestedOnContext:TWLContext.immediate handler:^(TWLResolver<NSNumber *,NSString *> * _Nonnull resolver) {
                    [resolver cancel];
                }];
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                dispatch_semaphore_signal(sema);
                [resolver fulfillWithValue:@(i*2)];
            }
        }];
        if (i != 3) {
            [promise thenOnContext:TWLContext.utility handler:^(NSNumber * _Nonnull value) {
                XCTAssertEqualObjects(value, @(i*2));
                [expectation fulfill];
            }];
        }
        [expectations addObject:expectation];
        [promises addObject:promise];
    }
    TWLPromise *promise = [TWLPromise whenFulfilled:promises];
    XCTestExpectation *expectation = TWLExpectationCancel(promise);
    [self waitForExpectations:@[expectation] timeout:1];
    dispatch_semaphore_signal(sema); // let the promises empty out
    [self waitForExpectations:expectations timeout:1];
}

- (void)testWhenEmptyInput {
    TWLPromise *promise = [TWLPromise whenFulfilled:@[]];
    XCTestExpectation *expectation = TWLExpectationSuccessWithValue(promise, @[]);
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testWhenDuplicatePromise {
    TWLPromise *dummy = [TWLPromise newFulfilledWithValue:@42];
    TWLPromise *promise = [TWLPromise whenFulfilled:@[dummy,dummy,dummy]];
    XCTestExpectation *expectation = TWLExpectationSuccessWithValue(promise, (@[@42,@42,@42]));
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testWhenCancelPropagation {
    dispatch_semaphore_t sema = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    TWLPromise *promise;
    NSMutableArray<XCTestExpectation*> *expectations = [NSMutableArray new];
    @autoreleasepool {
        NSMutableArray<TWLPromise*> *promises = [NSMutableArray new];
        for (NSUInteger i = 0; i < 3; ++i) {
            TWLPromise *promise = [TWLPromise newOnContext:TWLContext.immediate withBlock:^(TWLResolver * _Nonnull resolver) {
                [resolver whenCancelRequestedOnContext:TWLContext.immediate handler:^(TWLResolver * _Nonnull resolver) {
                    [resolver cancel];
                }];
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                    dispatch_semaphore_signal(sema);
                    [resolver rejectWithError:@"foo"];
                });
            }];
            XCTestExpectation *expectation = TWLExpectationCancel(promise);
            [promises addObject:promise];
            [expectations addObject:expectation];
        }
        promise = [TWLPromise whenFulfilled:promises];
    }
    [promise requestCancel];
    dispatch_semaphore_signal(sema);
    [self waitForExpectations:expectations timeout:1];
}

- (void)testWhenWithPreFulfilledInput {
    // If all inputs have already fulfilled, return a pre-fulfilled promise
    NSMutableArray<TWLPromise<NSNumber*,NSString*>*> *promises = [NSMutableArray new];
    for (NSUInteger i = 0; i < 3; ++i) {
        [promises addObject:[TWLPromise<NSNumber*,NSString*> newFulfilledWithValue:@(i)]];
    }
    __auto_type promise = [TWLPromise<NSNumber*,NSString*> whenFulfilled:promises qos:QOS_CLASS_BACKGROUND];
    NSArray<NSNumber*> *value;
    XCTAssertTrue([promise getValue:&value error:NULL]);
    XCTAssertEqualObjects(value, (@[@0,@1,@2]));
}

- (void)testWhenWithPreRejectedInput {
    // If any input has already rejected, return a pre-rejected promise
    NSMutableArray<TWLPromise<NSNumber*,NSString*>*> *promises = [NSMutableArray new];
    for (NSUInteger i = 0; i < 3; ++i) {
        [promises addObject:(i == 2
                             ? [TWLPromise<NSNumber*,NSString*> newRejectedWithError:@"foo"]
                             : [TWLPromise<NSNumber*,NSString*> newOnContext:TWLContext.immediate withBlock:^(TWLResolver<NSNumber *,NSString *> * _Nonnull resolver) {
            [resolver whenCancelRequestedOnContext:TWLContext.immediate handler:^(TWLResolver<NSNumber *,NSString *> * _Nonnull innerResolver) {
                [resolver cancel]; // capture resolver
            }];
        }])];
    }
    __auto_type promise = [TWLPromise<NSNumber*,NSString*> whenFulfilled:promises qos:QOS_CLASS_BACKGROUND];
    NSString *error;
    XCTAssertTrue([promise getValue:NULL error:&error]);
    XCTAssertEqualObjects(error, @"foo");
}

- (void)testWhenWithPreCancelledInput {
    // If any input has already cancelled, return a pre-cancelled promise
    NSMutableArray<TWLPromise<NSNumber*,NSString*>*> *promises = [NSMutableArray new];
    for (NSUInteger i = 0; i < 3; ++i) {
        [promises addObject:(i == 2
                             ? [TWLPromise<NSNumber*,NSString*> newCancelled]
                             : [TWLPromise<NSNumber*,NSString*> newOnContext:TWLContext.immediate withBlock:^(TWLResolver<NSNumber *,NSString *> * _Nonnull resolver) {
            [resolver whenCancelRequestedOnContext:TWLContext.immediate handler:^(TWLResolver<NSNumber *,NSString *> * _Nonnull innerResolver) {
                [resolver cancel]; // capture resolver
            }];
        }])];
    }
    __auto_type promise = [TWLPromise<NSNumber*,NSString*> whenFulfilled:promises qos:QOS_CLASS_BACKGROUND];
    id value, error;
    XCTAssertTrue([promise getValue:&value error:&error]);
    XCTAssertNil(value);
    XCTAssertNil(error);
}

#pragma mark -

- (void)testRace {
    dispatch_semaphore_t sema = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    NSMutableArray<TWLPromise*> *promises = [NSMutableArray array];
    for (NSUInteger i = 1; i <= 5; ++i) {
        [promises addObject:[TWLPromise newOnContext:TWLContext.utility withBlock:^(TWLResolver * _Nonnull resolver) {
            if (i != 3) {
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                dispatch_semaphore_signal(sema);
            }
            [resolver fulfillWithValue:@(i*2)];
        }]];
    }
    TWLPromise *promise = [TWLPromise race:promises];
    XCTestExpectation *expectation = TWLExpectationSuccessWithValue(promise, @6);
    [self waitForExpectations:@[expectation] timeout:1];
    dispatch_semaphore_signal(sema);
}

- (void)testRaceRejected {
    dispatch_semaphore_t sema = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    NSMutableArray<TWLPromise*> *promises = [NSMutableArray array];
    for (NSUInteger i = 1; i <= 5; ++i) {
        [promises addObject:[TWLPromise newOnContext:TWLContext.utility withBlock:^(TWLResolver * _Nonnull resolver) {
            if (i == 3) {
                [resolver rejectWithError:@"foo"];
            } else {
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                dispatch_semaphore_signal(sema);
                [resolver fulfillWithValue:@(i*2)];
            }
        }]];
    }
    TWLPromise *promise = [TWLPromise race:promises];
    XCTestExpectation *expectation = TWLExpectationErrorWithError(promise, @"foo");
    [self waitForExpectations:@[expectation] timeout:1];
    dispatch_semaphore_signal(sema);
}

- (void)testRaceCancelled {
    dispatch_semaphore_t sema = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    NSMutableArray<TWLPromise*> *promises = [NSMutableArray array];
    for (NSUInteger i = 1; i <= 5; ++i) {
        [promises addObject:[TWLPromise newOnContext:TWLContext.utility withBlock:^(TWLResolver * _Nonnull resolver) {
            if (i == 3) {
                [resolver cancel];
            } else {
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                dispatch_semaphore_signal(sema);
                [resolver fulfillWithValue:@(i*2)];
            }
        }]];
    }
    TWLPromise *promise = [TWLPromise race:promises];
    XCTestExpectation *expectation = TWLExpectationSuccess(promise);
    dispatch_semaphore_signal(sema);
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testRaceAllCancelled {
    NSMutableArray<TWLPromise*> *promises = [NSMutableArray array];
    for (NSUInteger i = 1; i <= 5; ++i) {
        [promises addObject:[TWLPromise newOnContext:TWLContext.utility withBlock:^(TWLResolver * _Nonnull resolver) {
            [resolver cancel];
        }]];
    }
    TWLPromise *promise = [TWLPromise race:promises];
    XCTestExpectation *expectation = TWLExpectationCancel(promise);
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testRaceCancelRemaining {
    dispatch_semaphore_t sema = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    NSMutableArray<TWLPromise*> *promises = [NSMutableArray array];
    NSMutableArray<XCTestExpectation*> *expectations = [NSMutableArray array];
    for (NSUInteger i = 1; i <= 5; ++i) {
        XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:[NSString stringWithFormat:@"promise %tu", i]];
        TWLPromise *promise = [TWLPromise<NSNumber*,NSString*> newOnContext:TWLContext.utility withBlock:^(TWLResolver<NSNumber *,NSString *> * _Nonnull resolver) {
            if (i == 3) {
                [resolver fulfillWithValue:@(i*2)];
                [expectation fulfill];
            } else {
                [resolver whenCancelRequestedOnContext:TWLContext.immediate handler:^(TWLResolver<NSNumber *,NSString *> * _Nonnull resolver) {
                    [expectation fulfill];
                    [resolver cancel];
                }];
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                dispatch_semaphore_signal(sema);
                [resolver fulfillWithValue:@(i*2)];
            }
        }];
        if (i != 3) {
            [promise inspect:^(id _Nullable value, id  _Nullable error) {
                XCTAssert(value == nil && error == nil, @"expected promise cancellation");
                [expectation fulfill];
            }];
        }
        [promises addObject:promise];
        [expectations addObject:expectation];
    }
    TWLPromise *promise = [TWLPromise race:promises cancelRemaining:YES];
    XCTestExpectation *expectation = TWLExpectationSuccessWithValue(promise, @6);
    [expectations addObject:expectation];
    [self waitForExpectations:expectations timeout:1];
    dispatch_semaphore_signal(sema);
}

- (void)testRaceEmptyInput {
    TWLPromise *promise = [TWLPromise race:@[]];
    XCTestExpectation *expectation = TWLExpectationCancel(promise);
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testRaceDuplicateInput {
    TWLPromise *dummy = [TWLPromise newFulfilledWithValue:@42];
    TWLPromise *promise = [TWLPromise race:@[dummy,dummy,dummy]];
    XCTestExpectation *expectation = TWLExpectationSuccessWithValue(promise, @42);
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testRaceCancelPropagation {
    dispatch_semaphore_t sema = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    TWLPromise *promise;
    NSMutableArray<XCTestExpectation*> *expectations = [NSMutableArray new];
    @autoreleasepool {
        NSMutableArray<TWLPromise*> *promises = [NSMutableArray new];
        for (NSUInteger i = 0; i < 3; ++i) {
            TWLPromise *promise = [TWLPromise newOnContext:TWLContext.immediate withBlock:^(TWLResolver * _Nonnull resolver) {
                [resolver whenCancelRequestedOnContext:TWLContext.immediate handler:^(TWLResolver * _Nonnull resolver) {
                    [resolver cancel];
                }];
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                    dispatch_semaphore_signal(sema);
                    [resolver rejectWithError:@"foo"];
                });
            }];
            XCTestExpectation *expectation = TWLExpectationCancel(promise);
            [promises addObject:promise];
            [expectations addObject:expectation];
        }
        promise = [TWLPromise race:promises];
    }
    [promise requestCancel];
    dispatch_semaphore_signal(sema);
    [self waitForExpectations:expectations timeout:1];
}

- (void)testRaceWithPreResolvedInput {
    // If any input has already fulfilled
    {
        NSMutableArray<TWLPromise<NSNumber*,NSString*>*> *promises = [NSMutableArray new];
        for (NSUInteger i = 0; i < 3; ++i) {
            [promises addObject:[TWLPromise<NSNumber*,NSString*> newFulfilledWithValue:@(i)]];
        }
        __auto_type promise = [TWLPromise<NSNumber*,NSString*> race:promises];
        NSNumber *value;
        XCTAssertTrue([promise getValue:&value error:NULL]);
        XCTAssertEqualObjects(value, @0);
    }
    // If any input has already rejected
    {
        NSMutableArray<TWLPromise<NSString*,NSNumber*>*> *promises = [NSMutableArray new];
        for (NSUInteger i = 0; i < 3; ++i) {
            [promises addObject:[TWLPromise<NSString*,NSNumber*> newRejectedWithError:@(i)]];
        }
        __auto_type promise = [TWLPromise<NSString*,NSNumber*> race:promises];
        NSNumber *error;
        XCTAssertTrue([promise getValue:NULL error:&error]);
        XCTAssertEqualObjects(error, @0);
    }
}

- (void)testRaceWithAllInputsPreCancelled {
    // If all inputs were already cancelled, when should return a cancelled promise.
    // Note: This is a fairly crappy test in that when implicitly uses the .utility QoS to process
    // asynchronous cancellation. There's nothing we can do to prevent the race with it, so this
    // test exists just in case it ever trips.
    NSMutableArray<TWLPromise<NSString*,NSNumber*>*> *promises = [NSMutableArray new];
    for (NSUInteger i = 0; i < 3; ++i) {
        [promises addObject:[TWLPromise<NSString*,NSNumber*> newCancelled]];
    }
    __auto_type promise = [TWLPromise<NSString*,NSNumber*> race:promises];
    NSString *value;
    NSNumber *error;
    XCTAssertTrue([promise getValue:&value error:&error]);
    XCTAssertNil(value);
    XCTAssertNil(error);
}

@end
