//
//  ZQNetworkCacheCenter.h
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/1/22.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZQRequestModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZQNetworkCacheCenter : NSObject

+ (instancetype)cacheCenterWithName:(NSString *)cacheName;
- (instancetype)initWithCacheName:(NSString *)cacheName;

- (nullable NSDictionary *)cacheInfoForRequest:(ZQRequestModel *)request;
- (void)cacheResponseInfo:(NSDictionary *)responseInfo forRequest:(ZQRequestModel *)request;
- (void)clearAllDiskCache;
- (NSInteger)allDiskCacheCount;

@end

NS_ASSUME_NONNULL_END
