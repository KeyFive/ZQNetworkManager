//
//  ZQNetworkCenter.m
//  ZQNetworkManager
//
//  Created by zhiqiangcao on 17/1/19.
//  Copyright © 2017年 ZQ. All rights reserved.
//

#import "ZQNetworkCenter.h"
#import "ZQNetworkCacheCenter.h"
#import <AFNetworking/AFNetworking.h>
#import <YYCategories/YYCategories.h>
#import <YYModel/YYModel.h>

NSString * const ZQNetworkCacheName = @"zq_network_cache_name";

static dispatch_semaphore_t serverSignal;

@interface ZQNetworkServer : NSObject

+ (instancetype)shareInstance;

@end

@interface ZQNetworkCenter()

@property (nonatomic, copy, readwrite) NSString *centerName;
@property (nonatomic, strong) id<ZQInterfaceConfigure> configure;
@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, weak) ZQNetworkServer *server;
@property (nonatomic, strong) ZQNetworkCacheCenter *cacheCenter;

- (BOOL)isWifiOnlyForRequestName:(NSString *)name;
- (void)dealWithErrorRequest:(ZQRequestModel *)request responseObject:(NSError *)error finishedBlock:(ZQRequestFinishedBlock)block;

@end

@interface ZQNetworkServer()

@property (nonatomic, strong) NSMapTable *networkCenters;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) AFNetworkReachabilityManager *networkReachabilityManager;
@property (nonatomic, strong) NSMutableDictionary *runningOperationes;//正在执行的请求
@property (nonatomic, strong) NSMutableDictionary *waitingOperationes;//正在等待执行的请求

@end

static ZQNetworkServer *networkServcer = nil;

@implementation ZQNetworkServer


#pragma mark - initial method

+ (instancetype)shareInstance
{
    if (!networkServcer)
    {
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            serverSignal = dispatch_semaphore_create(1);
            networkServcer = [[self alloc] init];
        });
    }
    return networkServcer;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        @weakify(self);
        [self.networkReachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            @strongify(self);
            dispatch_semaphore_wait(serverSignal, DISPATCH_TIME_FOREVER);
            [self cleanUnvalidOperation];
            switch (status)
            {
                case AFNetworkReachabilityStatusNotReachable:
                {
                    [self dealOperationWithNoNetStatus];
                    break;
                }
                case AFNetworkReachabilityStatusReachableViaWWAN:
                {
                    [self dealOperationWithWANStatus];
                    break;
                }
                case AFNetworkReachabilityStatusReachableViaWiFi:
                {
                    [self dealOperationWithWiFiStatus];
                    break;
                }
                default:
                    break;
            }
            dispatch_semaphore_signal(serverSignal);
        }];
        [self.networkReachabilityManager startMonitoring];
        NSTimeInterval cleanUnvalidOperationTimeInterval = 60 * 10;
        [NSTimer scheduledTimerWithTimeInterval:cleanUnvalidOperationTimeInterval target:self selector:@selector(cleanUnvalidOperationCirculation) userInfo:nil repeats:YES];
    }
    return self;
}

#pragma mark - private method

- (void)cleanUnvalidOperationCirculation
{
    dispatch_semaphore_wait(serverSignal, DISPATCH_TIME_FOREVER);
    [self cleanUnvalidOperation];
    dispatch_semaphore_signal(serverSignal);
}

- (void)cleanUnvalidOperation
{
    NSArray *unvalidWaitingKeys = [self unvalidKeysForOperations:self.waitingOperationes];
    for (NSString *key in unvalidWaitingKeys)
    {
        [self.waitingOperationes removeObjectForKey:key];
    }
    NSArray *unvalidRunningKeys = [self unvalidKeysForOperations:self.runningOperationes];
    for (NSString *key in unvalidRunningKeys)
    {
        NSMutableDictionary *operations = self.runningOperationes[key];
        for (NSString *operationKey in operations.allKeys)
        {
            NSOperation *operation = operations[operationKey];
            [operation cancel];
        }
        [self.runningOperationes removeObjectForKey:key];
    }
}

