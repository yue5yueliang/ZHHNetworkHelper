//
//  ZHHNetworkHelper.m
//  ZHHAnneKitExample
//
//  Created by 桃色三岁 on 2022/9/5.
//  Copyright © 2022 桃色三岁. All rights reserved.
//

#import "ZHHNetworkHelper.h"

@implementation ZHHNetworkHelper
static BOOL _isOpenLog;
// 以下变量是公共配置，不支持二次修改
static NSString *_baseUrl;
/// 公共参数
static NSDictionary *_baseParameters;
/// 加密参数
static NSDictionary *_encodeParameters;
/// 是否已开启日志打印
static BOOL _isOpenLog;
/// 是否需要加密传输
static BOOL _isNeedEncry;
/// 所有的请求task数组
static NSMutableArray *_allSessionTask;
static AFHTTPSessionManager *_sessionManager;

#pragma mark - 所有的请求task数组
+ (NSMutableArray *)allSessionTask {
    if (!_allSessionTask) {
        _allSessionTask = [NSMutableArray array];
    }
    return _allSessionTask;
}

#pragma mark - 初始化AFHTTPSessionManager相关属性
/**
 *  开始监测网络状态
 */
+ (void)load {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

/**
 *  所有的HTTP请求共享一个AFHTTPSessionManager
 *  原理参考地址:http://www.jianshu.com/p/5969bbb4af9f
 */
+ (void)initialize {
    // 创建请求管理者对象
    _sessionManager = [AFHTTPSessionManager manager];
    // 设置默认数据
    // 设置请求参数的格式：二进制格式
    _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    // 设置服务器返回结果的格式：JSON格式
    _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    // 配置响应序列化(设置请求接口回来的时候支持什么类型的数据,设置接收参数类型)
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",
                                                                 @"text/html",
                                                                 @"text/json",
                                                                 @"text/plain",
                                                                 @"text/text",
                                                                 @"text/javascript",
                                                                 @"text/xml",
                                                                 @"image/*",
                                                                 @"multipart/form-data"
                                                                 @"application/octet-stream",
                                                                 @"application/zip", nil];
    // 最大请求并发任务数
    //_sessionManager.operationQueue.maxConcurrentOperationCount = 5;
    // 设置请求超时时间
    _sessionManager.requestSerializer.timeoutInterval = 30;
    // 打开状态栏菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    // 默认关闭日志
    _isOpenLog = NO;
    // 默认不加密传输
    _isNeedEncry = NO;
}

#pragma mark - 判断当前是否有网络连接
+ (BOOL)isNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

#pragma mark - 判断当前是否是手机网络
+ (BOOL)isWWANNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN;
}

#pragma mark - 判断当前是否是WIFI网络
+ (BOOL)isWiFiNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
}

#pragma mark - 是否打开网络加载菊花(默认打开)
+ (void)openNetworkActivityIndicator:(BOOL)open {
    // 当使用AF发送网络请求时,只要有网络操作,那么在状态栏(电池条)wifi符号旁边显示  菊花提示
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:open];
}

#pragma mark - 实时获取网络状态
+ (void)zhh_networkStatusWithBlock:(ZHHNetworkStatusBlock)networkStatusBlock {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 1.创建网络监听管理者
        AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
        // 2.设置网络状态改变后的处理
        [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            // 当网络状态改变了, 就会调用这个block
            switch (status) {
                case AFNetworkReachabilityStatusUnknown:
                    if (_isOpenLog) ZHHApiLog(@"当前网络未知");
                    networkStatusBlock ? networkStatusBlock(ZHHNetworkStatusUnknown) : nil;
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    if (_isOpenLog) ZHHApiLog(@"当前无网络");
                    networkStatusBlock ? networkStatusBlock(ZHHNetworkStatusNotReachable) : nil;
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                    if (_isOpenLog) ZHHApiLog(@"当前是蜂窝网络");
                    networkStatusBlock ? networkStatusBlock(ZHHNetworkStatusReachableViaWWAN) : nil;
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    if (_isOpenLog) ZHHApiLog(@"当前是wifi环境");
                    networkStatusBlock ? networkStatusBlock(ZHHNetworkStatusReachableViaWiFi) : nil;
                    break;
                default:
                    break;
            }
        }];
    });
}

