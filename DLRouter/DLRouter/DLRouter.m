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
    [keys addObject:keyPath];
    
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
        
        for (NSUInteger i = 0; i < self.keys.count; ++i) {
            NSString *mkey = meta.keys[i];
            if ([mkey hasPrefix:@":"]) {
                //变量
                parameters[mkey] = self.keys[i];
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
        [self registerVariableRulesWithMeta:meta];
        
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
    
    //先找变量表
    DLRouterMeta *urlMeta = [self lookUpVariableRulesWithMeta:meta];
    if (urlMeta) {
        NSDictionary *dic = [meta parseParametersWithURL:URL mappedMeta:urlMeta];
        
        return YES;
    }
    else
    {
        NSDictionary *dic = [meta parseParametersWithURL:URL mappedMeta:nil];
        return YES;
    }
       return NO;
}


- (DLRouterMeta *)lookUpVariableRulesWithMeta:(DLRouterMeta *)meta
{
    NSDictionary *dic = self.variableRules;
    DLRouterMeta *lookupMeta = nil;
    for (NSString *key in meta.keys) {

        
       NSDictionary *resultDic = dic[key];
        if (!resultDic) {
            //找不到key的时候
            resultDic = dic[@"DLROUTER_VARLIST"];
        }
        
        dic = resultDic;
        lookupMeta = dic[@"meta"];
        if (lookupMeta) {
            break;
        }
    }

    return lookupMeta;
}


///可变参数存储结构

//前面是参数个数
//   @{@"3":@{}}


- (void)registerVariableRulesWithMeta:(DLRouterMeta *)meta
{
    if (!meta.includeVariable) {
        return;
    }
    NSString *count = @(meta.keys.count).stringValue;
    
   __block NSMutableDictionary *dic = self.variableRules;
    
    [meta.keys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *key = obj;
      
        if ([key hasPrefix:@":"]) {
            //变量
             NSMutableDictionary *d = dic[@"DLROUTER_VARLIST"];
            if (!d) {
                d = [NSMutableDictionary dictionary];
                dic[@"DLROUTER_VARLIST"] = d;
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
    
    NSLog(@"VariableRules = %@", self.variableRules);
}








@end
