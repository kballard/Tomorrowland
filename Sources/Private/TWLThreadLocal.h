//
//  TWLThreadLocal.h
//  Tomorrowland
//
//  Created by Kevin Ballard on 1/2/18.
//  Copyright © 2018 Kevin Ballard. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Gets the main context thread local flag.
BOOL TWLGetMainContextThreadLocalFlag(void);
/// Sets the main context thread local flag.
void TWLSetMainContextThreadLocalFlag(BOOL value);
/// Executes a block with the main context thread local flag set.
///
/// This guarantees that the flag will be unset even if an exception occurs.
///
/// \note This will unset the flag even if it was set prior to this function being invoked.
void TWLExecuteBlockWithMainContextThreadLocalFlag(NS_NOESCAPE dispatch_block_t _Nonnull block);

/// Enqueues a block onto the thread-local block list.
///
/// \note Any blocks left on the thread-local block list when the thread is exited are leaked. It is
/// an error to not dequeue all blocks before letting the thread die.
void TWLEnqueueThreadLocalBlock(dispatch_block_t _Nonnull block);
/// Dequeues a block from the thread-local block list.
///
/// Blocks are dequeued in FIFO order.
dispatch_block_t _Nullable TWLDequeueThreadLocalBlock(void);

