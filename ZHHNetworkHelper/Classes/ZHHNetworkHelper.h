//
//  ZHHNetworkHelper.h
//  ZHHAnneKitExample
//
//  Created by 桃色三岁 on 2022/9/5.
//  Copyright © 2022 桃色三岁. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import "ZHHNetworkCache.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef __OBJC__
// 日志输出宏定义
#define ZHHApiLog(FORMAT, ...) fprintf(stderr, "%s", [[NSString stringWithFormat: FORMAT, ## __VA_ARGS__] UTF8String]);
#define ZHHApiLogEnd(FORMAT, ...) fprintf(stderr, "%s:[第%d行]\t%s\n", [[[NSString stringWithUTF8String: __FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat: FORMAT, ## __VA_ARGS__] UTF8String]);
#define NSStringFormat(format,...) [NSString stringWithFormat:format,##__VA_ARGS__]
#endif

#ifndef kIsNetwork
#define kIsNetwork     [ZHHNetworkHelper isNetwork]  // 一次性判断是否有网的宏
#endif

#ifndef kIsWWANNetwork
#define kIsWWANNetwork [ZHHNetworkHelper isWWANNetwork]  // 一次性判断是否为手机网络的宏
#endif

#ifndef kIsWiFiNetwork
#define kIsWiFiNetwork [ZHHNetworkHelper isWiFiNetwork]  // 一次性判断是否为WiFi网络的宏
#endif

/** 请求方法 */
typedef NS_ENUM(NSUInteger, ZHHRequestMethod) {
    ///GET请求方法
    ZHHRequestMethodGET = 0,
    /// POST请求方法
    ZHHRequestMethodPOST,
    /// HEAD请求方法
    ZHHRequestMethodHEAD,
    /// PUT请求方法
    ZHHRequestMethodPUT,
    /// PATCH请求方法
    ZHHRequestMethodPATCH,
    /// DELETE请求方法
    ZHHRequestMethodDELETE
};

/** 缓存方式 */
typedef NS_ENUM(NSUInteger, ZHHCachePolicy) {
    /// 仅从网络获取数据
    ZHHCachePolicyNetworkOnly = 0,
    /// 先从网络获取数据，再更新本地缓存
    ZHHCachePolicyNetworkAndSaveCache,
    /// 先从网络获取数据，再更新本地缓存，如果网络获取失败还会从缓存获取
    ZHHCachePolicyNetworkElseCache,
    /// 仅从缓存获取数据
    ZHHCachePolicyCacheOnly,
    /// 先从缓存获取数据，如果没有再获取网络数据，网络数据获取成功后更新本地缓存
    ZHHCachePolicyCacheElseNetwork,
    /// 先从缓存获取数据，同时再获取网络数据并更新本地缓存，如果本地不存在缓存就返回网络获取的数据
    ZHHCachePolicyCacheAndNetwork,
    /// 先从缓存读取数据，然后在从网络获取并且缓存，在这种情况下，Block将产生两次调用
    ZHHCachePolicyCacheThenNetwork
};

/** 网络状态 */
typedef NS_ENUM(NSUInteger, ZHHNetworkStatusType) {
    /// 未知网络
    ZHHNetworkStatusUnknown,
    /// 无网络
    ZHHNetworkStatusNotReachable,
    /// 手机网络
    ZHHNetworkStatusReachableViaWWAN,
    /// WIFI网络
    ZHHNetworkStatusReachableViaWiFi
};

/** 请求序列化类型 */
typedef NS_ENUM(NSUInteger, ZHHRequestSerializer) {
    /// 设置请求数据为JSON格式
    ZHHRequestSerializerJSON,
    /// 设置请求数据为二进制格式
    ZHHRequestSerializerHTTP,
};

/** 响应序列化类型 */
typedef NS_ENUM(NSUInteger, ZHHResponseSerializer) {
    /// 设置响应数据为JSON格式
    ZHHResponseSerializerJSON,
    /// 设置响应数据为二进制格式
    ZHHResponseSerializerHTTP,
};

/// 请求成功的Block
typedef void(^ZHHHttpSuccessBlock)(id _Nullable responseObject);

/// 请求失败的Block
typedef void(^ZHHHttpFailureBlock)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error);

/// 缓存的Block
typedef void(^ZHHHttpCacheBlock)(id responseCache);

