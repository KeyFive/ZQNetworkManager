//
//  ZQNetworkCacheCenter.m
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/1/22.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import "ZQNetworkCacheCenter.h"
#import <YYCache/YYCache.h>
#import <YYCategories/YYCategories.h>

NSString * const ZQCacheDateKey = @"zq_cache_date_key";
NSString * const ZQCacheNoParamsKey = @"zq_cache_no_params_key";

@interface ZQNetworkCacheCenter()

@property (nonatomic, copy) NSString *cacheName;
@property (nonatomic, strong) YYCache *cache;
@property (nonatomic, strong) YYMemoryCache *memoryCache;
@property (nonatomic, strong) YYDiskCache *diskCache;

@end


static ZQNetworkCacheCenter *cacheCenter = nil;

@implementation ZQNetworkCacheCenter

#pragma mark - class method
+ (instancetype)cacheCenterWithName:(NSString *)cacheName
{
    return [[self alloc] initWithCacheName:cacheName];
}

#pragma mark - initial method

- (instancetype)initWithCacheName:(NSString *)cacheName
{
    self = [super init];
    if (self)
    {
        self.cacheName = cacheName;
    }
    return self;
}

#pragma mark - public method

- (NSInteger)allDiskCacheCount
{
    return self.cache.diskCache.totalCount + self.diskCache.totalCount;
}

- (void)clearAllDiskCache
{
    [self.cache.diskCache removeAllObjects];
    [self.diskCache removeAllObjects];
}

- (nullable NSDictionary *)cacheInfoForRequest:(ZQRequestModel *)request
{
    NSString *key = [request.params jsonPrettyStringEncoded];;
    if (key)
    {
        key = [key md5String];
    }
    else
    {
        key = ZQCacheNoParamsKey;
    }
    NSDictionary *cacheInfo = [self cacheInfoForName:request.name Key:key policy:request.cachePolicy];
    if (cacheInfo)
    {
        cacheInfo = [self validCacheInfo:cacheInfo timeInterval:request.cacheValidityTimeInterval];
        if (!cacheInfo)
        {
            [self cacheResponseInfo:nil name:request.name key:key policy:request.cachePolicy];//删除过期缓存
        }
    }
    return cacheInfo;
}

- (void)cacheResponseInfo:(NSDictionary *)responseInfo forRequest:(ZQRequestModel *)request
{
    if (!responseInfo || responseInfo.allKeys.count == 0)
    {
        return;
    }
    NSString *key = [request.params jsonPrettyStringEncoded];;
    if (key)
    {
        key = [key md5String];
    }
    else
    {
        key = ZQCacheNoParamsKey;
    }
    [self cacheResponseInfo:responseInfo name:request.name key:key policy:request.cachePolicy];
}

#pragma mark - private method

- (nullable NSDictionary *)validCacheInfo:(NSDictionary *)cacheInfo timeInterval:(NSTimeInterval)timeInterval
{
    NSMutableDictionary *validCacheInfo = [NSMutableDictionary dictionaryWithDictionary:cacheInfo];
    NSDate *cacheDate = [cacheInfo objectForKey:ZQCacheDateKey];
    NSDate *now = [NSDate date];
    if ([now timeIntervalSinceDate:cacheDate] < timeInterval)
    {
        [validCacheInfo removeObjectForKey:ZQCacheDateKey];
    }
    else
    {
        validCacheInfo = nil;
    }
    return validCacheInfo;
}

- (void)cacheResponseInfo:(NSDictionary *)responseInfo name:(NSString *)name key:(NSString *)key policy:(ZQCachePolicy)cachePolicy
{
    NSMutableDictionary *cacheInfo = nil;
    if (responseInfo)
    {
        cacheInfo = [NSMutableDictionary dictionaryWithDictionary:responseInfo];
        [cacheInfo setObject:[NSDate date] forKey:ZQCacheDateKey];
    }
    switch (cachePolicy)
    {
        case ZQCachePolicyMemory:
        {
            [self memoryCacheResponseInfo:cacheInfo name:name key:key];
            break;
        }
        case ZQCachePolicyDisk:
        {
            [self diskCacheResponseInfo:cacheInfo name:name key:key];
            break;
        }
        case ZQCachePolicyUnion:
        {
            [self unionCacheResponseInfo:cacheInfo name:name key:key];
            break;
        }
        default:
            break;
    }
}

- (void)memoryCacheResponseInfo:(NSDictionary *)responseInfo name:(NSString *)name key:(NSString *)key
{
    if (responseInfo)
    {
        NSDictionary *cacheInfo = responseInfo;
        if ([key isEqualToString:ZQCacheNoParamsKey])
        {
            cacheInfo = @{key:cacheInfo};
        }
        else
        {
            NSDictionary *inCacheInfo = [self.memoryCache objectForKey:name];
            if (!inCacheInfo)
            {
                inCacheInfo = @{};
            }
            NSMutableDictionary *allCacheInfo = [NSMutableDictionary dictionaryWithDictionary:inCacheInfo];
            [allCacheInfo setObject:responseInfo forKey:key];
            cacheInfo = allCacheInfo;
        }
        [self.memoryCache setObject:cacheInfo forKey:name];
    }
    else
    {
        NSDictionary *cacheInfo = [self.memoryCache objectForKey:name];
        if (cacheInfo && cacheInfo.allKeys.count > 0)
        {
            if ([key isEqualToString:ZQCacheNoParamsKey])
            {
                [self.memoryCache removeObjectForKey:name];
            }
            else
            {
                NSMutableDictionary *newCacheInfo = [NSMutableDictionary dictionaryWithDictionary:cacheInfo];
                [newCacheInfo removeObjectForKey:key];
                if (newCacheInfo.allKeys.count == 0)
                {
                    [self.memoryCache removeObjectForKey:name];
                }
                else
                {
                    [self.memoryCache setObject:newCacheInfo forKey:name];
                }
            }
        }
    }
}