#pragma mark - 取消所有HTTP请求
+ (void)cancelAllRequest {
    // 锁操作
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTask] removeAllObjects];
    }
}

#pragma mark - 取消指定URL的HTTP请求
+ (void)cancelRequestWithURL:(NSString *)url {
    if (!url) { return; }
    // 锁操作
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:url]) {
                [task cancel];
                [[self allSessionTask] removeObject:task];
                *stop = YES;
            }
        }];
    }
}

#pragma mark - 开启日志打印 (Debug级别)
+ (void)openLog {
    _isOpenLog = YES;
}

#pragma mark - 关闭日志打印,默认关闭
+ (void)closeLog{
    _isOpenLog = NO;
}

#pragma mark - 设置AFHTTPSessionManager相关属性
#pragma mark 注意: 因为全局只有一个AFHTTPSessionManager实例,所以以下设置方式全局生效
#pragma mark 设置请求头
+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [_sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
}

#pragma mark 设置接口根路径
+ (void)setBaseUrl:(nullable NSString *)baseUrl{
    _baseUrl = baseUrl;
}

#pragma mark - 设置接口基本参数/公共参数 (如:用户ID, Token)
+ (void)setBaseParameters:(NSDictionary *)parameters {
    _baseParameters = parameters;
}

#pragma mark - 加密接口参数/加密Body
+ (void)setEncodeParameters:(NSDictionary *)parameters {
    _encodeParameters = parameters;
}

#pragma mark - 是否需要加密传输
+ (void)setIsNeedEncry:(BOOL)isNeedEncry {
    _isNeedEncry = isNeedEncry;
}

#pragma mark - 设置请求超时时间(默认30s)
+ (void)setRequestTimeoutInterval:(NSTimeInterval)timeout {
    if (!_sessionManager) return;
    _sessionManager.requestSerializer.timeoutInterval = timeout;
}

/**
 *  在开发中,如果以下的设置方式不满足项目的需求,就调用此方法获取AFHTTPSessionManager实例进行自定义设置
 *  (注意: 调用此方法时在要导入AFNetworking.h头文件,否则可能会报找不到AFHTTPSessionManager的❌)
 *  @param sessionManager AFHTTPSessionManager的实例
 */
+ (void)setAFHTTPSessionManagerProperty:(void (^)(AFHTTPSessionManager *))sessionManager {
    if (!_sessionManager) return;
    sessionManager ? sessionManager(_sessionManager) : nil;
}

#pragma mark - 设置网络请求参数的格式:默认为二进制格式
+ (void)setRequestSerializer:(ZHHRequestSerializer)requestSerializer {
    if (!_sessionManager) return;
    switch (requestSerializer) {
        case ZHHRequestSerializerHTTP:
            _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
        case ZHHRequestSerializerJSON:
            _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
            break;
        default:
            break;
    }
}

#pragma mark - 设置服务器响应数据格式:默认为JSON格式
+ (void)setResponseSerializer:(ZHHResponseSerializer)responseSerializer {
    if (!_sessionManager) return;
    switch (responseSerializer) {
        case ZHHResponseSerializerHTTP:
            _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        case ZHHResponseSerializerJSON:
            _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        default:
            break;
    }
}

#pragma mark - 验证https证书
// 参考链接:http://blog.csdn.net/syg90178aw/article/details/52839103
+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName {
    // 先导入证书 证书由服务端生成，具体由服务端人员操作
    // NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"xxx" ofType:@"cer"]; // CA证书地址
    // 获取CA证书数据
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    // 使用证书验证模式：AFSSLPinningModeCertificate
    AFSecurityPolicy *securitypolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // 是否允许无效证书（也就是自建的证书），默认为NO；如果需要验证自建证书，需要设置为YES
    securitypolicy.allowInvalidCertificates = YES;
    // 是否需要验证域名，默认为YES。假如证书的域名与你请求的域名不一致，需把该项设置为NO；
    securitypolicy.validatesDomainName = validatesDomainName;
    // 根据验证模式来返回用于验证服务器的证书
    securitypolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
    _sessionManager.securityPolicy = securitypolicy;
}

