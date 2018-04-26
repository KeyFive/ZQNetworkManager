//
//  ZQInterfaceConfigure.h
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/1/16.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

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

typedef NS_ENUM(NSInteger,ZQRequestErrorCode)
{
    ZQRequestErrorCodeNoSuitableNetwork = 1111,//网络状况不符合（网络不通，或者只在wifi下请求的网络请求没在wifi下）
    ZQRequestErrorCodeNoSuitableCache = 1112,//没有合适的缓存数据，只有在只请求缓存的时候使用
    ZQRequestErrorCodeCanceld = 1113,//由于请求对象被销毁，操作自动失效
};

NS_ASSUME_NONNULL_BEGIN

@protocol ZQInterfaceConfigure <NSObject>

- (NSString *)urlForRequestName:(NSString *)name userInfo:(nullable NSDictionary *)userInfo;//根据接口名称返回接口url
- (ZQRequestMenthod)methodForRequestName:(NSString *)name userInfo:(nullable NSDictionary *)userInfo;//调用接口的方法POST/GET

@optional

- (AFSecurityPolicy *)customerSecurityPolicy;//是否自定义加密策略
- (NSURLSessionAuthChallengeDisposition (^) (NSURLSession * _Nonnull session, NSURLAuthenticationChallenge * _Nonnull challenge, NSURLCredential *__autoreleasing  _Nullable * _Nullable credential))sessionAuthChallengeDispositionBlock;
- (BOOL)allowConcurrencyRequestName:(NSString *)name;//默认发起同一个请求会覆盖上一次请求，上一个请求不会发生回调
- (NSTimeInterval)timeoutInterval;
- (NSString *)domainForLink;//用来检测网络可用性
- (BOOL)isWiFiOnlyForRequestName:(NSString *)name;//是否只在wifi情况下进行请求
- (NSSet *)acceptableContentTypesForRequest;//需要复写acceptableContentTypes的可实现此方法否则用AF默认的
- (NSDictionary *)httpHeadFiledsForRequestName:(NSString *)requestName;//需要设置得请求头
- (ZQRequestPolicy)requestPolicyForRequestName:(NSString *)name userInfo:(nullable NSDictionary *)userInfo;//请求策略
- (ZQCachePolicy)cachePolicyForRequestName:(NSString *)name userInfo:(nullable NSDictionary *)userInfo;//缓存策略
- (NSTimeInterval)cacheValidityTimeIntervalForRequestName:(NSString *)name userInfo:(nullable NSDictionary *)userInfo;//缓存的有效期
- (ZQDealPolicy)dealPolicyForRequestName:(NSString *)name userInfo:(nullable NSDictionary *)userInfo;

@end

@protocol ZQInterfaceActivitConfigure <NSObject>

- (nullable NSDictionary *)responseInfoFromObject:(id)responseObject requestName:(NSString *)requestName error:(NSError **)error;

@optional
- (NSDictionary *)paramsDealForRequestName:(NSString *)name params:(nullable NSDictionary *)params;//需要对参数对额外处理得可实现此方法
- (NSError *)dealErrorInfoWithError:(NSError *)error requestName:(NSString *)requestName;
- (NSData *)fileDataWithData:(NSData *)fileData requestName:(NSString *)requestName;//压缩上传文件大小时使用
- (void)networkActivityStartForRequestName:(NSString *)name;//开始请求网络（main thread）
- (void)networkActivityEndForRequestName:(NSString *)name;//结束请求网络(main thread)

@end

NS_ASSUME_NONNULL_END
