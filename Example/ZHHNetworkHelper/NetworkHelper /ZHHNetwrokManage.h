//
//  ZHHNetwrokManage.h
//  ZHHAnneKitExample
//
//  Created by 桃色三岁 on 2022/10/19.
//  Copyright © 2022 桃色三岁. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** 来自服务器定义 */
typedef NS_ENUM(NSInteger,HTTPResponseCode) {
    /// http请求失败
    HTTPResponseCodeFailure = 0,
    /// http请求成功
    HTTPResponseCodeSuccess = 1,
    /// 网络错误
    HTTPResponseCodeNetworkError = -1,
    /// 签名验证失败
    HTTPResponseCodeSignError = -2,
    /// 会话已过期
    HTTPResponseCodeSessionHasExpired = -3,
    /// 账号已在其他地方登录
    HTTPResponseCodeOtherPlaceLogin = -4,
    /// 未知错误
    HTTPResponseCodeUnknownError = -5,
    /// 错误
    HTTPResponseCodeTryError = -6,
    /// 请求超时
    HTTPResponseCodeTimeOut = -7,
    /// 数据解析错误
    HTTPResponseCodeAnalysisError = -72,
    /// 无网状况
    HTTPResponseCodeNetwork = -88,
    /// 404无法连接服务器
    HTTPResponseCodeSeverError = 404
};

/** 成功的回调 */
typedef void (^ZHHRequestSuccess)(id responseObject);
/** 失败的回调 */
typedef void (^ZHHRequestFailure)(NSError *error);

@interface ZHHNetwrokManage : NSObject
/** 网络获取 */
+ (void)api_get_network:(id _Nullable)parameters success:(ZHHRequestSuccess)success failure:(ZHHRequestFailure)failure;
/** 缓存获取 */
+ (void)api_get_cache:(id _Nullable)parameters success:(ZHHRequestSuccess)success failure:(ZHHRequestFailure)failure;
@end

NS_ASSUME_NONNULL_END
