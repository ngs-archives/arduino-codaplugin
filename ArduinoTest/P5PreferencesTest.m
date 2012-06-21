//
//  P5PreferencesTest.m
//  Arduino
//
//  Created by Atsushi Nagase on 5/29/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "P5PreferencesTest.h"
#import "P5Preferences.h"
#import "ArduinoPlugin.h"
#import "FoundationNamedAdditions.h"

#define kTestBundleIdentifier @"org.ngsdev.codaplugin.ArduinoTest"

@implementation P5PreferencesTest

- (void)setUp {
  [[NSUserDefaults standardUserDefaults] registerDefaults:
   [NSDictionary dictionaryWithObjectsAndKeys:
    @"/Applications/Arduino.app/Contents/Resources/Java", ArduinoPluginArduinoLocationKey,
    @"uno", ArduinoPluginBoardKey,
    @"avrispmkii", ArduinoPluginProgrammerKey,
    nil]];
}

- (void)testPreferences {
  NSBundle *testBundle = [NSBundle bundleWithIdentifier:kTestBundleIdentifier];
  NSString *path = [testBundle pathForNamedAsset:@"preferences.txt"];
  P5Preferences *pref = [[P5Preferences alloc] initWithContentsOfFile:path];

  STAssertEqualObjects([pref objectForKey:@"board"],
                       @"uno", @"board = uno");
  
  STAssertEqualObjects([[pref objectForKey:@"browser"] objectForKey:@"linux"],
                       @"mozilla", @"browser.linux = mozilla");
  
  pref = [P5Preferences selectedBoardPreferences];
  STAssertEqualObjects([pref get:@"bootloader.extended_fuses"], @"0x05", nil);
  STAssertEqualObjects([pref get:@"bootloader.file"], @"optiboot_atmega328.hex", nil);
  STAssertEqualObjects([pref get:@"build.core"], @"arduino", nil);
  STAssertEqualObjects([pref get:@"name"], @"Arduino Uno", nil);
  [[NSUserDefaults standardUserDefaults] setObject:@"ethernet" forKey:ArduinoPluginBoardKey];
  pref = [P5Preferences selectedBoardPreferences];
  STAssertEqualObjects([pref get:@"name"], @"Arduino Ethernet", nil);
  NSLog(@"%@", pref);
  
}

@end
