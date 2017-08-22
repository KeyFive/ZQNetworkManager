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
#import "ZQNetworkOperation.h"

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
@property (nonatomic, strong) AFNetworkReachabilityManager *networkReachabilityManager;

- (BOOL)isWiFiOnlyForRequestName:(NSString *)name;
- (void)dealWithErrorRequest:(ZQRequestModel *)request responseObject:(NSError *)error finishedBlock:(ZQRequestFinishedBlock)block;

@end

@interface ZQNetworkServer()

@property (nonatomic, strong) NSMapTable *networkCenters;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
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
        NSTimeInterval cleanUnvalidOperationTimeInterval = 60 * 10;
        [NSTimer scheduledTimerWithTimeInterval:cleanUnvalidOperationTimeInterval target:self selector:@selector(cleanUnvalidOperationCirculation) userInfo:nil repeats:YES];
    }
    return self;
}

#pragma mark - private method

- (void)dealWithNetworkStatus:(AFNetworkReachabilityStatus)status changeCenterName:(NSString *)centerName
{
    dispatch_semaphore_wait(serverSignal, DISPATCH_TIME_FOREVER);
    switch (status)
    {
        case AFNetworkReachabilityStatusNotReachable:
        {
            [self dealOperationWithNoNetStatusWithCenterName:centerName];
            break;
        }
        case AFNetworkReachabilityStatusReachableViaWWAN:
        {
            [self dealOperationWithWANStatusWithCenterName:centerName];
            break;
        }
        case AFNetworkReachabilityStatusReachableViaWiFi:
        {
            [self dealOperationWithWiFiStatusWithCenterName:centerName];
            break;
        }
        default:
            break;
    }
    dispatch_semaphore_signal(serverSignal);
}

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
            ZQNetworkOperation *operation = operations[operationKey];
            [operation cancel];
            operation.responseBlock(nil, [NSError errorWithDomain:@"" code:ZQRequestErrorCodeCanceld userInfo:@{@"url":operation.request.requestUrl,@"params":operation.request.params}]);
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

- (void)dealOperationWithNoNetStatusWithCenterName:(NSString *)centerName
{
    ZQNetworkCenter *center = [self.networkCenters objectForKey:centerName];
    if (center)
    {
        for (NSString *key in self.runningOperationes.allKeys)
        {
            if ([centerName isEqualToString:key])
            {
                NSMutableDictionary *operations = self.runningOperationes[key];
                for (NSString *operationKey in operations.allKeys)
                {
                    ZQNetworkOperation *operation = operations[operationKey];
                    [operation cancel];
                    if (operation.request.dealPolicy == ZQDealPolicyAllowDelay)
                    {
                        ZQNetworkOperation *waitOperation = [[ZQNetworkOperation alloc] init];
                        waitOperation.requestName = operation.requestName;
                        waitOperation.block = operation.block;
                        waitOperation.responseBlock = operation.responseBlock;
                        waitOperation.completionBlock = operation.completionBlock;
                        [self addWaitingOperation:waitOperation name:key requestName:operationKey];
                    }
                    else
                    {
                        operation.responseBlock(nil, [NSError errorWithDomain:@"" code:ZQRequestErrorCodeNoSuitableNetwork userInfo:@{@"url":operation.request.requestUrl,@"params":operation.request.params}]);
                    }
                }
                break;
            }
        }
    }
    [self.runningOperationes removeObjectForKey:centerName];
}

