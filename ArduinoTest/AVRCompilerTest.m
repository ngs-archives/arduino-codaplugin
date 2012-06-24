//
//  AVRCompilerTest.m
//  Arduino
//
//  Created by Atsushi Nagase on 5/30/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "AVRCompilerTest.h"
#import "FoundationNamedAdditions.h"
#import "P5Preferences.h"
#import "ArduinoPlugin.h"
#import "AVRCompiler.h"


#define kTestBundleIdentifier @"org.ngsdev.codaplugin.ArduinoTest"

@implementation AVRCompilerTest

- (void)setUp {
  [[NSUserDefaults standardUserDefaults] registerDefaults:
   [NSDictionary dictionaryWithObjectsAndKeys:
    @"/Applications/Arduino.app/Contents/Resources/Java", ArduinoPluginArduinoLocationKey,
    @"uno", ArduinoPluginBoardKey,
    @"avrispmkii", ArduinoPluginProgrammerKey,
    nil]];
}

- (void)testExtraImports {
  NSBundle *testBundle = [NSBundle bundleWithIdentifier:kTestBundleIdentifier];
  NSString *path = [testBundle pathForNamedAsset:@"Sample.ino"];
  AVRCompiler *compiler = [[AVRCompiler alloc] initWithPath:path boardPreferences:nil];
  NSSet *set1 = [compiler extraImports];
  NSSet *set2 = [NSSet setWithObjects:@"AAA.h", @"BBB.h", @"CCC.h", nil];
  STAssertEqualObjects(set1, set2, nil);
}

- (void)testPaths {
  NSBundle *testBundle = [NSBundle bundleWithIdentifier:kTestBundleIdentifier];
  NSString *path = [testBundle pathForNamedAsset:@"Sample.ino"];
  AVRCompiler *compiler = [[AVRCompiler alloc] initWithPath:path boardPreferences:nil];
  
  STAssertTrue([compiler.buildPath hasPrefix:NSTemporaryDirectory()], nil);
  
  STAssertEqualObjects(compiler.arduinoPath, @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino", nil);
  STAssertEqualObjects(compiler.corePath, @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino", nil);
  STAssertEqualObjects(compiler.variantPath, @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/variants/standard", nil);
}

- (void)testFileInPath {
  NSBundle *testBundle = [NSBundle bundleWithIdentifier:kTestBundleIdentifier];
  NSString *path = [testBundle pathForNamedAsset:@"Sample.ino"];
  AVRCompiler *compiler = [[AVRCompiler alloc] initWithPath:path boardPreferences:nil];
  NSSet *set1 = nil;
  NSSet *set2 = nil;
  set1 = [compiler fileInPath:compiler.arduinoPath
                withExtention:nil
                    recursive:NO];
  set2 = [NSSet setWithObjects:
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/boards.txt",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/programmers.txt", nil];
  STAssertEqualObjects(set1, set2, nil);
  set1 = [compiler fileInPath:[compiler.arduinoPath stringByAppendingString:@"/cores/arduino"]
                withExtention:@"CPP"
                    recursive:NO];
  set2 = [NSSet setWithObjects:
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino/CDC.cpp",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino/HardwareSerial.cpp",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino/HID.cpp",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino/IPAddress.cpp",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino/main.cpp",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino/new.cpp",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino/Print.cpp",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino/Stream.cpp",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino/Tone.cpp",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino/USBCore.cpp",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino/WMath.cpp",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino/WString.cpp",
          nil];
  STAssertEqualObjects(set1, set2, nil);
  set1 = [compiler fileInPath:[compiler.arduinoPath stringByAppendingString:@"/bootloaders"]
                withExtention:@"C"
                    recursive:YES];
  set2 = [NSSet setWithObjects:
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/bootloaders/atmega/ATmegaBOOT_168.c",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/bootloaders/atmega8/ATmegaBOOT.c",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/bootloaders/bt/ATmegaBOOT_168.c",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/bootloaders/caterina/Caterina.c",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/bootloaders/caterina/Descriptors.c",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/bootloaders/lilypad/src/ATmegaBOOT.c",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/bootloaders/optiboot/optiboot.c",
          @"/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/bootloaders/stk500v2/stk500boot.c",
          nil];
  STAssertEqualObjects(set1, set2, nil);
}

- (void)testImportedLibraries {
  NSBundle *testBundle = [NSBundle bundleWithIdentifier:kTestBundleIdentifier];
  NSString *path = [testBundle pathForNamedAsset:@"Sample.ino"];
  AVRCompiler *compiler = [[AVRCompiler alloc] initWithPath:path boardPreferences:nil];
  NSSet *set1 = nil;
  NSSet *set2 = nil;
  set1 = compiler.importedLibraries;
  set2 = [NSSet setWithObjects:
          @"/Applications/Arduino.app/Contents/Resources/Java/libraries/AAA",
          @"/Applications/Arduino.app/Contents/Resources/Java/libraries/BBB",
          @"/Applications/Arduino.app/Contents/Resources/Java/libraries/CCC",
          nil];
  STAssertEqualObjects(set1, set2, nil);
}

- (void)testObjectName {
  NSString *path = @"/Users/foo/Path/To/MyArduinoProject/Simple.ino";
  AVRCompiler *compiler = [[AVRCompiler alloc] initWithPath:path boardPreferences:nil];
  STAssertEqualObjects(
                       [compiler objectNameForSource:@"/Users/foo/Path/To/MyArduinoProject/lib/Bar.cpp" buildPath:@"/Users/foo/Path/To/MyArduinoProject/build/libraries"],
                       @"/Users/foo/Path/To/MyArduinoProject/build/libraries/Bar.cpp.o",
                       nil);
  
  
}


@end
