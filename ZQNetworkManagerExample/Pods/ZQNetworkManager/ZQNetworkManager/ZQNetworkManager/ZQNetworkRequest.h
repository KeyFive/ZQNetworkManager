//
//  ZQNetworkRequest.h
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/1/16.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZQInterfaceConfigure.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZQNetworkRequest : NSObject

@property (nonatomic, readonly ,copy) NSString *name;//请求接口的名称
@property (nonatomic, copy, nullable) NSDictionary *params;//请求参数
@property (nonatomic, copy) NSString *responseClassName;

- (instancetype)initWithRequestName:(NSString *)name NS_DESIGNATED_INITIALIZER;
+ (instancetype)requestWithName:(NSString *)name;

@end

@interface ZQUploadFileRequest : ZQNetworkRequest

@property (nonatomic, copy, nullable) NSArray *files;
@property (nonatomic, copy, nullable) void (^progressBlock)(NSProgress * _Nonnull progress);//上传文件进度

@end

@interface ZQRequstFileItem : NSObject

@property (nonatomic, strong) NSData *fileData;
@property (nonatomic, copy) NSString *name;//默认file
@property (nonatomic, copy) NSString *fileName;//默认@""
@property (nonatomic, copy) NSString *mimeType;//默认image/jpeg

- (instancetype)initWithFileData:(NSData *)fileData NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

