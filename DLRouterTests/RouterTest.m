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
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//- (void)testExample {
//    // This is an example of a functional test case.
//    // Use XCTAssert and related functions to verify your tests produce the correct results.
//}
//
//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

- (void)testReginster
{
    [[DLRouter sharedInstance]registerPatternFromPlist:@"rules"];
}


- (void)testLookUpConstantURL
{
    [self testReginster];
   BOOL ok = [[DLRouter sharedInstance]openURL:@"famulei://test/a/b/c"];
    XCTAssertTrue(ok);
}

- (void)testLookUpConstantURLAndQuery
{
    [self testReginster];
    BOOL ok = [[DLRouter sharedInstance]openURL:@"famulei://test/a/b?a=1&b=2/c?c=3&d=4"];
    XCTAssertTrue(ok);
}




@end
