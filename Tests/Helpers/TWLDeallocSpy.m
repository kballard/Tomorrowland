//
//  TWLDeallocSpy.m
//  TomorrowlandTests
//
//  Created by Lily Ballard on 4/5/19.
//  Copyright © 2019 Lily Ballard. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
//  http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
//  <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
//  option. This file may not be copied, modified, or distributed
//  except according to those terms.
//

#import "TWLDeallocSpy.h"

@implementation TWLDeallocSpy {
    void (^_handler)(void);
}

+ (instancetype)newWithHandler:(void (^)(void))handler {
    return [[self alloc] initWithHandler:handler];
}

- (instancetype)initWithHandler:(void (^)(void))handler {
    if ((self = [super init])) {
        _handler = handler;
    }
    return self;
}

- (void)dealloc {
    _handler();
}
@end
