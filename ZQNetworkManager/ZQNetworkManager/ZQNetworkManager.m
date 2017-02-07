//
//  ZQRequestManager.m
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/1/16.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import "ZQNetworkManager.h"
#import "ZQInterfaceManager.h"
#import "ZQNetworkCenter.h"

@interface ZQNetworkManager()

@property (nonatomic, strong) id<ZQInterfaceConfigure> configure;
@property (nonatomic, strong) ZQInterfaceManager *interfaceManager;
@property (nonatomic, strong) ZQNetworkCenter *networkCenter;
@property (nonatomic, copy, readwrite) NSString *managerName;

@end

@implementation ZQNetworkManager

#pragma mark - class method

+ (instancetype)requestManagerWithInterfaceConfigure:(id<ZQInterfaceConfigure>)configure manamgerName:(NSString *)managerName;
{
    return [[self alloc] initWithInterfaceConfigure:configure manamgerName:managerName];
}

#pragma mark - initial method

- (instancetype)init
{
    NSAssert(FALSE, @"请使用initWithInterfaceConfigure：managerName：进行初始化");
    return self;
}

- (instancetype)initWithInterfaceConfigure:(id<ZQInterfaceConfigure>)configure manamgerName:(NSString *)managerName
{
    NSAssert(configure, @"接口配置信息不能为空");
    self = [super init];
    if (self)
    {
        self.configure = configure;
        self.managerName = managerName;
        self.networkCenter = [ZQNetworkCenter centerWithinterfaceConfigure:self.configure centerName:self.managerName];
        self.interfaceManager = [ZQInterfaceManager interfaceManagerWithConfigure:configure];
    }
    return self;
}

#pragma mark - public method

- (void)request:(ZQNetworkRequest *)request finishedBlock:(ZQRequestFinishedBlock)finishedBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        ZQRequestModel *requestModel = [self.interfaceManager requestModelFromRequest:request];
        [self.networkCenter handleRequest:requestModel finishedBlock:finishedBlock];
    });
}

- (void)fileUploadRequest:(ZQUploadFileRequest *)request finishedBlock:(ZQRequestFinishedBlock)finishedBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        ZQFileUploadRequestModel *requestModel = [self.interfaceManager requestModelFromFileUploadRequest:request];
        [self.networkCenter handleFileUploadRequest:requestModel finishedBlock:finishedBlock];
    });
}

#pragma mark - property

- (void)setActivityConfigure:(id<ZQInterfaceActivitConfigure>)activityConfigure
{
    _activityConfigure = activityConfigure;
    self.networkCenter.activityConfigure = _activityConfigure;
}

@end
