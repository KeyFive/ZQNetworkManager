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

@property (nonatomic, strong, readonly) void(^finishedBlock)(void);//调用此block标明operation结束
@property (nonatomic, strong) void(^block)(void);//执行的block

@end
