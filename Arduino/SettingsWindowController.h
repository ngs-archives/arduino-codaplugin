//
//  SettingsWindowController.h
//  Arduino
//
//  Created by Atsushi Nagase on 5/29/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ArduinoPlugin;
@interface SettingsWindowController : NSWindowController

- (id)initWithPlugin:(ArduinoPlugin *)plugin;

@property (weak) ArduinoPlugin *plugin;
@property (weak) IBOutlet NSTextField *locationTextField;
@property (weak) IBOutlet NSMenu *boardMenu;
@property (weak) IBOutlet NSMenu *serialPortMenu;
@property (weak) IBOutlet NSMenu *programmerMenu;

- (IBAction)selectArduinoLocation:(id)sender;

@end
