//
//  ZQNetworkOperation.h
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/2/15.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YYCategories/YYCategories.h>

@interface ZQNetworkOperation : NSOperation

@property (nonatomic, strong) void(^block)(void);//执行的block
- (void)finisheOperation;//结束操作

@end
