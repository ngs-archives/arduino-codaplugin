//
//  P5PreferencesTest.m
//  Arduino
//
//  Created by Atsushi Nagase on 5/29/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "P5PreferencesTest.h"
#import "P5Preferences.h"
#import "FoundationNamedAdditions.h"

#define kTestBundleIdentifier @"org.ngsdev.codaplugin.ArduinoTest"

@implementation P5PreferencesTest

- (void)testPreferences {
  NSBundle *testBundle = [NSBundle bundleWithIdentifier:kTestBundleIdentifier];
  NSString *path = [testBundle pathForNamedAsset:@"preferences.txt"];
  P5Preferences *pref = [[P5Preferences alloc] initWithContentsOfFile:path];

  STAssertEqualObjects([pref objectForKey:@"board"],
                       @"uno", @"board = uno");
  
  STAssertEqualObjects([[pref objectForKey:@"browser"] objectForKey:@"linux"],
                       @"mozilla", @"browser.linux = mozilla");
}

@end
