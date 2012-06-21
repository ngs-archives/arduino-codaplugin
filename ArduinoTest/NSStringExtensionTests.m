//
//  NSStringExtensionTests.m
//  Arduino
//
//  Created by Atsushi Nagase on 6/22/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "NSStringExtensionTests.h"
#import "NSString+extension.h"

@implementation NSStringExtensionTests

- (void)testExtension {
  STAssertEqualObjects([@"/path/to/input/test.png" replacePathExtension:@"gif" inDirectory:@"/path/to/output"], @"/path/to/output/test.gif", nil);
  
}

@end
