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

@interface ZQNetworkManager : NSObject

<<<<<<< HEAD
<<<<<<< HEAD
@property (nonatomic, strong, nullable) id<ZQInterfaceActivitConfigure> activityConfigure;
@property (nonatomic, copy, readonly) NSString *managerName;

+ (instancetype)requestManagerWithInterfaceConfigure:(id<ZQInterfaceConfigure>)configure manamgerName:(NSString *)managerName;
- (instancetype)initWithInterfaceConfigure:(id<ZQInterfaceConfigure>)configure manamgerName:(NSString *)managerName;

- (void)request:(ZQNetworkRequest *)request finishedBlock:(ZQRequestFinishedBlock)finishedBlock;
- (void)fileUploadRequest:(ZQUploadFileRequest *)request finishedBlock:(ZQRequestFinishedBlock)finishedBlock;

@end

NS_ASSUME_NONNULL_END
=======
// In this header, you should import all the public headers of your framework using statements like #import <ZQNetworkManager/PublicHeader.h>
>>>>>>> parent of d4e09fe... 开发完成
=======
// In this header, you should import all the public headers of your framework using statements like #import <ZQNetworkManager/PublicHeader.h>
>>>>>>> parent of d4e09fe... 开发完成
