//
//  ZQRequestModel.m
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/1/16.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import "ZQRequestModel.h"

@implementation ZQRequestModel

#pragma mark - property

- (ZQRequestMenthod)method
{
    if (!_method)
    {
        _method = ZQRequestMenthodGET;
    }
    return _method;
}

- (ZQRequestPolicy)requestPolicy
{
    if (!_requestPolicy)
    {
        _requestPolicy = ZQRequestPolicyDefault;
    }
    return _requestPolicy;
}

- (ZQCachePolicy)cachePolicy
{
    if (!_cachePolicy)
    {
        _cachePolicy = ZQCachePolicyDefault;
    }
    return _cachePolicy;
}

- (NSTimeInterval)cacheValidityTimeInterval
{
    if (!_cacheValidityTimeInterval)
    {
        _cacheValidityTimeInterval = MAXFLOAT;
    }
    return _cacheValidityTimeInterval;
}

- (ZQDealPolicy)dealPolicy
{
    if (!_dealPolicy)
    {
        _dealPolicy = ZQDealPolicyImmediately;
    }
    return _dealPolicy;
}

- (NSDictionary *)params
{
    if (!_params)
    {
        return @{};
    }
    return _params;
}

- (NSString *)requestUrl
{
    if (!_requestUrl)
    {
        return @"";
    }
    return _requestUrl;
}

@end

@implementation ZQFileUploadRequestModel

- (ZQRequestPolicy)requestPolicy
{
    return ZQRequestPolicyOnlyNet;
}

- (ZQCachePolicy)cachePolicy
{
    return ZQCachePolicyNone;
}

- (ZQRequestMenthod)method
{
    return ZQRequestMenthodPOST;
}

@end