#pragma mark - 请求相关使用的方法
/**
 *  GET请求方法
 *
 *  @param url 请求地址
 *  @param parameters 请求参数
 *  @param headers 请求头
 *  @param cachePolicy 缓存策略
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 */
+ (void)zhh_getWithURL:(NSString *)url
            parameters:(nullable NSDictionary *)parameters
               headers:(nullable NSDictionary *)headers
           cachePolicy:(ZHHCachePolicy)cachePolicy
               success:(nullable ZHHHttpSuccessBlock)successBlock
               failure:(nullable ZHHHttpFailureBlock)failureBlock{
    [self zhh_requestWithMethod:ZHHRequestMethodGET url:url parameters:parameters headers:headers cachePolicy:cachePolicy success:successBlock failure:failureBlock];
}

/**
 *  POST请求方法
 *
 *  @param url 请求地址
 *  @param parameters 请求参数
 *  @param headers 请求头
 *  @param cachePolicy 缓存策略
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 */
+ (void)zhh_postWithURL:(NSString *)url
             parameters:(nullable NSDictionary *)parameters
                headers:(nullable NSDictionary *)headers
            cachePolicy:(ZHHCachePolicy)cachePolicy
                success:(nullable ZHHHttpSuccessBlock)successBlock
                failure:(nullable ZHHHttpFailureBlock)failureBlock{
    [self zhh_requestWithMethod:ZHHRequestMethodPOST url:url parameters:parameters headers:headers cachePolicy:cachePolicy success:successBlock failure:failureBlock];
}

