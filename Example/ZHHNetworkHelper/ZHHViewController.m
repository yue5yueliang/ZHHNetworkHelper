//
//  ZHHViewController.m
//  ZHHNetworkHelper
//
//  Created by yue5yueliang on 10/20/2022.
//  Copyright (c) 2022 yue5yueliang. All rights reserved.
//

#import "ZHHViewController.h"
#import <Masonry/Masonry.h>
#import "ZHHNetworkHelper.h"
#import "ZHHNetwrokManage.h"

static NSString *const downloadUrl = @"https://dyy1.jb51.net/201906/tools/GitHubDesktop_jb51.zip";

@interface ZHHViewController ()
@property (strong, nonatomic) UILabel *networkDataTitle;
@property (strong, nonatomic) UILabel *cacheDataTitle;
@property (strong, nonatomic) UITextView *networkData;
@property (strong, nonatomic) UITextView *cacheData;
@property (strong, nonatomic) UILabel *cacheStatus;
@property (strong, nonatomic) UISwitch *cacheSwitch;
@property (strong, nonatomic) UIProgressView *progress;
@property (strong, nonatomic) UIButton *downloadBtn;
/** 是否开启缓存*/
@property (nonatomic, assign, getter=isCache) BOOL cache;
/** 是否开始下载*/
@property (nonatomic, assign, getter=isDownload) BOOL download;
@end

@implementation ZHHViewController
- (UIColor *)colorWithRed:(u_int8_t)red green:(u_int8_t)green blue:(u_int8_t)blue{
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
}

/// 竖屏底部安全区域
- (UIEdgeInsets)safeAreaInsets{
    UIEdgeInsets insets = UIEdgeInsetsMake(20, 0, 0, 0);
    if (@available(iOS 11.0, *)) {
        insets = [[UIApplication sharedApplication] delegate].window.safeAreaInsets;
    } else {
        // Fallback on earlier versions
    }
    return insets;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self setupUI];
    // 开启日志打印
    [ZHHNetworkHelper openLog];
    // 获取网络缓存大小
    ZHHApiLog(@"网络缓存大小cache = %fKB",[ZHHNetworkCache zhh_allHttpCacheSize]/1024.f);
    // 清理缓存 [ZHHNetworkCache zhh_removeAllHttpCache];
    // 实时监测网络状态
    [self monitorNetworkStatus];
    /*
     * 一次性获取当前网络状态
     这里延时0.1s再执行是因为程序刚刚启动,可能相关的网络服务还没有初始化完成(也有可能是AFN的BUG),
     导致此demo检测的网络状态不正确,这仅仅只是为了演示demo的功能性, 在实际使用中可直接使用一次性网络判断,不用延时
     */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self getCurrentNetworkStatus];
    });
    
    [self.cacheSwitch addTarget:self action:@selector(isCache:) forControlEvents:UIControlEventTouchUpInside];
    [self.downloadBtn addTarget:self action:@selector(download:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - 缓存开关
- (void)isCache:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"isOn"];
    [self getNetwrokData:sender.isOn];
}

#pragma mark - 下载
- (IBAction)download:(UIButton *)sender {
    static NSURLSessionTask *task = nil;
    //开始下载
    if(!self.isDownload)  {
        self.download = YES;
        [self.downloadBtn setTitle:@"取消下载" forState:UIControlStateNormal];
        task = [ZHHNetworkHelper zhh_downloadWithURL:downloadUrl progress:^(NSProgress *progress) {
            CGFloat stauts = 100.f * progress.completedUnitCount/progress.totalUnitCount;
            self.progress.progress = stauts/100.f;
            ZHHApiLog(@"下载进度 :%.2f%%\n",stauts);
        } success:^(NSString *filePath) {
            [self.downloadBtn setTitle:@"重新下载" forState:UIControlStateNormal];
            ZHHApiLog(@"下载完成filePath = %@",filePath);
        } failure:^(NSError *error) {
            ZHHApiLog(@"下载失败error = %@",error);
        }];
    } else {
        //暂停下载
        self.download = NO;
        [task suspend];
        self.progress.progress = 0;
        [self.downloadBtn setTitle:@"开始下载" forState:UIControlStateNormal];
    }
}

#pragma  mark - 获取数据请求示例 GET请求自动缓存与无缓存
#pragma  mark - 这里的请求只是一个演示, 在真实的项目中建议不要这样做, 具体做法可以参照PPHTTPRequestLayer文件夹的例子
- (void)getNetwrokData:(BOOL)isOn{
    if(isOn) {
        // 缓存数据
        self.cacheStatus.text = @"关闭缓存";
        self.cacheSwitch.on = YES;
        [ZHHNetwrokManage api_get_cache:nil success:^(id  _Nonnull responseObject) {
            self.networkData.text = @"";
            self.cacheData.text = [self jsonToString:responseObject];
        } failure:^(NSError * _Nonnull error) {
            
        }];
    } else {
        // 网络数据
        self.cacheStatus.text = @"打开缓存";
        self.cacheSwitch.on = NO;
        self.cacheData.text = @"";
        [ZHHNetwrokManage api_get_network:nil success:^(id  _Nonnull responseObject) {
            self.cacheData.text = @"";
            self.networkData.text = [self jsonToString:responseObject];
        } failure:^(NSError * _Nonnull error) {
            
        }];
    }
}

/**
 *  json转字符串
 */
