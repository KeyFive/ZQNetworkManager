//
//  ZQRequestModel.h
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/1/16.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZQNetworkRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZQRequestModel : NSObject

@property (nonatomic, copy) NSString *name;//请求的接口名称
@property (nonatomic, copy) NSString *requestUrl;//请求的url
@property (nonatomic, copy, nullable) NSDictionary *params;//请求参数
@property (nonatomic, copy) NSString *responseClassName;//请求成功返回的类名称
@property (nonatomic, assign) ZQRequestMenthod method;//上传http method默认：ZQRequestMenthodGET
@property (nonatomic, assign) ZQRequestPolicy requestPolicy;//请求策略
@property (nonatomic, assign) ZQCachePolicy cachePolicy;//缓存策略
@property (nonatomic, assign) NSTimeInterval cacheValidityTimeInterval;//缓存有效期
@property (nonatomic, assign) ZQDealPolicy dealPolicy;//处理策略

@end

    //上传文件（无缓存）
@interface ZQFileUploadRequestModel : ZQRequestModel

@property (nonatomic, copy, nullable) NSArray *files;//上传文件列表
@property (nonatomic, copy, nullable) void (^progressBlock)(NSProgress * _Nonnull progress);//上传文件进度

@end

NS_ASSUME_NONNULL_END