- (NSArray *)unvalidKeysForOperations:(NSMutableDictionary *)operations
{
    NSMutableArray *unvalidKeys = [NSMutableArray array];
    for (NSString *key in operations.allKeys)
    {
        ZQNetworkCenter *center = [self.networkCenters objectForKey:key];
        if (!center)
        {
            [unvalidKeys addObject:key];
        }
    }
    return unvalidKeys;
}

- (void)dealOperationWithNoNetStatus
{
    for (NSString *key in self.runningOperationes.allKeys)
    {
        NSMutableDictionary *operations = self.runningOperationes[key];
        for (NSString *operationKey in operations.allKeys)
        {
            NSOperation *operation = operations[operationKey];
            [operation cancel];
            [self addWaitingOperation:operation name:key requestName:operationKey];
        }
    }
    [self.runningOperationes removeAllObjects];
}

- (void)dealOperationWithWANStatus
{
    for (NSString *key in self.waitingOperationes.allKeys)
    {
        ZQNetworkCenter *center = [self.networkCenters objectForKey:key];
        if (center)
        {
            NSMutableArray *runningOperationsKey = [NSMutableArray array];
            NSMutableDictionary *operations = self.waitingOperationes[key];
            for (NSString *operationKey in operations.allKeys)
            {
                if (![center isWifiOnlyForRequestName:operationKey])
                {
                    NSOperation *operation = operations[operationKey];
                    [self addRunningOperation:operation name:key requestName:operationKey];
                    [runningOperationsKey addObject:operationKey];
                }
            }
            [operations removeObjectsForKeys:runningOperationsKey];
        }
    }
}

- (void)dealOperationWithWiFiStatus
{
    for (NSString *key in self.waitingOperationes.allKeys)
    {
        NSMutableArray *runningOperationsKey = [NSMutableArray array];
        NSMutableDictionary *operations = self.waitingOperationes[key];
        for (NSString *operationKey in operations.allKeys)
        {
            NSOperation *operation = operations[operationKey];
            [self addRunningOperation:operation name:key requestName:operationKey];
            [runningOperationsKey addObject:operationKey];
        }
        [operations removeObjectsForKeys:runningOperationsKey];
    }
}

- (void)addWaitingOperation:(NSOperation *)operation name:(NSString *)name requestName:(NSString *)requestName
{
    NSMutableDictionary *operations = [self.waitingOperationes objectForKey:name];
    if (!operation)
    {
        operations = [NSMutableDictionary dictionary];
    }
    [operations setObject:operation forKey:requestName];
    [self.waitingOperationes setObject:operations forKey:name];
}

- (void)addRunningOperation:(NSOperation *)operation name:(NSString *)name requestName:(NSString *)requestName
{
    NSMutableDictionary *operations = [self.runningOperationes objectForKey:name];
    if (!operation)
    {
        operations = [NSMutableDictionary dictionary];
    }
    if (![operations objectForKey:requestName])
    {
        [operations setObject:operation forKey:requestName];
        [self.runningOperationes setObject:operations forKey:name];
        [self.operationQueue addOperation:operation];
    }
}

#pragma mark - public method

- (void)completionOperationWithName:(NSString *)name requestName:(NSString *)requestName
{
    dispatch_semaphore_wait(serverSignal, DISPATCH_TIME_FOREVER);
    NSMutableDictionary *operations = [self.runningOperationes objectForKey:name];
    [operations removeObjectForKey:requestName];
    dispatch_semaphore_signal(serverSignal);
}

- (void)addNetworkCenter:(ZQNetworkCenter *)networkCenter
{
    dispatch_semaphore_wait(serverSignal, DISPATCH_TIME_FOREVER);
    ZQNetworkCenter *loadNetworkCenter = [self.networkCenters objectForKey:networkCenter.centerName];
    if(!loadNetworkCenter)
    {
        [self.networkCenters setObject:networkCenter forKey:networkCenter.centerName];
    }
    else
    {
        if (![loadNetworkCenter isEqual:networkCenter])
        {
            NSAssert(FALSE, @"不能存在两个名字相同的RequestManager对象");
        }
    }
    dispatch_semaphore_signal(serverSignal);
}