- (void)dealOperationWithWANStatusWithCenterName:(NSString *)centerName
{
    ZQNetworkCenter *center = [self.networkCenters objectForKey:centerName];
    if (center)
    {
        for (NSString *key in self.waitingOperationes.allKeys)
        {

            if ([centerName isEqualToString:key])
            {
                NSMutableArray *runningOperationsKey = [NSMutableArray array];
                NSMutableDictionary *operations = self.waitingOperationes[key];
                for (NSString *operationKey in operations.allKeys)
                {
                    if (![center isWiFiOnlyForRequestName:operationKey])
                    {
                        NSOperation *operation = operations[operationKey];
                        [self addRunningOperation:operation name:key requestName:operationKey];
                        [runningOperationsKey addObject:operationKey];
                    }
                }
                [operations removeObjectsForKeys:runningOperationsKey];
                break;
            }
        }

        for (NSString *key in self.runningOperationes.allKeys)
        {
            if ([centerName isEqualToString:key])
            {
                NSMutableArray *waitingOperationsKey = [NSMutableArray array];
                NSMutableDictionary *operations = self.runningOperationes[key];
                for (NSString *operationKey in operations.allKeys)
                {
                    ZQNetworkOperation *operation = operations[operationKey];
                    if ([center isWiFiOnlyForRequestName:operationKey])
                    {
                        [operation cancel];
                        if (operation.request.dealPolicy == ZQDealPolicyAllowDelay)
                        {
                            ZQNetworkOperation *waitOperation = [[ZQNetworkOperation alloc] init];
                            waitOperation.requestName = operation.requestName;
                            waitOperation.block = operation.block;
                            waitOperation.responseBlock = operation.responseBlock;
                            waitOperation.completionBlock = operation.completionBlock;
                            [self addWaitingOperation:waitOperation name:key requestName:operationKey];
                            [waitingOperationsKey addObject:operationKey];
                        }
                        else
                        {
                            operation.responseBlock(nil, [NSError errorWithDomain:@"" code:ZQRequestErrorCodeCanceld userInfo:@{@"url":operation.request.requestUrl,@"params":operation.request.params}]);
                        }
                    }
                }
                [operations removeObjectsForKeys:waitingOperationsKey];
                break;
            }
        }
    }
    else
    {
        [self.waitingOperationes removeObjectForKey:centerName];
        [self.runningOperationes removeObjectForKey:centerName];
    }
}

- (void)dealOperationWithWiFiStatusWithCenterName:(NSString *)centerName
{
    ZQNetworkCenter *center = [self.networkCenters objectForKey:centerName];
    if (center)
    {
        for (NSString *key in self.waitingOperationes.allKeys)
        {

            if ([key isEqualToString:centerName])
            {
                NSMutableDictionary *operations = self.waitingOperationes[key];
                for (NSString *operationKey in operations.allKeys)
                {
                    NSOperation *operation = operations[operationKey];
                    [self addRunningOperation:operation name:key requestName:operationKey];
                }
            }
        }
    }
    [self.waitingOperationes removeObjectForKey:centerName];
}

- (void)addWaitingOperation:(NSOperation *)operation name:(NSString *)name requestName:(NSString *)requestName
{
    NSMutableDictionary *operations = [self.waitingOperationes objectForKey:name];
    if (!operations)
    {
        operations = [NSMutableDictionary dictionary];
    }
    [operations setObject:operation forKey:requestName];
    [self.waitingOperationes setObject:operations forKey:name];
}