- (NSString *)jsonToString:(NSDictionary *)dic {
    if(!dic){
        return nil;
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

#pragma mark - 实时监测网络状态
- (void)monitorNetworkStatus {
    // 网络状态改变一次, networkStatusWithBlock就会响应一次
    [ZHHNetworkHelper zhh_networkStatusWithBlock:^(ZHHNetworkStatusType networkStatus) {
        switch (networkStatus) {
            case ZHHNetworkStatusUnknown:
                // 未知网络
                break;
            case ZHHNetworkStatusNotReachable:
                // 无网络
                self.networkData.text = @"没有网络";
                [self getNetwrokData:YES];
                ZHHApiLog(@"无网络,加载缓存数据");
                break;
            case ZHHNetworkStatusReachableViaWWAN:
                // 手机网络
            case ZHHNetworkStatusReachableViaWiFi:
                // 无线网络
                [self getNetwrokData:[[NSUserDefaults standardUserDefaults] boolForKey:@"isOn"]];
                ZHHApiLog(@"有网络,请求网络数据");
                break;
        }
        
    }];
}

#pragma mark - 一次性获取当前最新网络状态
- (void)getCurrentNetworkStatus {
    if (kIsNetwork) {
        ZHHApiLog(@"有网络");
        if (kIsWWANNetwork) {
            ZHHApiLog(@"手机网络");
        }else if (kIsWiFiNetwork){
            ZHHApiLog(@"WiFi网络");
        }
    } else {
        ZHHApiLog(@"无网络");
    }
    // 或
//    if ([ZHHNetworkHelper isNetwork]) {
//        ZHHApiLog(@"有网络");
//        if ([ZHHNetworkHelper isWWANNetwork]) {
//            ZHHApiLog(@"手机网络");
//        }else if ([ZHHNetworkHelper isWiFiNetwork]){
//            ZHHApiLog(@"WiFi网络");
//        }
//    } else {
//        ZHHApiLog(@"无网络");
//    }
}


- (void)setupUI{
    UILabel *networkDataTitle = [[UILabel alloc] init];
    networkDataTitle.font = [UIFont systemFontOfSize:14];
    networkDataTitle.text = @"网络数据";
    [self.view addSubview:networkDataTitle];
    self.networkDataTitle = networkDataTitle;
    
    UITextView *networkData = [[UITextView alloc] init];
    networkData.font = [UIFont systemFontOfSize:14];
    networkData.backgroundColor = [self colorWithRed:239 green:239 blue:244];
    networkData.editable = NO;
    [self.view addSubview:networkData];
    self.networkData = networkData;
    
    UILabel *cacheDataTitle = [[UILabel alloc] init];
    cacheDataTitle.font = [UIFont systemFontOfSize:14];
    cacheDataTitle.text = @"缓存数据";
    [self.view addSubview:cacheDataTitle];
    self.cacheDataTitle = cacheDataTitle;
    
    UITextView *cacheData = [[UITextView alloc] init];
    cacheData.font = [UIFont systemFontOfSize:14];
    cacheData.backgroundColor = [self colorWithRed:239 green:239 blue:244];
    cacheData.editable = NO;
    [self.view addSubview:cacheData];
    self.cacheData = cacheData;
    
    UILabel *cacheStatus = [[UILabel alloc] init];
    cacheStatus.font = [UIFont systemFontOfSize:14];
    cacheStatus.text = @"开启缓存";
    [self.view addSubview:cacheStatus];
    self.cacheStatus = cacheStatus;
    
    UISwitch *cacheSwitch = [[UISwitch alloc] init];
    [self.view addSubview:cacheSwitch];
    self.cacheSwitch = cacheSwitch;
    
    UIProgressView *progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    //设置进度条颜色
    progress.trackTintColor = [self colorWithRed:239 green:239 blue:244];
    //设置进度条上进度的颜色
    progress.progressTintColor = [UIColor redColor];
    [self.view addSubview:progress];
    self.progress = progress;
    
    UIButton *downloadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    downloadBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [downloadBtn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [downloadBtn setTitleColor:UIColor.lightGrayColor forState:UIControlStateHighlighted];
    [downloadBtn setTitle:@"开始下载" forState:UIControlStateNormal];
    [self.view addSubview:downloadBtn];
    self.downloadBtn = downloadBtn;
    
    [self.networkData mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.height.equalTo(@(250));
        make.top.equalTo(self.view).offset([self safeAreaInsets].top + 44);
    }];
    
    [self.networkDataTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.networkData);
        make.bottom.equalTo(self.networkData.mas_top).offset(-10);
    }];
    
    [self.cacheData mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.height.equalTo(self.networkData);
        make.top.equalTo(self.networkData.mas_bottom).offset(44);
    }];
    
    [self.cacheDataTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cacheData);
        make.bottom.equalTo(self.cacheData.mas_top).offset(-10);
    }];
    
    [self.cacheSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cacheData.mas_bottom).offset(10);
        make.left.equalTo(self.cacheStatus.mas_right).offset(5);
    }];
    
    [self.cacheStatus mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cacheData);
        make.centerY.equalTo(self.cacheSwitch);
    }];
    
    [self.progress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.networkData);
        make.top.equalTo(self.cacheSwitch.mas_bottom).offset(20);
        make.height.equalTo(@(2));
    }];
    [self.downloadBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.progress.mas_bottom).offset(20);
    }];
}
@end