- (void)addOperation:(NSOperation *)operation name:(NSString *)name request:(ZQRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block;
{
    dispatch_semaphore_wait(serverSignal, DISPATCH_TIME_FOREVER);
    ZQNetworkCenter *center = [self.networkCenters objectForKey:name];
    switch (self.networkReachabilityManager.networkReachabilityStatus)
    {
        case AFNetworkReachabilityStatusNotReachable:
        {
            if (request.dealPolicy == ZQDealPolicyAllowDelay)
            {
                [self addWaitingOperation:operation name:name requestName:request.name];
            }
            else
            {
                [center dealWithErrorRequest:request responseObject:[NSError errorWithDomain:@"网络连接不可用" code:0 userInfo:nil] finishedBlock:block];
            }
            break;
        }
        case AFNetworkReachabilityStatusReachableViaWWAN:
        {
            if ([center isWifiOnlyForRequestName:request.name])
            {
                if (request.dealPolicy == ZQDealPolicyAllowDelay)
                {
                    [self addWaitingOperation:operation name:name requestName:request.name];
                }
                else
                {
                    [center dealWithErrorRequest:request responseObject:[NSError errorWithDomain:@"网络连接不可用" code:0 userInfo:nil] finishedBlock:block];
                }
            }
            else
            {
                [self addRunningOperation:operation name:name requestName:request.name];
            }
            break;
        }
        case AFNetworkReachabilityStatusReachableViaWiFi:
        {
            [self addRunningOperation:operation name:name requestName:request.name];
            break;
        }
        default:
            break;
    }
    dispatch_semaphore_signal(serverSignal);
}

#pragma mark - property

- (AFNetworkReachabilityManager *)networkReachabilityManager
{
    if (!_networkReachabilityManager)
    {
        _networkReachabilityManager = [AFNetworkReachabilityManager sharedManager];
    }
    return _networkReachabilityManager;
}

- (NSMapTable *)networkCenters
{
    if (!_networkCenters)
    {
        _networkCenters = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:5];
    }
    return _networkCenters;
}

- (NSOperationQueue *)operationQueue
{
    if (!_operationQueue)
    {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 5;
    }
    return _operationQueue;
}

- (NSMutableDictionary *)runningOperationes
{
    if (!_runningOperationes)
    {
        _runningOperationes = [NSMutableDictionary dictionary];
    }
    return _runningOperationes;
}

- (NSMutableDictionary *)waitingOperationes
{
    if (!_waitingOperationes)
    {
        _waitingOperationes = [NSMutableDictionary dictionary];
    }
    return _waitingOperationes;
}

@end

@implementation ZQNetworkCenter

+ (instancetype)centerWithinterfaceConfigure:(id<ZQInterfaceConfigure>)configure centerName:(NSString *)centerName
{
    return [[self alloc] initWithinterfaceConfigure:configure centerName:centerName];
}

- (instancetype)initWithinterfaceConfigure:(id<ZQInterfaceConfigure>)configure centerName:(NSString *)centerName
{
    NSAssert(configure, @"接口配置类不能为空");
    self = [super init];
    if (self)
    {
        self.centerName = centerName;
        self.configure = configure;
        [self.server addNetworkCenter:self];
    }
    return self;
}

#pragma mark - private method

- (void)beginNetworkActivity:(NSString *)requestName
{
    if ([self.activityConfigure respondsToSelector:@selector(networkActivityStartForRequestName:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityConfigure networkActivityStartForRequestName:requestName];
        });

    }
}

- (void)endNetworkActivity:(NSString *)requestName
{
    if ([self.activityConfigure respondsToSelector:@selector(networkActivityEndForRequestName:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityConfigure networkActivityEndForRequestName:requestName];
        });
    }
}

- (NSDictionary *)dealCacheRequest:(ZQRequestModel *)request
{
    NSDictionary *cacheInfo = [self.cacheCenter cacheInfoForRequest:request];;
    return cacheInfo;
}

