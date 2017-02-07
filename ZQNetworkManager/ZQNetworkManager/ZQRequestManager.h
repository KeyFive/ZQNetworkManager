//
//  ZQRequestManager.h
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/1/16.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZQNetworkRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZQRequestManager : NSObject

@property (nonatomic, strong, nullable) id<ZQInterfaceActivitConfigure> activityConfigure;
@property (nonatomic, copy, readonly) NSString *managerName;

+ (instancetype)requestManagerWithInterfaceConfigure:(id<ZQInterfaceConfigure>)configure manamgerName:(NSString *)managerName;
- (instancetype)initWithInterfaceConfigure:(id<ZQInterfaceConfigure>)configure manamgerName:(NSString *)managerName;

- (void)request:(ZQNetworkRequest *)request finishedBlock:(ZQRequestFinishedBlock)finishedBlock;
- (void)fileUploadRequest:(ZQUploadFileRequest *)request finishedBlock:(ZQRequestFinishedBlock)finishedBlock;

@end

NS_ASSUME_NONNULL_END