/**
 *  网络请求方法
 *
 *  @param method 请求方法
 *  @param url 请求地址
 *  @param parameters 请求参数
 *  @param headers 请求头
 *  @param cachePolicy 缓存策略
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 */
+ (void)zhh_requestWithMethod:(ZHHRequestMethod)method
                          url:(NSString *)url
                   parameters:(nullable NSDictionary *)parameters
                      headers:(nullable NSDictionary *)headers
                  cachePolicy:(ZHHCachePolicy)cachePolicy
                      success:(nullable ZHHHttpSuccessBlock)successBlock
                      failure:(nullable ZHHHttpFailureBlock)failureBlock{
    if (!(url && [url hasPrefix:@"http"]) && _baseUrl && _baseUrl.length > 0) {
        // 获取完整的url路径
        url = [NSString stringWithFormat:@"%@%@", _baseUrl, url];
    }
    if (_baseParameters.count > 0) {
        NSMutableDictionary *mutableDic = [NSMutableDictionary dictionaryWithDictionary:parameters];
        // 添加基本参数/公共参数
        [mutableDic addEntriesFromDictionary:_baseParameters];
        parameters = [mutableDic copy];
    }
    if (_isNeedEncry && _encodeParameters.count > 0) {
        parameters = _encodeParameters;
    }
    if (cachePolicy == ZHHCachePolicyNetworkOnly) {
        [self zhh_requestWithMethod:method url:url parameters:parameters headers:headers success:successBlock failure:failureBlock];
    } else if (cachePolicy == ZHHCachePolicyNetworkAndSaveCache) {
        [self zhh_requestWithMethod:method url:url parameters:parameters headers:headers success:^(id responseObject) {
            // 更新缓存
            [ZHHNetworkCache zhh_saveHttpCache:responseObject url:url parameters:parameters];
            successBlock ? successBlock(responseObject) : nil;
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            failureBlock ? failureBlock(task,error) : nil;
        }];
    } else if (cachePolicy == ZHHCachePolicyNetworkElseCache) {
        [self zhh_requestWithMethod:method url:url parameters:parameters headers:headers success:^(id responseObject) {
            // 更新缓存
            [ZHHNetworkCache zhh_saveHttpCache:responseObject url:url parameters:parameters];
            successBlock ? successBlock(responseObject) : nil;
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [self zhh_getHttpCacheWithURL:url parameters:parameters headers:headers resultBlock:^(id<NSCoding> object) {
                if (object) {
                    successBlock ? successBlock(object) : nil;
                } else {
                    failureBlock ? failureBlock(task,error) : nil;
                }
            }];
        }];
    } else if (cachePolicy == ZHHCachePolicyCacheOnly) {
        [self zhh_getHttpCacheWithURL:url parameters:parameters headers:headers resultBlock:^(id<NSCoding> object) {
            successBlock ? successBlock(object) : nil;
        }];
    } else if (cachePolicy == ZHHCachePolicyCacheElseNetwork) {
        // 先从缓存读取数据
        [self zhh_getHttpCacheWithURL:url parameters:parameters headers:headers resultBlock:^(id<NSCoding> object) {
            if (object) {
                successBlock ? successBlock(object) : nil;
            } else {
                // 如果没有缓存再从网络获取
                [self zhh_requestWithMethod:method url:url parameters:parameters headers:headers success:^(id responseObject) {
                    // 更新缓存
                    [ZHHNetworkCache zhh_saveHttpCache:responseObject url:url parameters:parameters];
                    successBlock ? successBlock(responseObject) : nil;
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    failureBlock ? failureBlock(task,error) : nil;
                }];
            }
        }];
    } else if (cachePolicy == ZHHCachePolicyCacheAndNetwork) {
        // 先从缓存读取数据
        [self zhh_getHttpCacheWithURL:url parameters:parameters headers:headers resultBlock:^(id<NSCoding> object) {
            if (object) {
                successBlock ? successBlock(object) : nil;
            }
            // 同时再从网络获取
            [self zhh_requestWithMethod:method url:url parameters:parameters headers:headers success:^(id responseObject) {
                // 更新本地缓存
                [ZHHNetworkCache zhh_saveHttpCache:responseObject url:url parameters:parameters];
                // 如果本地不存在缓存，就获取网络数据
                if (!object) {
                    successBlock ? successBlock(responseObject) : nil;
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                failureBlock ? failureBlock(task,error) : nil;
            }];
        }];
    } else if (cachePolicy == ZHHCachePolicyCacheThenNetwork) {
        // 先从缓存读取数据（这种情况successBlock调用两次）
        [self zhh_getHttpCacheWithURL:url parameters:parameters headers:headers resultBlock:^(id<NSCoding> object) {
            if (object) {
                successBlock ? successBlock(object) : nil;
            }
            // 再从网络获取
            [self zhh_requestWithMethod:method url:url parameters:parameters headers:headers success:^(id responseObject) {
                // 更新缓存
                [ZHHNetworkCache zhh_saveHttpCache:responseObject url:url parameters:parameters];
                successBlock ? successBlock(responseObject) : nil;
            } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                failureBlock ? failureBlock(task,error) : nil;
            }];
        }];
    } else {
        // 未知缓存策略 (使用BRCachePolicyNetworkOnly)
        [self zhh_requestWithMethod:method url:url parameters:parameters headers:headers success:successBlock failure:failureBlock];
    }
}

#pragma mark - 网络请求处理
+ (void)zhh_requestWithMethod:(ZHHRequestMethod)method
                          url:(NSString *)url
                   parameters:(NSDictionary *)parameters
                      headers:(NSDictionary *)headers
                      success:(ZHHHttpSuccessBlock)successBlock
                      failure:(ZHHHttpFailureBlock)failureBlock {
    [self zhh_dataTaskWithMethod:method url:url parameters:parameters headers:headers success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        
        BOOL isEmpty = (responseObject == nil || [responseObject isEqual:[NSNull null]] ||
        [responseObject isEqual:@"null"] || [responseObject isEqual:@"(null)"] ||
        ([responseObject respondsToSelector:@selector(length)] && [(NSData *)responseObject length] == 0) ||
        ([responseObject respondsToSelector:@selector(count)] && [(NSArray *)responseObject count] == 0));
    
        // 响应序列化类型是HTTP时，请求结果输出的是二进制数据
        if (!isEmpty && ![NSJSONSerialization isValidJSONObject:responseObject]) {
            NSError *error = nil;
            // 将二进制数据序列化成JSON数据
            id obj = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:&error];
            if (error) {
                if (_isOpenLog) ZHHApiLog(@"二进制数据序列化成JSON数据失败：%@", error);
            } else {
                responseObject = obj;
            }
        }
        if (_isOpenLog) ZHHApiLog(@"\nurl：%@\nheader：\n%@\nparameters：\n%@\nsuccess：\n%@\n\n", url, headers, parameters, responseObject);
        [[self allSessionTask] removeObject:task];
        successBlock ? successBlock(responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isOpenLog) ZHHApiLog(@"\nurl：%@\nheader：\n%@\nparameters：\n%@\nfailure：\n%@\n\n", url, headers, parameters, error);
        failureBlock ? failureBlock(task,error) : nil;
        [[self allSessionTask] removeObject:task];
    }];
}

