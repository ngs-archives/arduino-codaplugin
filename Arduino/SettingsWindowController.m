//
//  SettingsWindowController.m
//  Arduino
//
//  Created by Atsushi Nagase on 5/29/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "SettingsWindowController.h"
#import "ArduinoPlugin.h"

@interface SettingsWindowController ()

@end

@implementation SettingsWindowController
@synthesize plugin = _plugin;
@synthesize locationTextField = _locationTextField;
@synthesize boardMenu = _boardMenu;
@synthesize serialPortMenu = _serialPortMenu;
@synthesize programmerMenu = _programmerMenu;

- (id)initWithPlugin:(ArduinoPlugin *)plugin {
  if(self=[super initWithWindowNibName:@"SettingsWindow" owner:self]) {
    self.plugin = plugin;
  }
  return self;
}

- (IBAction)selectArduinoLocation:(id)sender {
  NSLog(@"%@", sender);
}

@end
