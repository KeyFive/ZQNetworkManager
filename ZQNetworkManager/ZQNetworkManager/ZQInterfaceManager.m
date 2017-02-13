//
//  ZQInterfaceManager.m
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/1/16.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import "ZQInterfaceManager.h"

@interface ZQInterfaceManager()

@property (nonatomic, strong) id<ZQInterfaceConfigure> configure;

@end

@implementation ZQInterfaceManager

#pragma mark - class method
+ (instancetype)interfaceManagerWithConfigure:(id<ZQInterfaceConfigure>)configure
{
    return [[self alloc] initWithConfigure:configure];
}

#pragma mark - initial method

- (instancetype)init
{
    NSAssert(FALSE, @"请使用initWithConfigure:初始化");
    return self;
}

- (instancetype)initWithConfigure:(id<ZQInterfaceConfigure>)configure
{
    NSAssert(configure, @"接口配置不能为nil");
    self = [super init];
    if (self)
    {
        self.configure = configure;
    }
    return self;
}

#pragma mark - public method

- (ZQRequestModel *)requestModelFromRequest:(ZQNetworkRequest *)request
{
    ZQRequestModel *requestModel = [[ZQRequestModel alloc] init];
    requestModel.name = request.name;
    requestModel.method = [self.configure methodForRequestName:request.name userInfo:request.userInfo];
    requestModel.requestUrl = [self.configure urlForRequestName:request.name userInfo:request.userInfo];
    requestModel.params = request.params;
        //请求策略
    if ([self.configure respondsToSelector:@selector(requestPolicyForRequestName:userInfo:)])
    {
        requestModel.requestPolicy = [self.configure requestPolicyForRequestName:request.name userInfo:request.userInfo];
    }
        //缓存策略
    if ([self.configure respondsToSelector:@selector(cachePolicyForRequestName: userInfo:)])
    {
        requestModel.cachePolicy = [self.configure cachePolicyForRequestName:request.name userInfo:request.userInfo];
    }
        //缓存时间
    if ([self.configure respondsToSelector:@selector(cacheValidityTimeIntervalForRequestName:userInfo:)])
    {
        requestModel.cacheValidityTimeInterval = [self.configure cacheValidityTimeIntervalForRequestName:request.name userInfo:request.userInfo];
    }
        //处理策略
    if ([self.configure respondsToSelector:@selector(dealPolicyForRequestName: userInfo:)])
    {
        requestModel.dealPolicy = [self.configure dealPolicyForRequestName:request.name userInfo:request.userInfo];
    }

    return requestModel;
}

- (ZQFileUploadRequestModel *)requestModelFromFileUploadRequest:(ZQUploadFileRequest *)request
{
    ZQFileUploadRequestModel *requestModel = [[ZQFileUploadRequestModel alloc] init];
    requestModel.name = request.name;
    requestModel.requestUrl = [self.configure urlForRequestName:request.name userInfo:request.userInfo];
    requestModel.params = request.params;
    requestModel.progressBlock = request.progressBlock;
    requestModel.files = request.files;
        //处理策略
    if ([self.configure respondsToSelector:@selector(dealPolicyForRequestName:userInfo:)])
    {
        requestModel.dealPolicy = [self.configure dealPolicyForRequestName:request.name userInfo:request.userInfo];
    }

    return requestModel;
}

@end
