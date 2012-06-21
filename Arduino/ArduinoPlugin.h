//
//  ArduinoPlugin.h
//  Arduino
//
//  Created by Atsushi Nagase on 5/26/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CodaPlugInsController.h"

extern NSString *const ArduinoPluginArduinoLocationKey;
extern NSString *const ArduinoPluginBoardKey;
extern NSString *const ArduinoPluginProgrammerKey;
extern NSString *const ArduinoPluginSerialPortKey;

@class SerialMonitorWindowController, SettingsWindowController;
@interface ArduinoPlugin : NSObject<CodaPlugIn>


- (id)initWithPlugInController:(CodaPlugInsController*)aController
                 withBundleURL:(NSURL *)bundleURL;

@property (strong) CodaPlugInsController *pluginController;
@property (strong) NSURL *bundleURL;
@property (readonly) SerialMonitorWindowController *serialMonitorWindowController;
@property (readonly) SettingsWindowController *settingsMonitorWindowController;
@property (strong) void (^)(float progress); progressHandler;


@end
