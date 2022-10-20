//
//  ZHHNetworkCache.h
//  ZHHAnneKitExample
//
//  Created by 桃色三岁 on 2022/10/19.
//  Copyright © 2022 桃色三岁. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZHHNetworkCache : NSObject
/// 获取网络缓存的总大小 bytes(字节)
+ (NSInteger)zhh_allHttpCacheSize;

/// 删除所有网络缓存
+ (void)zhh_removeAllHttpCache;

/// 过滤缓存Key
+ (void)zhh_setFiltrationCacheKey:(NSArray *)filtrationCacheKey;

/**
 *  异步缓存网络数据,根据请求的 URL与parameters
 *  做KEY存储数据, 这样就能缓存多级页面的数据
 *
 *  @param responseObj  服务器返回的数据
 *  @param url          请求路径
 *  @param parameters   请求参数
 *
 *  这里是根据(url + params)拼接缓存数据对应的key值
 */
+ (void)zhh_saveHttpCache:(id)responseObj url:(NSString *)url parameters:(NSDictionary *)parameters;

/**
 *  同步 获取缓存的数据(根据存入时候填入的key值来取出对应的数据)
 *  根据请求的 URL与parameters 同步取出缓存数据
 *  @param url          请求路径
 *  @param parameters   请求参数
 *
 *  @return 缓存的数据
 */

+ (id)zhh_getHttpCacheWithURL:(NSString *)url parameters:(NSDictionary *)parameters;

/**
 *  异步 获取缓存的数据(根据存入时候填入的key值来取出对应的数据)
 *  根据请求的 URL与parameters 异步取出缓存数据
 *  @param url          请求路径
 *  @param parameters   请求参数
 *  @param block        异步回调缓存的数据
 */
+ (void)zhh_getHttpCacheWithURL:(NSString *)url parameters:(NSDictionary *)parameters block:(void(^)(id<NSCoding> object))block;

@end

NS_ASSUME_NONNULL_END
