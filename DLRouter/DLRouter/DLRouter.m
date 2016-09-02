//
//  DLRouter.m
//  DLRouter
//
//  Created by famulei on 9/2/16.
//  Copyright © 2016 famulei. All rights reserved.
//

#import "DLRouter.h"


@interface DLRouter ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *rules;

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
        self.rules = [NSMutableDictionary dictionary];
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
            [self registerPattern:fullURL patternParms:item];
        }
    }
}

- (void)registerPatternFromPlist:(NSString *)plistName
{
    [self loadRulesFromPlist:plistName];
}

- (void)registerPattern:(NSString *)url patternParms:(NSDictionary *)parms{
     NSLog(@"fullURL = %@", url);
}



@end