- (void)cacheRequest:(ZQRequestModel *)request cacheInfo:(NSDictionary *)cacheInfo
{
    [self.cacheCenter cacheResponseInfo:cacheInfo forRequest:request];
}

- (void)confirmHttpSessionWithRequestName:(NSString *)name
{
    if ([self.configure respondsToSelector:@selector(httpHeadFiledsForRequestName:)])
    {
        NSDictionary *httpheadFileds = [self.configure httpHeadFiledsForRequestName:name];
        for (NSString *key in httpheadFileds.allKeys)
        {
            [self.manager setValue:httpheadFileds[key] forKey:key];
        }
    }

    if ([self.configure respondsToSelector:@selector(acceptableContentTypesForRequestName:)])
    {
        NSSet *acceptableContnetTypes = [self.configure acceptableContentTypesForRequestName:name];
        self.manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [self.manager.responseSerializer setAcceptableContentTypes:acceptableContnetTypes];
    }
}

- (void)beginRequest:(ZQRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block
{
    [self confirmHttpSessionWithRequestName:request.name];
    switch (request.method)
    {
        case ZQRequestMenthodGET:
        {
            [self dealWithGETRequest:request finishedBlock:block];
            break;
        }
        case ZQRequestMenthodPOST:
        {
            [self dealWithPOSTRequest:request finishedBlock:block];
            break;
        }
        default:
            break;
    }
}

- (void)dealWithGETRequest:(ZQRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block
{

    @weakify(self);
    [self beginNetworkActivity:request.name];
    [self.manager GET:request.requestUrl parameters:request.params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        @strongify(self);
        [self endNetworkActivity:request.name];
        [self dealWithSuccessRequest:request responseObject:responseObject finishedBlock:block];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        @strongify(self);
        [self endNetworkActivity:request.name];
        [self dealWithErrorRequest:request responseObject:error finishedBlock:block];
    }];
}

- (void)dealWithPOSTRequest:(ZQRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block
{
    [self beginNetworkActivity:request.name];
    @weakify(self);
    [self.manager POST:request.requestUrl parameters:request.params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        @strongify(self);
        [self endNetworkActivity:request.name];
        [self dealWithSuccessRequest:request responseObject:responseObject finishedBlock:block];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        @strongify(self);
        [self endNetworkActivity:request.name];
        [self dealWithErrorRequest:request responseObject:error finishedBlock:block];
    }];
}

- (void)beginFileUploadRequest:(ZQFileUploadRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block
{
    [self confirmHttpSessionWithRequestName:request.name];
    if ([self.activityConfigure respondsToSelector:@selector(paramsDealForRequestName:params:)])
    {
        request.params = [self.activityConfigure paramsDealForRequestName:request.name params:request.params];
    }

    if ([self.activityConfigure respondsToSelector:@selector(fileDataWithData:)])
    {
        for (ZQRequstFileItem *fileItem in request.files)
        {
            fileItem.fileData = [self.activityConfigure fileDataWithData:fileItem.fileData];
        }
    }
    [self beginNetworkActivity:request.name];
    @weakify(self);
    [self.manager POST:request.requestUrl parameters:request.params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        for (ZQRequstFileItem *fileItem in request.files)
        {
            [formData appendPartWithFileData:fileItem.fileData name:fileItem.name fileName:fileItem.fileName mimeType:fileItem.mimeType];
        }
    } progress:request.progressBlock success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        @strongify(self);
        [self endNetworkActivity:request.name];
        [self dealWithSuccessRequest:request responseObject:responseObject finishedBlock:block];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        @strongify(self);
        [self endNetworkActivity:request.name];
        [self dealWithErrorRequest:request responseObject:error finishedBlock:block];
    }];
}

- (void)dealWithSuccessRequest:(ZQRequestModel *)request responseObject:(id)responseObject finishedBlock:(ZQRequestFinishedBlock)block
{
    NSError *responseError = nil;
    NSDictionary *responseInfo = [self.activityConfigure responseInfoFromObject:responseObject];
    [self.activityConfigure validResponseInfo:responseInfo error:&responseError];
    if (responseError)
    {
            //返回错误
        [self dealWithErrorRequest:request responseObject:responseError finishedBlock:block];
    }
    else
    {
            //正确
        NSDictionary *usefulInfo = [self.activityConfigure usefulInfoWithResponseInfo:responseInfo];
        [self cacheRequest:request cacheInfo:usefulInfo];
        [self analysisUsefulInfo:usefulInfo request:request finishedBlock:block];
    }
}

