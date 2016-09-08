//
//  DLRouter.h
//  DLRouter
//
//  Created by famulei on 9/2/16.
//  Copyright © 2016 famulei. All rights reserved.
//

#import <Foundation/Foundation.h>

//FOUNDATION_EXTERN static NSString *DLRouter


@protocol DLRouterHandlerProtocol <NSObject>

- (BOOL)handleURL:(NSString *)URL userInfo:(NSDictionary *)userInfo;

@end






@interface DLRouter : NSObject

- (void)registerPatternFromPlist:(NSString *)plistName;
- (void)registerPatternWithURL:(NSString *)URL userInfo:(NSDictionary *)userInfo completionHandler:(void(^)(NSDictionary *parameters))completionHandler;
- (BOOL)openURL:(NSString *)URL userInfo:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler;
- (void)addURLHandler:(id<DLRouterHandlerProtocol>)handler;

+ (void)registerPatternWithURL:(NSString *)URL;
+ (void)registerPatternWithURL:(NSString *)URL userInfo:(NSDictionary *)userInfo completionHandler:(void(^)(NSDictionary *parameters))completionHandler;

+ (BOOL)openURL:(NSString *)URL;
+ (BOOL)openURL:(NSString *)URL userInfo:(NSDictionary *)userInfo;
+ (BOOL)openURL:(NSString *)URL completionHandler:(void(^)())completionHandler;
+ (BOOL)openURL:(NSString *)URL userInfo:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler;

+ (void)addURLHandler:(id<DLRouterHandlerProtocol>)handler;

+ (DLRouter *)sharedInstance;


@end
