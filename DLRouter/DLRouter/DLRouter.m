//
//  DLRouter.m
//  DLRouter
//
//  Created by famulei on 9/2/16.
//  Copyright © 2016 famulei. All rights reserved.
//

#import "DLRouter.h"

#define kDLRouterWildcard @"*"

@interface DLRouterMeta : NSObject

@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, strong) NSMutableDictionary *parmas;
@property (nonatomic, strong) NSArray *keys;
@property (nonatomic, assign) BOOL includeVariable;
@end

@implementation DLRouterMeta

- (instancetype)initWithURL:(NSString *)URL
{
    self = [super init];
    if (self) {
       [self parseURL:URL];
    }
    return self;
}


- (void)parseURL:(NSString *)URL
{
    if (![URL isKindOfClass:[NSString class]] && URL.length != 0) {
        NSAssert(YES, @"URL is invalid");
        return;
    }
    
    //scheme
    NSArray *schemeAndPath = [URL componentsSeparatedByString:@"://"];
    if (schemeAndPath.count != 2) {
        NSAssert(YES, @"scheme is invalid");
        return ;
    }
    
    NSString *path = schemeAndPath.lastObject;
    if (path.length == 0) {
        NSAssert(YES, @"path is invalid");
        return ;
    }
    
    //解析path
    NSArray<NSString *> *components = [path componentsSeparatedByString:@"/"];
    if (components.count == 0) {
        return ;
    }
    
    //添加协议
    __block NSUInteger pathCount = 1;
    __block NSString *keyPath = schemeAndPath.firstObject;
    NSMutableArray *keys = [NSMutableArray array];
    
    [components enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj hasPrefix:@":"]) {
            _includeVariable = YES;
        }
        keyPath = [keyPath stringByAppendingString:[NSString stringWithFormat:@".%@", obj]];
        [keys addObject:obj];
        pathCount ++;
    }];
    
    self.keyPath = keyPath;
    self.keys = [keys copy];
}


- (NSDictionary *)parseParametersWithURL:(NSString *)URL mappedMeta:(DLRouterMeta *)meta
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    if (meta) {
        return nil;
    }
    else
    {
        for (NSString *key in self.keys) {
           NSDictionary *parms = [self parseQueryParametersWithString:key];
           [parameters addEntriesFromDictionary:parms];
        }
    }
    return [parameters copy];
}

- (NSDictionary *)parseQueryParametersWithString:(NSString *)queryString
{
    NSArray<NSString *> *paths = [queryString componentsSeparatedByString:@"?"];
    if (paths.count != 2) {
        return nil;
    }
    
    NSString *query = paths.lastObject;
    NSArray *keysAndValues = [query componentsSeparatedByString:@"&"];
    if (keysAndValues.count == 0) {
        return nil;
    }
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    for (NSString *keyValue in keysAndValues) {
       NSArray *kv = [keyValue componentsSeparatedByString:@"="];
        NSString *key = kv.firstObject;
        NSString *value = kv.lastObject;
        if (key && value) {
            parameters[key] = value;
        }
    }
    return [parameters copy];
}






@end




@interface DLRouter ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, DLRouterMeta *> *constantRules;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary *> *variableRules;

@end

@implementation DLRouter

+ (DLRouter *)sharedInstance {
    static DLRouter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [DLRouter new];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.variableRules = [NSMutableDictionary dictionary];
        self.constantRules = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)loadRulesFromPlist:(NSString *)plistName
{
   NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]pathForResource:plistName ofType:@"plist"]];
    for (NSString *scheme in plist.allKeys) {
        NSArray<NSDictionary *> *rules = plist[scheme];
        for (NSDictionary<NSString *, NSString *> *item in rules) {
            NSString *fullURL = [NSString stringWithFormat:@"%@://%@", scheme, item[@"url"]];
            [self registerPatternWithURL:fullURL patternParms:item];
        }
    }
}

- (void)registerPatternFromPlist:(NSString *)plistName
{
    [self loadRulesFromPlist:plistName];
}


- (void)registerPatternWithURL:(NSString *)URL patternParms:(NSDictionary *)parms{
    
    DLRouterMeta *meta = [[DLRouterMeta alloc]initWithURL:URL];
    if (meta.keyPath.length == 0) {
        //解析失败了。不注册
        NSAssert(YES, @"URL 解析失败");
        return;
    }
    
    if (meta.includeVariable) {
        //变量的URL集合
        NSMutableDictionary *dic = self.variableRules;
        for (NSUInteger i = 0; i < meta.keys.count; ++i) {
            NSString *key = meta.keys[i];
            NSMutableDictionary *keyDic = dic[key];
            if (!keyDic) {
                keyDic = [NSMutableDictionary dictionary];
                dic[key] = keyDic;
            }
            
            if (i == meta.keys.count - 1) {
                //最后一个
            }
            else
            {
                
            }
            
            
        }
        
        
        for (NSString *key in meta.keys) {
            
            if (!dic) {
                dic = [NSMutableDictionary dictionary];
                self.variableRules[key] = dic;
            }
        }
    }
    else
    {
        //静态的URL
        self.constantRules[meta.keyPath] = meta;
    }
}



- (BOOL)openURL:(NSString *)URL
{
    DLRouterMeta *meta = [[DLRouterMeta alloc]initWithURL:URL];
    if (meta.keyPath.length == 0) {
        return NO;
    }
    
    if (meta.includeVariable) {
        
    }
    else
    {
        //查找静态规则
        NSDictionary *dic = [meta parseParametersWithURL:URL mappedMeta:nil];
        NSLog(@"dic = %@", dic);
        return YES;
    }
    return NO;
}








@end
