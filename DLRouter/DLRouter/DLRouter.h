//
//  DLRouter.h
//  DLRouter
//
//  Created by famulei on 9/2/16.
//  Copyright © 2016 famulei. All rights reserved.
//

#import <Foundation/Foundation.h>


//遵守 RFC标准的URL eg:http://domain/path

/* 存储结构
 @{@"scheme":
    @{@"domain":
        @{@"path":
            @{}}
     }
 };
 */



@interface DLRouter : NSObject

- (void)registerPatternFromPlist:(NSString *)plistName;

- (BOOL)canOpenURL:(NSString *)URL;

- (BOOL)openURL:(NSString *)URL;


+ (DLRouter *)sharedInstance;




@end