#pragma mark - 异步 获取缓存的数据
+ (void)zhh_getHttpCacheWithURL:(NSString *)url parameters:(nullable NSDictionary *)parameters headers:(nullable NSDictionary *)headers resultBlock:(nullable void (^)(id<NSCoding> object))resultBlock {
    [ZHHNetworkCache zhh_getHttpCacheWithURL:url parameters:parameters block:^(id<NSCoding> object) {
        if (_isOpenLog) ZHHApiLog(@"\nurl：%@\nheader：\n%@\nparameters：\n%@\ncache：\n%@\n\n", url, headers, parameters, object);
        resultBlock(object);
    }];
}

#pragma mark - 请求任务
+ (void)zhh_dataTaskWithMethod:(ZHHRequestMethod)method
                           url:(NSString *)url
                    parameters:(nullable NSDictionary *)parameters
                       headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                       success:(nullable void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject))success
                       failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure {
    NSURLSessionTask *sessionTask = nil;
    if (method == ZHHRequestMethodGET) {
        sessionTask = [_sessionManager GET:url parameters:parameters headers:headers progress:nil success:success failure:failure];
    } else if (method == ZHHRequestMethodPOST) {
        sessionTask = [_sessionManager POST:url parameters:parameters headers:headers progress:nil success:success failure:failure];
    } else if (method == ZHHRequestMethodHEAD) {
        sessionTask = [_sessionManager HEAD:url parameters:parameters headers:headers success:nil failure:failure];
    } else if (method == ZHHRequestMethodPUT) {
        sessionTask = [_sessionManager PUT:url parameters:parameters headers:headers success:success failure:failure];
    } else if (method == ZHHRequestMethodPATCH) {
        sessionTask = [_sessionManager PATCH:url parameters:parameters headers:headers success:success failure:failure];
    } else if (method == ZHHRequestMethodDELETE) {
        sessionTask = [_sessionManager DELETE:url parameters:parameters headers:headers success:success failure:failure];
    } else {
        sessionTask = [_sessionManager GET:url parameters:parameters headers:headers progress:nil success:success failure:failure];
    }
    
    //添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
}



/**
 *  上传单/多张图片
 *
 *  @param url              请求地址
 *  @param parameters       请求参数
 *  @param nameKey          图片对应服务器上的字段
 *  @param images           图片数组
 *  @param fileNames        图片文件名数组, 可以为nil, 数组内的文件名默认为当前日期时间"yyyyMMddHHmmss"
 *  @param imageScale       图片文件压缩比 范围 (0.0f ~ 1.0f)
 *  @param imageType        图片文件的类型,例:png、jpg(默认类型)....
 *  @param progress         上传进度的回调
 *  @param success          请求成功的回调
 *  @param failure          请求失败的回调
 *
 */
