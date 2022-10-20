//
//  ZHHNetworkCache.m
//  ZHHAnneKitExample
//
//  Created by 桃色三岁 on 2022/10/19.
//  Copyright © 2022 桃色三岁. All rights reserved.
//

#import "ZHHNetworkCache.h"
#if __has_include(<YYCache/YYCache.h>)
#import <YYCache/YYCache.h>
#else
#import "YYCache.h"
#endif
#import "YYDiskCache.h"

static YYCache *_dataCache;
static NSArray *_filtrationCacheKey;
static NSString *const kZHHNetworkResponseCache = @"kZHHNetworkResponseCache";

@implementation ZHHNetworkCache
+ (void)initialize {
    _dataCache = [YYCache cacheWithName:kZHHNetworkResponseCache];
}

#pragma mark - 获取网络缓存的总大小
+ (NSInteger)zhh_allHttpCacheSize {
    return [_dataCache.diskCache totalCost];
}

#pragma mark - 删除所有网络缓存
+ (void)zhh_removeAllHttpCache {
    [_dataCache.diskCache removeAllObjects];
}

#pragma mark - 过滤缓存Key
+ (void)zhh_setFiltrationCacheKey:(NSArray *)filtrationCacheKey {
    _filtrationCacheKey = filtrationCacheKey;
}

#pragma mark - 缓存网络数据
+ (void)zhh_saveHttpCache:(id)responseObj url:(NSString *)url parameters:(NSDictionary *)parameters {
    NSString *cacheKey = [self zhh_cacheKeyWithURL:url parameters:parameters];
    // 异步缓存,不会阻塞主线程
    [_dataCache setObject:responseObj forKey:cacheKey withBlock:nil];
}

#pragma mark - 同步 获取缓存的数据
+ (id)zhh_getHttpCacheWithURL:(NSString *)url parameters:(NSDictionary *)parameters {
    NSString *cacheKey = [self zhh_cacheKeyWithURL:url parameters:parameters];
    // 根据存入时候填入的key值来取出对应的数据
    return [_dataCache objectForKey:cacheKey];
}

#pragma mark - 异步 获取缓存的数据
+ (void)zhh_getHttpCacheWithURL:(NSString *)url parameters:(NSDictionary *)parameters block:(void(^)(id<NSCoding> object))block {
    NSString *cacheKey = [self zhh_cacheKeyWithURL:url parameters:parameters];
    [_dataCache objectForKey:cacheKey withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nonnull object) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(object);
        });
    }];
}

#pragma mark - 获取缓存数据对应的key值
+ (NSString *)zhh_cacheKeyWithURL:(NSString *)url parameters:(NSDictionary *)parameters {
    if (parameters == nil) {
        return url;
    }
    // 过滤指定的参数
    if (_filtrationCacheKey.count > 0) {
        NSMutableDictionary *mutableDic = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [mutableDic removeObjectsForKeys:_filtrationCacheKey];
        parameters =  [mutableDic copy];
    }
    
    // 将参数字典转换成字符串
    NSData *data = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
    NSString *parameterStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // 将url与转换好的参数字符串拼接在一起，成为最终存储的key值
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@", url, parameterStr];
    return cacheKey;
}
@end
