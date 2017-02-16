//
//  ZQNetworkOperation.m
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/2/15.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import "ZQNetworkOperation.h"

@interface ZQNetworkOperation()

@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, assign) BOOL operationExecuting;
@property (nonatomic, assign) BOOL operationFinished;

@end

@implementation ZQNetworkOperation

#pragma mark - initial

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.lock = [[NSLock alloc] init];
    }
    return self;
}

#pragma mark - private method

- (void)start
{
    if (self.cancelled)
    {
        [self finisheOperation];
        return;
    }
    if (self.isReady)
    {
        [self executeOperation];
        self.block();
    }
    else
    {
        NSAssert(FALSE, @"operation is not ready");
        [self finisheOperation];
    }
}

#pragma mark - property

- (BOOL)isAsynchronous
{
    return YES;
}

- (BOOL)isExecuting
{
    return self.operationExecuting;
}

- (BOOL)isFinished
{
    return self.operationFinished;
}

#pragma mark - 更改状态

- (void)executeOperation
{
    [self.lock lock];
    [self willChangeValueForKey:@"isExecuting"];
    self.operationExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self.lock unlock];
}

- (void)finisheOperation
{
    [self.lock lock];
    [self willChangeValueForKey:@"isFinished"];
     self.operationExecuting = NO;
    self.operationFinished = YES;
    [self didChangeValueForKey:@"isFinished"];
    [self.lock unlock];
}

@end
