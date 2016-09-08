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
@property (nonatomic, strong) NSDictionary *userInfo;
@property (nonatomic, copy) void(^completionHandle)(NSDictionary *parameters);
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
    [keys addObject:keyPath];
    
    [components enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.length != 0) {
            NSString *mkeyPath = obj;
            if ([obj hasPrefix:@":"]) {
                _includeVariable = YES;
            }
            
            NSArray *queryArr = [obj componentsSeparatedByString:@"?"];
            if (queryArr.count > 1) {
                mkeyPath = queryArr.firstObject;
            }
            
            keyPath = [keyPath stringByAppendingString:[NSString stringWithFormat:@".%@", mkeyPath]];
            [keys addObject:obj];
            pathCount ++;

        }
        
    }];
    
    self.keyPath = keyPath;
    self.keys = [keys copy];
}


- (NSDictionary *)parseParametersWithURL:(NSString *)URL mappedMeta:(DLRouterMeta *)meta
{
    if (meta == nil) {
        return nil;
    }
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (meta.userInfo) {
        [parameters addEntriesFromDictionary:meta.userInfo];
    }
    if (meta.includeVariable) {
        if (self.keys.count != meta.keys.count) {
            return nil;
        }
        for (NSUInteger i = 0; i < self.keys.count; ++i) {
            NSString *mkey = meta.keys[i];
            if ([mkey hasPrefix:@":"]) {
                //变量
                NSString *keyStr = [mkey substringFromIndex:1];
                if (keyStr.length != 0) {
                    NSString *value = self.keys[i];
                    NSArray *queryArray = [value componentsSeparatedByString:@"?"];
                    if (queryArray.count > 1) {
                        value = queryArray.firstObject;
                        [parameters addEntriesFromDictionary:[self parseQueryParametersWithString:queryArray.lastObject]];
                    }
                    parameters[keyStr] = value;
                }
            }
            NSDictionary *parms = [self parseQueryParametersWithString:self.keys[i]];
            [parameters addEntriesFromDictionary:parms];
        }
    }
    else
    {
        for (NSString *key in self.keys) {
           NSDictionary *parms = [self parseQueryParametersWithString:key];
           [parameters addEntriesFromDictionary:parms];
        }
    }
    
    return parameters;
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

@property (nonatomic, strong) NSMutableArray *handlers;
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
        self.handlers = [NSMutableArray array];
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
            [self registerPatternWithURL:fullURL userInfo:item completionHandler:nil];
        }
    }
}

- (void)registerPatternFromPlist:(NSString *)plistName
{
    [self loadRulesFromPlist:plistName];
}


- (void)registerPatternWithURL:(NSString *)URL userInfo:(NSDictionary *)userInfo completionHandler:(void(^)(NSDictionary *parameters))completionHandler;
{
    DLRouterMeta *meta = [[DLRouterMeta alloc]initWithURL:URL];
    meta.completionHandle = completionHandler;
    meta.userInfo = userInfo;
    if (meta.keyPath.length == 0) {
        //解析失败了。不注册
        NSAssert(YES, @"URL 解析失败");
        return;
    }
    
    if (meta.includeVariable) {
        //变量的URL集合
        [self registerVariableRulesWithMeta:meta];
        
    }
    else
    {
        //静态的URL
        self.constantRules[meta.keyPath] = meta;
    }
}



- (BOOL)openURL:(NSString *)URL completionHandler:(void (^)())completionHandler
{
    DLRouterMeta *meta = [[DLRouterMeta alloc]initWithURL:URL];
    if (meta.keyPath.length == 0) {
        return NO;
    }
    
    //先找变量表
    DLRouterMeta *urlMeta = [self lookUpVariableRulesWithMeta:meta];
    NSDictionary *parameters = nil;
    if (!urlMeta) {
        urlMeta = self.constantRules[meta.keyPath];
    }
    
    if (urlMeta) {
        parameters = [meta parseParametersWithURL:URL mappedMeta:urlMeta];
        
        BOOL hadHandle = NO;
        if (self.handlers.count != 0) {
            for (id<DLRouterHandlerProtocol> handler in self.handlers) {
               hadHandle = [handler handleURL:URL userInfo:parameters];
                if (hadHandle) {
                    break;
                }
            }
        }
        
        if (hadHandle == NO) {
            if (urlMeta.completionHandle) {
                urlMeta.completionHandle(parameters);
            }
        }
        
        if (completionHandler) {
            completionHandler();
        }
        return YES;
    }
    return NO;
}


- (DLRouterMeta *)lookUpVariableRulesWithMeta:(DLRouterMeta *)meta
{
    NSDictionary *dic = self.variableRules;
    DLRouterMeta *lookupMeta = nil;
    for (NSString *key in [meta.keyPath componentsSeparatedByString:@"."]) {

        
       NSDictionary *resultDic = dic[key];
        if (!resultDic) {
            //找不到key的时候
            resultDic = dic[@"*"];
        }
        
        dic = resultDic;
        lookupMeta = dic[@"meta"];
        if (lookupMeta) {
            break;
        }
    }

    return lookupMeta;
}

- (void)registerVariableRulesWithMeta:(DLRouterMeta *)meta
{
    if (!meta.includeVariable) {
        return;
    }
   __block NSMutableDictionary *dic = self.variableRules;
    
    [meta.keys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *key = obj;
      
        if ([key hasPrefix:@":"]) {
            //变量
             NSMutableDictionary *d = dic[@"*"];
            if (!d) {
                d = [NSMutableDictionary dictionary];
                dic[@"*"] = d;
            }
            if (idx == meta.keys.count - 1) {
                //最后一个
                d[@"meta"] = meta;
            }
            dic = d;
        }
        else
        {
            NSMutableDictionary *d =  dic[key];
            if (!d) {
                d = [NSMutableDictionary dictionary];
                dic[key] = d;
            }
            if (idx == meta.keys.count - 1) {
                //最后一个
                d[@"meta"] = meta;
            }
            dic = d;

        }

           }];
    
//    NSLog(@"VariableRules = %@", self.variableRules);
}


- (void)addURLHandler:(id<DLRouterHandlerProtocol>)handler
{
    [self.handlers addObject:handler];
}

+ (void)registerPatternWithURL:(NSString *)URL
{
    [[DLRouter sharedInstance]registerPatternWithURL:URL userInfo:nil completionHandler:nil];
}

+ (void)registerPatternWithURL:(NSString *)URL userInfo:(NSDictionary *)userInfo
{
    [[DLRouter sharedInstance]registerPatternWithURL:URL userInfo:userInfo completionHandler:nil];
}

+ (void)registerPatternWithURL:(NSString *)URL userInfo:(NSDictionary *)userInfo completionHandler:(void (^)(NSDictionary *))completionHandler
{
    [[DLRouter sharedInstance]registerPatternWithURL:URL userInfo:userInfo completionHandler:completionHandler];
}

+ (BOOL)openURL:(NSString *)URL
{
   return [[DLRouter sharedInstance]openURL:URL completionHandler:nil];
}

+ (BOOL)openURL:(NSString *)URL completionHandler:(void (^)())completionHandler
{
   return [[DLRouter sharedInstance]openURL:URL completionHandler:completionHandler];
}

+ (void)addURLHandler:(id<DLRouterHandlerProtocol>)handler
{
    [[DLRouter sharedInstance]addURLHandler:handler];
}







@end
