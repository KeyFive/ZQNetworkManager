//
//  ZQNetworkOperation.h
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/2/15.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YYCategories/YYCategories.h>
#import "ZQInterfaceConfigure.h"
#import "ZQRequestModel.h"

@interface ZQNetworkOperation : NSOperation

@property (nonatomic, strong) ZQRequestModel *request;
@property (nonatomic, copy) NSString *requestName;
@property (nonatomic, copy) void(^block)(void);//执行的block
@property (nonatomic, copy) ZQRequestFinishedBlock responseBlock;
- (void)finisheOperation;//结束操作

@end
