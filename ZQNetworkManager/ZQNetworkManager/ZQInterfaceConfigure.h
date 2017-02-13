//
//  ZQInterfaceConfigure.h
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/1/16.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef  void(^ZQRequestFinishedBlock)( NSDictionary * __nullable responseObject, NSError * __nullable error);

typedef NS_ENUM(NSUInteger, ZQRequestMenthod)
{
    ZQRequestMenthodGET = 1,
    ZQRequestMenthodPOST
};

typedef NS_ENUM(NSUInteger, ZQRequestPolicy)
{
    ZQRequestPolicyDefault = 1,
    ZQRequestPolicyNetThenCache = ZQRequestPolicyDefault,//如果有网洛则从网络获取，没有则取缓存
    ZQRequestPolicyCacheThenNet,
    ZQRequestPolicyOnlyCache,//只取缓存
    ZQRequestPolicyOnlyNet//只取网络
};

typedef NS_ENUM(NSUInteger, ZQCachePolicy)
{
    ZQCachePolicyDefault = 1,
    ZQCachePolicyMemory = ZQCachePolicyDefault,//存储在内存中
    ZQCachePolicyDisk,//存储在硬盘中
    ZQCachePolicyUnion,//两个都有
    ZQCachePolicyNone//没有缓存
};

typedef NS_ENUM(NSUInteger, ZQDealPolicy)//即时处理，或者允许延时处理
{
    ZQDealPolicyImmediately = 1,
    ZQDealPolicyAllowDelay
};

NS_ASSUME_NONNULL_BEGIN

@protocol ZQInterfaceConfigure <NSObject>

- (NSString *)urlForRequestName:(NSString *)name userInfo:(nullable NSDictionary *)userInfo;//根据接口名称返回接口url
- (ZQRequestMenthod)methodForRequestName:(NSString *)name userInfo:(nullable NSDictionary *)userInfo;//调用接口的方法POST/GET

@optional

- (NSString *)domainForLink;//用来检测网络可用性
- (BOOL)isWifiOnlyForRequestName:(NSString *)name;//是否只在wifi情况下进行请求
- (NSSet *)acceptableContentTypesForRequestName:(NSString *)name;//需要复写acceptableContentTypes的可实现此方法否则用AF默认的
- (NSDictionary *)httpHeadFiledsForRequestName:(NSString *)name;//需要设置得请求头
- (ZQRequestPolicy)requestPolicyForRequestName:(NSString *)name userInfo:(nullable NSDictionary *)userInfo;//请求策略
- (ZQCachePolicy)cachePolicyForRequestName:(NSString *)name userInfo:(nullable NSDictionary *)userInfo;//缓存策略
- (NSTimeInterval)cacheValidityTimeIntervalForRequestName:(NSString *)name userInfo:(nullable NSDictionary *)userInfo;//缓存的有效期
- (ZQDealPolicy)dealPolicyForRequestName:(NSString *)name userInfo:(nullable NSDictionary *)userInfo;

@end

@protocol ZQInterfaceActivitConfigure <NSObject>

- (nullable NSDictionary *)responseInfoFromObject:(id)responseObject error:(NSError **)error;

@optional
- (NSDictionary *)paramsDealForRequestName:(NSString *)name params:(nullable NSDictionary *)params;//需要对参数对额外处理得可实现此方法
- (NSData *)fileDataWithData:(NSData *)fileData;//压缩上传文件大小时使用
- (void)networkActivityStartForRequestName:(NSString *)name;//开始请求网络（main thread）
- (void)networkActivityEndForRequestName:(NSString *)name;//结束请求网络(main thread)

@end

NS_ASSUME_NONNULL_END