+ (void)zhh_uploadImagesWithURL:(NSString *)url
                     parameters:(nullable id)parameters
                        nameKey:(nullable NSString *)nameKey
                         images:(nullable NSArray<UIImage *> *)images
                      fileNames:(nullable NSArray<NSString *> *)fileNames
                     imageScale:(CGFloat)imageScale
                      imageType:(nullable NSString *)imageType
                       progress:(nullable void(^)(NSProgress * _Nonnull progress))progress
                        success:(nullable void(^)(id _Nullable responseObject))success
                        failure:(nullable void(^)(NSError * _Nonnull error))failure{
    NSURLSessionTask *sessionTask = [_sessionManager POST:url parameters:parameters headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        // 循环遍历上传图片
        [images enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
            // 图片经过等比压缩后得到的二进制文件(imageData就是要上传的数据)
            NSData *imageData = UIImageJPEGRepresentation(image, imageScale ?: 1.0f);
            // 1.使用时间拼接上传图片名
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *currentTimeStr = [formatter stringFromDate:[NSDate date]];
            NSString *uploadFileName1 = [NSString stringWithFormat:@"%@%@.%@", currentTimeStr, @(idx), imageType?:@"jpg"];
            // 2.使用传入的图片名
            NSString *uploadFileName2 = [NSString stringWithFormat:@"%@.%@", fileNames[idx], imageType?:@"jpg"];
            // 上传图片名
            NSString *uploadFileName = fileNames ? uploadFileName2 : uploadFileName1;
            // 上传图片类型
            NSString *uploadFileType = [NSString stringWithFormat:@"image/%@", imageType ?: @"jpg"];
            
            [formData appendPartWithFileData:imageData name:nameKey fileName:uploadFileName mimeType:uploadFileType];
        }];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        progress ? progress(uploadProgress) : nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allSessionTask] removeObject:task];
        failure ? failure(error) : nil;
    }];
    // 添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
}


/**
 *  上传文件
 *
 *  @param url              请求地址
 *  @param parameters       请求参数
 *  @param nameKey          文件对应服务器上的字段
 *  @param filePath         文件本地的沙盒路径
 *  @param progress         上传进度的回调
 *  @param success          请求成功的回调
 *  @param failure          请求失败的回调
 *
*/
+ (void)zhh_uploadFileWithURL:(NSString *)url
                   parameters:(nullable id)parameters
                      nameKey:(nullable NSString *)nameKey
                     filePath:(nullable NSString *)filePath
                     progress:(nullable void(^)(NSProgress * _Nonnull progress))progress
                      success:(nullable void(^)(id _Nullable responseObject))success
                      failure:(nullable void(^)(NSError * _Nonnull error))failure{
    NSURLSessionTask *sessionTask = [_sessionManager POST:url parameters:parameters headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:nameKey error:&error];
        if (error) {
            failure ? failure(error) : nil;
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        progress ? progress(uploadProgress) : nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allSessionTask] removeObject:task];
        failure ? failure(error) : nil;
    }];
    // 添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil;
}

/**
 *  下载文件
 *
 *  @param url              请求地址
 *  @param progress         下载进度的回调
 *  @param success          下载成功的回调
 *  @param failure          下载失败的回调
 *
 */
+ (__kindof NSURLSessionTask *)zhh_downloadWithURL:(NSString *)url
                                          progress:(nullable void(^)(NSProgress *progress))progress
                                           success:(nullable void(^)(NSString * _Nullable filePath))success
                                           failure:(nullable void(^)(NSError * _Nullable error))failure{
    NSURL *URL = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    __block NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        // 下载进度
        // progress.completedUnitCount: 当前大小;
        // Progress.totalUnitCount: 总大小
        if (_isOpenLog) ZHHApiLog(@"下载进度：%.2f%%",100.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress) : nil;
        });
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        // 下载完后，实际下载在临时文件夹里；在这里需要保存到本地缓存文件夹里
        // 1.拼接缓存目录（保存到Download目录里）
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Download"];
        // 2.打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // 3.创建Download目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        // 4.拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        // 5.返回文件位置的URL路径
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        [[self allSessionTask] removeObject:downloadTask];
        if (!error) {
            // NSURL 转 NSString: filePath.path 或 filePath.absoluteString
            success ? success(filePath.path) : nil;
        } else {
            failure ? failure(error) : nil;
        }
    }];
    // 开始下载
    [downloadTask resume];
    // 添加sessionTask到数组
    downloadTask ? [[self allSessionTask] addObject:downloadTask] : nil;
    return downloadTask;
}
@end
