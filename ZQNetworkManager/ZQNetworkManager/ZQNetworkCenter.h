//
//  ZQNetworkCenter.h
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/1/19.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZQRequestModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZQNetworkCenter : NSObject

@property (nonatomic, copy, readonly) NSString *centerName;
@property (nonatomic, strong) id<ZQInterfaceConfigure> configure;
@property (nonatomic, strong, nullable) id<ZQInterfaceActivitConfigure> activityConfigure;

+ (instancetype)centerWithinterfaceConfigure:(id<ZQInterfaceConfigure>)configure centerName:(NSString *)centerName;
- (instancetype)initWithinterfaceConfigure:(id<ZQInterfaceConfigure>)configure centerName:(NSString *)centerName;

- (void)handleRequest:(ZQRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block;
- (void)handleFileUploadRequest:(ZQFileUploadRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block;

@end

NS_ASSUME_NONNULL_END
