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
  NSString *str = [NSString stringNamed:@"preferences.txt" bundleIdentifier:kTestBundleIdentifier];
  P5Preferences *pref = [[P5Preferences alloc] initWithString:str];
  
}

@end
