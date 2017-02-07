//
//  ZQNetworkRequest.m
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/1/16.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import "ZQNetworkRequest.h"

@interface ZQNetworkRequest()

@property (nonatomic, readwrite, copy) NSString *name;

@end

@implementation ZQNetworkRequest

#pragma mark - class method

+ (instancetype)requestWithName:(NSString *)name
{
    return [[self alloc] initWithName:name];
}

#pragma mark - initial method

- (instancetype)init
{
    return [self initWithRequestName:@""];
}

- (instancetype)initWithRequestName:(NSString *)name
{
    NSAssert(name && name.length > 0, @"请求方法的名称不能为空");
    self = [super init];
    if (self)
    {
        self.name = name;
    }
    return self;
}

#pragma mark - property

- (NSString *)responseClassName
{
    if (!_responseClassName)
    {
        _responseClassName = @"NSDictionary";
    }
    return _responseClassName;
}

@end

@implementation ZQUploadFileRequest

@end

@implementation ZQRequstFileItem

#pragma mark - initial method

- (instancetype)init
{
    return [self initWithFileData:[NSData
                                    data]];
}

- (instancetype)initWithFileData:(NSData *)fileData
{
    NSAssert(fileData && fileData.length > 0, @"上传的文件信息不能为空");
    self = [super init];
    if (self)
    {
        self.fileData = fileData;
    }
    return self;
}

#pragma mark - property

- (NSString *)name
{
    if (!_name)
    {
        _name = @"file";
    }
    return _name;
}

- (NSString *)fileName
{
    if (!_fileName)
    {
        _fileName = @"";
    }
    return _fileName;
}

- (NSString *)mimeType
{
    if (!_mimeType)
    {
        _mimeType = @"image/jpeg";
    }
    return _mimeType;
}

@end
