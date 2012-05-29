//
//  ArduinoPlugin.h
//  Arduino
//
//  Created by Atsushi Nagase on 5/26/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CodaPlugInsController.h"

@class SerialMonitorWindowController, Port;
@interface ArduinoPlugin : NSObject<CodaPlugIn>


- (id)initWithPlugInController:(CodaPlugInsController*)aController
                 withBundleURL:(NSURL *)bundleURL;

@property (strong) CodaPlugInsController *pluginController;
@property (strong) NSURL *bundleURL;
@property (readonly) SerialMonitorWindowController *serialMonitorWindowController;
@property (strong) Port *port;

@end