- (void)diskCacheResponseInfo:(NSDictionary *)responseInfo name:(NSString *)name key:(NSString *)key
{
    if (responseInfo)
    {
        NSDictionary *cacheInfo = responseInfo;
        if ([key isEqualToString:ZQCacheNoParamsKey])
        {
            cacheInfo = @{key:cacheInfo};
        }
        else
        {
            NSDictionary *inCacheInfo = (NSDictionary *)[self.diskCache objectForKey:name];
            if (!inCacheInfo)
            {
                inCacheInfo = @{};
            }
            NSMutableDictionary *allCacheInfo = [NSMutableDictionary dictionaryWithDictionary:inCacheInfo];
            [allCacheInfo setObject:responseInfo forKey:key];
            cacheInfo = allCacheInfo;
        }
        [self.diskCache setObject:cacheInfo forKey:name];
    }
    else
    {
        NSDictionary *cacheInfo = (NSDictionary *)[self.diskCache objectForKey:name];
        if (cacheInfo && cacheInfo.allKeys.count > 0)
        {
            if ([key isEqualToString:ZQCacheNoParamsKey])
            {
                [self.diskCache removeObjectForKey:name];
            }
            else
            {
                NSMutableDictionary *newCacheInfo = [NSMutableDictionary dictionaryWithDictionary:cacheInfo];
                [newCacheInfo removeObjectForKey:key];
                if (newCacheInfo.allKeys.count == 0)
                {
                    [self.diskCache removeObjectForKey:name];
                }
                else
                {
                    [self.diskCache setObject:newCacheInfo forKey:name];
                }
            }
        }
    }
}

- (void)unionCacheResponseInfo:(NSDictionary *)responseInfo name:(NSString *)name key:(NSString *)key
{
    if (responseInfo)
    {
        NSDictionary *cacheInfo = responseInfo;
        if ([key isEqualToString:ZQCacheNoParamsKey])
        {
            cacheInfo = @{key:cacheInfo};
        }
        else
        {
            NSDictionary *inCacheInfo = (NSDictionary *)[self.cache objectForKey:name];
            if (!inCacheInfo)
            {
                inCacheInfo = @{};
            }
            NSMutableDictionary *allCacheInfo = [NSMutableDictionary dictionaryWithDictionary:inCacheInfo];
            [allCacheInfo setObject:responseInfo forKey:key];
            cacheInfo = allCacheInfo;
        }
        [self.cache setObject:cacheInfo forKey:name];
    }
    else
    {
        NSDictionary *cacheInfo = (NSDictionary *)[self.cache objectForKey:name];
        if (cacheInfo && cacheInfo.allKeys.count > 0)
        {
            if ([key isEqualToString:ZQCacheNoParamsKey])
            {
                [self.cache removeObjectForKey:name];
            }
            else
            {
                NSMutableDictionary *newCacheInfo = [NSMutableDictionary dictionaryWithDictionary:cacheInfo];
                [newCacheInfo removeObjectForKey:key];
                if (newCacheInfo.allKeys.count == 0)
                {
                    [self.cache removeObjectForKey:name];
                }
                else
                {
                    [self.cache setObject:newCacheInfo forKey:name];
                }
            }
        }
    }
}

- (nullable NSDictionary *)cacheInfoForName:(NSString *)name Key:(NSString *)key policy:(ZQCachePolicy)cachePolicy
{
    switch (cachePolicy)
    {
        case ZQCachePolicyMemory:
        {
            return [self memoryCacheInfoForName:name key:key];
            break;
        }
        case ZQCachePolicyDisk:
        {
            return [self diskCacheInfoForName:name key:key];
            break;
        }
        case ZQCachePolicyUnion:
        {
            return [self unionCacheInfoForName:name key:key];
            break;
        }
        default:
            break;
    }
    return nil;
}

- (nullable NSDictionary *)memoryCacheInfoForName:(NSString *)name key:(NSString *)key
{
    NSDictionary *cacheInfo = [self.memoryCache objectForKey:name];
    cacheInfo = [cacheInfo objectForKey:key];
    return cacheInfo;
}

- (nullable NSDictionary *)diskCacheInfoForName:(NSString *)name key:(NSString *)key
{
    NSDictionary *cacheInfo = (NSDictionary *)[self.diskCache objectForKey:name];
    cacheInfo = [cacheInfo objectForKey:key];
    return cacheInfo;
}

- (nullable NSDictionary *)unionCacheInfoForName:(NSString *)name key:(NSString *)key
{
    NSDictionary *cacheInfo = (NSDictionary *)[self.cache objectForKey:name];
    cacheInfo = [cacheInfo objectForKey:key];
    return cacheInfo;
}

#pragma mark - property

- (YYCache *)cache
{
    if (!_cache)
    {
        _cache = [YYCache cacheWithName:self.cacheName];
    }
    return _cache;
}

- (YYMemoryCache *)memoryCache
{
    if (!_memoryCache)
    {
        _memoryCache = [[YYMemoryCache alloc] init];
        _memoryCache.name = [self.cacheName stringByAppendingString:@"memory"];
    }
    return _memoryCache;
}

- (YYDiskCache *)diskCache
{
    if (!_diskCache)
    {
        NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *path = [cacheFolder stringByAppendingPathComponent:[self.cacheName stringByAppendingString:@"disk"]];
        _diskCache = [[YYDiskCache alloc] initWithPath:path];
    }
    return _diskCache;
}

@end
