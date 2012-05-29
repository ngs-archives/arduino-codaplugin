//
//  AVRCompilerTest.m
//  Arduino
//
//  Created by Atsushi Nagase on 5/30/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "AVRCompilerTest.h"
#import "FoundationNamedAdditions.h"
#import "AVRCompiler.h"


#define kTestBundleIdentifier @"org.ngsdev.codaplugin.ArduinoTest"

@implementation AVRCompilerTest

- (void)testExtraImports {
  NSBundle *testBundle = [NSBundle bundleWithIdentifier:kTestBundleIdentifier];
  NSString *path = [testBundle pathForNamedAsset:@"Sample.ino"];
  AVRCompiler *compiler = [[AVRCompiler alloc] initWithPath:path boardPreferences:nil];
  NSArray *includes = [compiler extraImports];
  STAssertEqualObjects(includes, [@"AAA.h BBB.h CCC.h" componentsSeparatedByString:@" "], nil);
}



@end
