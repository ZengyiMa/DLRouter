//
//  RouterTest.m
//  DLRouter
//
//  Created by famulei on 9/2/16.
//  Copyright © 2016 famulei. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DLRouter.h"

@interface RouterTest : XCTestCase

@end

@implementation RouterTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [DLRouter registerPatternWithURL:@"f://c/a/b/c"];
    [DLRouter registerPatternWithURL:@"f://c/a/b/c/d"];
    [DLRouter registerPatternWithURL:@"f://test/:test/" userInfo:nil completionHandler:^(NSDictionary *parameters) {
        NSLog(@"parameters = %@", parameters);
    }];
    [DLRouter registerPatternWithURL:@"f://test/test/:test" userInfo:nil completionHandler:^(NSDictionary *parameters) {
        NSLog(@"parameters = %@", parameters);
    }];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testReginsterFromPlist
{
    [[DLRouter sharedInstance]registerPatternFromPlist:@"rules"];
}

- (void)testRegisterConstant
{
    [DLRouter registerPatternWithURL:@"f://a/b/c"];
    [DLRouter registerPatternWithURL:@"f://b/a/d"];
    XCTAssertTrue([DLRouter openURL:@"f://a/b/c"]);
    XCTAssertFalse([DLRouter openURL:@"f://a/d/c"]);
}

- (void)testRegisterConstantCompletion
{
    [DLRouter registerPatternWithURL:@"f://a/b/c" userInfo:@{@"a":@"b"} completionHandler:^(NSDictionary *parameters) {
        XCTAssertTrue([parameters[@"a"] isEqualToString:@"b"]);
    }];
    
    [DLRouter openURL:@"f://a/b/c"];
}


- (void)testRegisterConstantQuery
{
    [DLRouter registerPatternWithURL:@"f://a/b/c" userInfo:@{@"a":@"b"} completionHandler:^(NSDictionary *parameters) {
        XCTAssertTrue([parameters[@"a"] isEqualToString:@"b"]);
        XCTAssertTrue([parameters[@"name"] isEqualToString:@"m"]);
        XCTAssertTrue([parameters[@"lastname"] isEqualToString:@"zy"]);
        XCTAssertTrue([parameters[@"male"] isEqualToString:@"m"]);
        XCTAssertTrue([parameters[@"age"] isEqualToString:@"24"]);
        NSLog(@"parameters = %@", parameters);
    }];
    
    XCTAssertTrue([DLRouter openURL:@"f://a?name=m&lastname=zy/b?male=m/c?age=24"]);
}


- (void)testVal
{
    XCTAssertTrue([DLRouter openURL:@"f://test/test/abc"]);
    XCTAssertFalse([DLRouter openURL:@"f://a/d/c"]);
}

- (void)testOpenComptetionHandle
{
    [DLRouter registerPatternWithURL:@"f://a/b/c"];
    
    [DLRouter openURL:@"f://a/b/c" completionHandler:^{
        NSLog(@"注册成功");
        XCTAssertTrue(YES);
    }];
}






@end