- (void)addRunningOperation:(NSOperation *)operation name:(NSString *)name requestName:(NSString *)requestName
{
    NSMutableDictionary *operations = [self.runningOperationes objectForKey:name];
    if (!operations)
    {
        operations = [NSMutableDictionary dictionary];
    }
    NSOperation *preoperation = [operations objectForKey:requestName];
    if (preoperation)
    {
        [preoperation cancel];
        [operations setObject:operation forKey:requestName];
        [self.runningOperationes setObject:operations forKey:name];
        [self.operationQueue addOperation:operation];
    }
    else
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

- (void)addOperation:(NSOperation *)operation name:(NSString *)name request:(ZQRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block networkSatus:(AFNetworkReachabilityStatus)status
{
    dispatch_semaphore_wait(serverSignal, DISPATCH_TIME_FOREVER);
    ZQNetworkCenter *center = [self.networkCenters objectForKey:name];
    switch (status)
    {
        case AFNetworkReachabilityStatusNotReachable:
        {
            if (request.dealPolicy == ZQDealPolicyAllowDelay)
            {
                [self addWaitingOperation:operation name:name requestName:request.name];
            }
            else
            {
                [center dealWithErrorRequest:request responseObject:[NSError errorWithDomain:@"" code:ZQRequestErrorCodeNoSuitableNetwork userInfo:@{@"url":request.requestUrl,@"params":request.params}] finishedBlock:block];
            }
            break;
        }
        case AFNetworkReachabilityStatusReachableViaWWAN:
        {
            if ([center isWiFiOnlyForRequestName:request.name])
            {
                if (request.dealPolicy == ZQDealPolicyAllowDelay)
                {
                    [self addWaitingOperation:operation name:name requestName:request.name];
                }
                else
                {
                    [center dealWithErrorRequest:request responseObject:[NSError errorWithDomain:@"" code:ZQRequestErrorCodeNoSuitableNetwork userInfo:@{@"url":request.requestUrl,@"params":request.params}] finishedBlock:block];
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
        case AFNetworkReachabilityStatusUnknown:
        {
                //网络状态还不清楚时，默认发起网络请求
            [self addRunningOperation:operation name:name requestName:request.name];
            break;
        }
        default:
            break;
    }
    dispatch_semaphore_signal(serverSignal);
}

#pragma mark - property

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

        if ([self.configure respondsToSelector:@selector(acceptableContentTypesForRequest)])
        {
            NSSet *acceptableContnetTypes = [self.configure acceptableContentTypesForRequest];
            self.manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            [self.manager.responseSerializer setAcceptableContentTypes:acceptableContnetTypes];
        }

        if ([self.configure respondsToSelector:@selector(timeoutInterval)])
        {
            self.manager.requestSerializer.timeoutInterval = [self.configure timeoutInterval];
        }

        if ([self.configure respondsToSelector:@selector(domainForLink)])
        {
            self.networkReachabilityManager = [AFNetworkReachabilityManager managerForDomain:[self.configure domainForLink]];
        }
        else
        {
            self.networkReachabilityManager = [AFNetworkReachabilityManager manager];
        }
        @weakify(self);
        [self.networkReachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            @strongify(self);
            [self.server dealWithNetworkStatus:status changeCenterName:self.centerName];

        }];
        [self.networkReachabilityManager startMonitoring];
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

- (void)confirmHttpSessionWithRequestName:(NSString *)requestName
{
    if ([self.configure respondsToSelector:@selector(httpHeadFiledsForRequestName:)])
    {
        NSDictionary *httpheadFileds = [self.configure httpHeadFiledsForRequestName:requestName];
        for (NSString *key in httpheadFileds.allKeys)
        {
            [self.manager.requestSerializer setValue:httpheadFileds[key] forHTTPHeaderField:key];
        }
    }
};

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

- (void)beginRequest:(ZQRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block operation:(ZQNetworkOperation *)operation
{
    if (operation.isCancelled)
    {
        [operation finisheOperation];
        return;
    }
    [self confirmHttpSessionWithRequestName:request.name];
    switch (request.method)
    {
        case ZQRequestMenthodGET:
        {
            [self dealWithGETRequest:request finishedBlock:block operation:operation];
            break;
        }
        case ZQRequestMenthodPOST:
        {
            [self dealWithPOSTRequest:request finishedBlock:block operation:operation];
            break;
        }
        default:
            break;
    }
}

- (void)checkOperationState:(ZQNetworkOperation *)operation block:(void(^)())block request:(ZQRequestModel *)request;
{
    if (!operation.isCancelled)
    {
        block();
    }
    [operation finisheOperation];
}

- (void)dealWithGETRequest:(ZQRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block operation:(ZQNetworkOperation *)operation
{

    @weakify(self);
    [self beginNetworkActivity:request.name];
    [self.manager GET:request.requestUrl parameters:request.params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        @strongify(self);
        [self endNetworkActivity:request.name];
        @weakify(self);
        [self checkOperationState:operation block:^{
            @strongify(self);
            [self dealWithSuccessRequest:request responseObject:responseObject finishedBlock:block];
        } request:request];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        @strongify(self);
        [self endNetworkActivity:request.name];
        @weakify(self);
        [self checkOperationState:operation block:^{
            @strongify(self);
            [self dealWithErrorRequest:request responseObject:error finishedBlock:block];
        } request:request];
    }];
}

- (void)dealWithPOSTRequest:(ZQRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block operation:(ZQNetworkOperation *)operation
{
    [self beginNetworkActivity:request.name];
    @weakify(self);
    [self.manager POST:request.requestUrl parameters:request.params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        @strongify(self);
        [self endNetworkActivity:request.name];
        @weakify(self);
        [self checkOperationState:operation block:^{
            @strongify(self);
            [self dealWithSuccessRequest:request responseObject:responseObject finishedBlock:block];
        } request:request];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        @strongify(self);
        [self endNetworkActivity:request.name];
        @weakify(self);
        [self checkOperationState:operation block:^{
            @strongify(self);
            [self dealWithErrorRequest:request responseObject:error finishedBlock:block];
        } request:request];
    }];
}

- (void)beginFileUploadRequest:(ZQFileUploadRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block operation:(ZQNetworkOperation *)operation
{
    if (operation.isCancelled)
    {
        [operation finisheOperation];
        return;
    }

    [self confirmHttpSessionWithRequestName:request.name];

    if ([self.activityConfigure respondsToSelector:@selector(paramsDealForRequestName:params:)])
    {
        request.params = [self.activityConfigure paramsDealForRequestName:request.name params:request.params];
    }

    if ([self.activityConfigure respondsToSelector:@selector(fileDataWithData:requestName:)])
    {
        for (ZQRequstFileItem *fileItem in request.files)
        {
            fileItem.fileData = [self.activityConfigure fileDataWithData:fileItem.fileData requestName:request.name];
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
        @weakify(self);
        [self checkOperationState:operation block:^{
            @strongify(self);
            [self dealWithSuccessRequest:request responseObject:responseObject finishedBlock:block];
        } request:request];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        @strongify(self);
        [self endNetworkActivity:request.name];
        @weakify(self);
        [self checkOperationState:operation block:^{
            @strongify(self);
            [self dealWithErrorRequest:request responseObject:error finishedBlock:block];
        } request:request];
    }];
}

- (void)dealWithSuccessRequest:(ZQRequestModel *)request responseObject:(id)responseObject finishedBlock:(ZQRequestFinishedBlock)block
{
    NSError *responseError = nil;
    NSDictionary *responseInfo = [self.activityConfigure responseInfoFromObject:responseObject requestName:request.name error:&responseError];
    if (responseError)
    {
            //返回错误
        [self dealWithErrorRequest:request responseObject:responseError finishedBlock:block];
    }
    else
    {
            //正确
        [self analysisUsefulInfo:responseInfo request:request finishedBlock:block];
         [self cacheRequest:request cacheInfo:responseInfo];
    }
}

- (void)dealWithErrorRequest:(ZQRequestModel *)request responseObject:(NSError *)error finishedBlock:(ZQRequestFinishedBlock)block
{

    if ([self.activityConfigure respondsToSelector:@selector(dealErrorInfoWithError: requestName:)])
    {
        error = [self.activityConfigure dealErrorInfoWithError:error requestName:request.name];
    }

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
    dispatch_async(dispatch_get_main_queue(), ^{
         block(usefulInfo, nil);
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
                NSError *cacheError = [NSError errorWithDomain:@"" code:ZQRequestErrorCodeNoSuitableCache userInfo:@{@"url":request.requestUrl,@"params":request.params}];
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
        ZQNetworkOperation *operation = [[ZQNetworkOperation alloc] init];
        operation.requestName = request.name;
        @weakify(operation);
        operation.block = ^{
            @strongify(self);
            @strongify(operation);
            [self beginRequest:request finishedBlock:block operation:operation];
        };
        operation.request = request;
        operation.responseBlock = block;
        operation.completionBlock = ^{
            @strongify(self);
            [self.server completionOperationWithName:self.centerName requestName:request.name];
        };
        [self.server addOperation:operation name:self.centerName request:request finishedBlock:block networkSatus:self.networkReachabilityManager.networkReachabilityStatus];
    }
}

- (void)handleFileUploadRequest:(ZQFileUploadRequestModel *)request finishedBlock:(ZQRequestFinishedBlock)block
{
    @weakify(self);
    ZQNetworkOperation *operation = [[ZQNetworkOperation alloc] init];
    operation.requestName = request.name;
    @weakify(operation);
    operation.block = ^{
        @strongify(self);
        @strongify(operation);
        [self beginFileUploadRequest:request finishedBlock:block operation:operation];
    };
    operation.request = request;
    operation.responseBlock = block;
    operation.completionBlock = ^{
        @strongify(self);
        [self.server completionOperationWithName:self.centerName requestName:request.name];
    };
    [self.server addOperation:operation name:self.centerName request:request finishedBlock:block networkSatus:self.networkReachabilityManager.networkReachabilityStatus];
}

- (BOOL)isWiFiOnlyForRequestName:(NSString *)name
{
    BOOL isWiFiOnly = NO;
    if ([self.configure respondsToSelector:@selector(isWiFiOnlyForRequestName:)])
    {
        isWiFiOnly = [self.configure isWiFiOnlyForRequestName:name];
    }
    return isWiFiOnly;
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
        _manager.requestSerializer.timeoutInterval = 10;
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
