//
//  DLRouter.h
//  DLRouter
//
//  Created by famulei on 9/2/16.
//  Copyright © 2016 famulei. All rights reserved.
//

#import <Foundation/Foundation.h>





@interface DLRouter : NSObject

- (void)registerPatternFromPlist:(NSString *)plistName;

- (void)registerPatternWithURL:(NSString *)URL userInfo:(NSDictionary *)userInfo completionHandler:(void(^)(NSDictionary *parameters))completionHandler;

- (BOOL)openURL:(NSString *)URL completionHandler:(void(^)())completionHandler;


+ (void)registerPatternWithURL:(NSString *)URL;
+ (void)registerPatternWithURL:(NSString *)URL userInfo:(NSDictionary *)userInfo;
+ (void)registerPatternWithURL:(NSString *)URL userInfo:(NSDictionary *)userInfo completionHandler:(void(^)(NSDictionary *parameters))completionHandler;

+ (BOOL)openURL:(NSString *)URL;
+ (BOOL)openURL:(NSString *)URL completionHandler:(void(^)())completionHandler;

+ (DLRouter *)sharedInstance;




@end