- (void)dealWithErrorRequest:(ZQRequestModel *)request responseObject:(NSError *)error finishedBlock:(ZQRequestFinishedBlock)block
{
    if (request.requestPolicy == ZQRequestPolicyNetThenCache)
    {
        NSDictionary *cacheInfo = [self dealCacheRequest:request];
        if (cacheInfo)
        {
            [self analysisUsefulInfo:cacheInfo request:request finishedBlock:block];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(nil, error);
            });
        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(nil, error);
        });
    }
}

- (void)analysisUsefulInfo:(NSDictionary *)usefulInfo request:(ZQRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block
{
    NSObject *responseObjct = [NSClassFromString(request.responseClassName) yy_modelWithDictionary:usefulInfo];
    dispatch_async(dispatch_get_main_queue(), ^{
         block(responseObjct, nil);
    });
}

- (BOOL)predealRequest:(ZQRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block
{
    BOOL dealFinished = NO;
    if ([self.activityConfigure respondsToSelector:@selector(paramsDealForRequestName:params:)])
    {
        request.params = [self.activityConfigure paramsDealForRequestName:request.name params:request.params];
    }

    if (request.requestPolicy == ZQRequestPolicyCacheThenNet || request.requestPolicy == ZQRequestPolicyOnlyCache)
    {
        NSDictionary *cacheInfo= [self dealCacheRequest:request];
        if (cacheInfo)
        {
            [self analysisUsefulInfo:cacheInfo request:request finishedBlock:block];
            dealFinished = YES;
        }
        else
        {
            if (request.requestPolicy == ZQRequestPolicyOnlyCache)
            {
                NSError *cacheError = [NSError errorWithDomain:@"未找到缓存数据" code:0 userInfo:nil];
                [self dealWithErrorRequest:request responseObject:cacheError finishedBlock:block];
                dealFinished = YES;
            }
        }
    }
    return dealFinished;
}

#pragma mark - public method
- (void)handleRequest:(ZQRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block
{

    if (![self predealRequest:request finishedBlock:block])
    {
        @weakify(self);
        NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
            @strongify(self);
            [self beginRequest:request finishedBlock:block];
        }];
        blockOperation.completionBlock = ^{
            @strongify(self);
            [self.server completionOperationWithName:self.centerName requestName:request.name];
        };
        [self.server addOperation:blockOperation name:self.centerName request:request finishedBlock:block];
    }
}

- (void)handleFileUploadRequest:(ZQFileUploadRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block
{
    @weakify(self);
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        @strongify(self);
        [self beginFileUploadRequest:request finishedBlock:block];
    }];
    blockOperation.completionBlock = ^{
        @strongify(self);
        [self.server completionOperationWithName:self.centerName requestName:request.name];
    };
    [self.server addOperation:blockOperation name:self.centerName request:request finishedBlock:block];
}

- (BOOL)isWifiOnlyForRequestName:(NSString *)name
{
    BOOL isWifiOnly = NO;
    if ([self.configure respondsToSelector:@selector(isWifiOnlyForRequestName:)])
    {
        isWifiOnly = [self.configure isWifiOnlyForRequestName:name];
    }
    return isWifiOnly;
}

#pragma mark - property

- (ZQNetworkCacheCenter *)cacheCenter
{
    if (!_cacheCenter)
    {
        _cacheCenter = [ZQNetworkCacheCenter cacheCenterWithName:self.centerName];
    }
    return _cacheCenter;
}

- (AFHTTPSessionManager *)manager
{
    if (!_manager)
    {
        _manager = [AFHTTPSessionManager manager];
    }
    return _manager;
}

- (ZQNetworkServer *)server
{
    if (!_server)
    {
        _server = [ZQNetworkServer shareInstance];
    }
    return _server;
}

@end
