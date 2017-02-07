//
//  ZQInterfaceManager.h
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/1/16.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZQRequestModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZQInterfaceManager : NSObject

- (instancetype)initWithConfigure:(id<ZQInterfaceConfigure>)configure;
+ (instancetype)interfaceManagerWithConfigure:(id<ZQInterfaceConfigure>)configure;

- (ZQRequestModel *)requestModelFromRequest:(ZQNetworkRequest *)request;
- (ZQFileUploadRequestModel *)requestModelFromFileUploadRequest:(ZQUploadFileRequest *)request;

@end

NS_ASSUME_NONNULL_END
