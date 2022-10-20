//
//  ZHHNetwrokManage.m
//  ZHHAnneKitExample
//
//  Created by 桃色三岁 on 2022/10/19.
//  Copyright © 2022 桃色三岁. All rights reserved.
//

#import "ZHHNetwrokManage.h"
#import "ZHHNetworkHelper.h"
#import "ZHHNetwrokModel.h"
#import <MJExtension/MJExtension.h>

@implementation ZHHNetwrokManage

/** 网络获取 */
+ (void)api_get_network:(id _Nullable)parameters success:(ZHHRequestSuccess)success failure:(ZHHRequestFailure)failure {
    // 将请求前缀与请求路径拼接成一个完整的URL
    NSString *url = [NSString stringWithFormat:@"/index/user_feedback/index"];
    [self requestWithURL:url parameters:parameters cachePolicy:ZHHCachePolicyNetworkOnly success:success failure:failure];
}

/** 缓存获取 */
+ (void)api_get_cache:(id _Nullable)parameters success:(ZHHRequestSuccess)success failure:(ZHHRequestFailure)failure {
    // 将请求前缀与请求路径拼接成一个完整的URL
    NSString *url = [NSString stringWithFormat:@"/index/user_feedback/index"];
    [self requestWithURL:url parameters:parameters cachePolicy:ZHHCachePolicyCacheAndNetwork success:success failure:failure];
}

/**
 *  配置好ZHHNetworkHelper各项请求参数,封装成一个公共方法,给以上方法调用,
 *  相比在项目中单个分散的使用PPNetworkHelper/其他网络框架请求,可大大降低耦合度,方便维护
 *  在项目的后期, 你可以在公共请求方法内任意更换其他的网络请求工具,切换成本小
 */
#pragma mark - 请求的公共方法
+ (void)requestWithURL:(NSString *)URL parameters:(NSDictionary *)parameter cachePolicy:(ZHHCachePolicy)cachePolicy success:(ZHHRequestSuccess)success failure:(ZHHRequestFailure)failure {
    [self configNetworkInfo];
    // 发起请求
    [ZHHNetworkHelper zhh_postWithURL:URL parameters:parameter headers:@{} cachePolicy:cachePolicy success:^(id  _Nullable responseObject) {
        // 在这里你可以根据项目自定义其他一些重复操作,比如加载页面时候的等待效果, 提醒弹窗....
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 同上
        failure(error);
        [self handleFailureLog:task parameter:parameter error:error];
    }];
}

+ (void)configNetworkInfo{
    [ZHHNetworkHelper openLog];
    [ZHHNetworkHelper setRequestTimeoutInterval:20];
//    [ZHHNetworkHelper setRequestSerializer:ZHHRequestSerializerHTTP];
//    [ZHHNetworkHelper setResponseSerializer:ZHHResponseSerializerJSON];
    [ZHHNetworkHelper setBaseUrl:@"http://apics.chamiedu.com"];

//    if (isBody) {
        // 将参数放在body里以json格式请求(必须此代码)
//        [ZHHNetworkHelper setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
//    }
    // 在请求之前你可以统一配置你请求的相关参数 ,设置请求头, 请求参数的格式, 返回数据的格式....这样你就不需要每次请求都要设置一遍相关参数
    // 设置带有HTTP请求头的相关字段
    // 添加token
    [ZHHNetworkHelper setValue:@"" forHTTPHeaderField:@"Authorization"];
    // 添加设备
    [ZHHNetworkHelper setValue:@"1" forHTTPHeaderField:@"deviceType"];
    // 添加设备id
    [ZHHNetworkHelper setValue:@"deviceId" forHTTPHeaderField:@"deviceId"];
    
    /// 设置公共参数
    ZHHNetwrokModel *model = [[ZHHNetwrokModel alloc] init];
    model.user_id = @"70700611";
    model.token = @"a7cca2f16146f6f99a8357a69a089de5";
    
    [ZHHNetworkHelper setBaseParameters:model.mj_keyValues];
}

+ (void)handleFailureLog:(NSURLSessionTask *)task parameter:(NSDictionary *)parameter error:(NSError *)error {
    NSString *msg = @"服务器异常，请稍候再试!";
    switch (error.code) {
        case -1000:
        case -1002:
            msg = @"系统异常，请稍后再试";
            break;
        case -1001:
            msg = @"请求超时，请检查您的网络!";
            break;
        case -1005:
        case -1006:
        case -1009:
            msg = @"网络异常，请检查您的网络!";
            break;
        default:
            break;
    }
    ZHHApiLogEnd(@">>>>>>>>>>>>>>>>>>>>>👇 REQUEST FINISH 👇>>>>>>>>>>>>>>>>>>>>>>>>>>");
    ZHHApiLog(@"Request %@=======>:%@", error? @"请求失败":@"请求成功", task.currentRequest.URL.absoluteString);
    ZHHApiLog(@"requestBody======>:%@", parameter);
    ZHHApiLog(@"requstHeader=====>:%@", task.currentRequest.allHTTPHeaderFields);
    ZHHApiLog(@"response=========>:%@", task.response);
    ZHHApiLog(@"statusCode=======>:%ld", (long)((NSHTTPURLResponse *)task.response).statusCode);
    ZHHApiLog(@"error============>:%@", error);
    ZHHApiLog(@"error.code=======>:%ld", error.code);
    ZHHApiLogEnd(@"<<<<<<<<<<<<<<<<<<<<<👆 REQUEST FINISH 👆<<<<<<<<<<<<<<<<<<<<<<<<<<");
    // 判断accessToken是否过期
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
    NSInteger authCode = response.statusCode;
    if (authCode == HTTPResponseCodeOtherPlaceLogin) {
        msg = @"您的账号在其它地方登录，请检查密码是否被盗";
    } else if (authCode == HTTPResponseCodeSeverError) {
        msg = @"会话已过期";
    } else if (authCode == HTTPResponseCodeNetworkError) {
        msg = @"服务器异常，请稍候再试!";
    }
}
@end