/// 上传或者下载的进度, Progress.completedUnitCount:当前大小 - Progress.totalUnitCount:总大小
typedef void (^ZHHHttpProgressBlock)(NSProgress *progress);

/// 网络状态的Block
typedef void(^ZHHNetworkStatusBlock)(ZHHNetworkStatusType status);

@interface ZHHNetworkHelper : NSObject

/// 有网YES, 无网:NO
+ (BOOL)isNetwork;

/// 手机网络:YES, 反之:NO
+ (BOOL)isWWANNetwork;

/// WiFi网络:YES, 反之:NO
+ (BOOL)isWiFiNetwork;

/// 是否打开网络加载菊花(默认打开)
+ (void)openNetworkActivityIndicator:(BOOL)open;

/// 实时获取网络状态,通过Block回调实时获取(此方法可多次调用)
+ (void)zhh_networkStatusWithBlock:(ZHHNetworkStatusBlock)networkStatusBlock;

/// 取消所有HTTP请求
+ (void)cancelAllRequest;

/// 取消指定URL的HTTP请求
+ (void)cancelRequestWithURL:(NSString *)URL;

/// 开启日志打印 (Debug级别)
+ (void)openLog;

/// 关闭日志打印,默认关闭
+ (void)closeLog;

#pragma mark - 设置AFHTTPSessionManager相关属性
#pragma mark 注意: 因为全局只有一个AFHTTPSessionManager实例,所以以下设置方式全局生效
/// 设置请求头
+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
/// 设置接口根路径
+ (void)setBaseUrl:(nullable NSString *)baseUrl;

/// 设置接口基本参数/公共参数(如:用户ID, Token)
+ (void)setBaseParameters:(nullable NSDictionary *)params;

/// 加密接口参数/加密Body
+ (void)setEncodeParameters:(nullable NSDictionary *)params;

/// 是否需要加密传输
+ (void)setIsNeedEncry:(BOOL)isNeedEncry;

/// 设置请求超时时间(默认30s)
+ (void)setRequestTimeoutInterval:(NSTimeInterval)timeout;
/**
 *  在开发中,如果以下的设置方式不满足项目的需求,就调用此方法获取AFHTTPSessionManager实例进行自定义设置
 *  (注意: 调用此方法时在要导入AFNetworking.h头文件,否则可能会报找不到AFHTTPSessionManager的❌)
 *  @param sessionManager AFHTTPSessionManager的实例
 */
+ (void)setAFHTTPSessionManagerProperty:(void(^)(AFHTTPSessionManager *sessionManager))sessionManager;
/**
 *  设置网络请求参数的格式:默认为二进制格式
 *
 *  @param requestSerializer ZHHRequestSerializerJSON(JSON格式),ZHHRequestSerializerHTTP(二进制格式)
 */
+ (void)setRequestSerializer:(ZHHRequestSerializer)requestSerializer;

/**
 *  设置服务器响应数据格式:默认为JSON格式
 *
 *  @param responseSerializer ZHHResponseSerializerJSON(JSON格式),ZHHResponseSerializerHTTP(二进制格式)
 */
+ (void)setResponseSerializer:(ZHHResponseSerializer)responseSerializer;

/**
 *  配置自建证书的Https请求, 参考链接: http://blog.csdn.net/syg90178aw/article/details/52839103
 *
 *  @param cerPath 自建Https证书的路径
 *  @param validatesDomainName 是否需要验证域名，默认为YES. 如果证书的域名与请求的域名不一致，需设置为NO;
 *  即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险, 建议打开.validatesDomainName=NO,
 *  主要用于这种情况:客户端请求的是子域名, 而证书上的是另外一个域名。因为SSL证书上的域名是独立的,
 *  假如证书上注册的域名是www.google.com, 那么mail.google.com是无法验证通过的.
 */
+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName;

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
               failure:(nullable ZHHHttpFailureBlock)failureBlock;

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
                failure:(nullable ZHHHttpFailureBlock)failureBlock;

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
                      failure:(nullable ZHHHttpFailureBlock)failureBlock;

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
                        failure:(nullable void(^)(NSError * _Nonnull error))failure;


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
                      failure:(nullable void(^)(NSError * _Nonnull error))failure;

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
                                           failure:(nullable void(^)(NSError * _Nullable error))failure;
@end

NS_ASSUME_NONNULL_END
