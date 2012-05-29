//
//  SettingsWindowController.m
//  Arduino
//
//  Created by Atsushi Nagase on 5/29/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "SettingsWindowController.h"
#import "ArduinoPlugin.h"
#import "P5Preferences.h"
#import <IOKit/IOKitLib.h>
#import <IOKit/serial/IOSerialKeys.h>

#define kBoardsTxtPath @"/hardware/arduino/boards.txt"
#define kProgrammersTxtPath @"/hardware/arduino/programmers.txt"
#define kAvrdudePath @"/hardware/tools/avr/bin/avrdude"


@interface SettingsWindowController ()

- (void)loadPreferences;
- (void)refreshSerialPorts;

@end

@implementation SettingsWindowController
@synthesize boardPopUpButton = _boardPopUpButton;
@synthesize serialPortPopUpButton = _serialPortPopUpButton;
@synthesize programmerPopUpButton = _programmerPopUpButton;
@synthesize plugin = _plugin
, locationTextField = _locationTextField
, boardMenu = _boardMenu
, serialPortMenu = _serialPortMenu
, programmerMenu = _programmerMenu
, programmerPreferences = _programmerPreferences
, boardPreferences = _boardPreferences
;

- (id)initWithPlugin:(ArduinoPlugin *)plugin {
  if(self=[super initWithWindowNibName:@"SettingsWindow" owner:self]) {
    self.plugin = plugin;
  }
  return self;
}

- (void)windowDidLoad {
  [super windowDidLoad];
  [self loadPreferences];
}

- (void)showWindow:(id)sender {
  [super showWindow:self];
  [self refreshSerialPorts];
}

- (IBAction)selectArduinoLocation:(id)sender {
  NSOpenPanel *pane = [NSOpenPanel openPanel];
  [pane setCanChooseFiles:NO];
  [pane setCanChooseDirectories:YES];
  [pane setTreatsFilePackagesAsDirectories:YES];
  [pane beginWithCompletionHandler:^(NSInteger result) {
    if(result == NSOKButton && pane.URL) {
      NSString *path = pane.URL.path;
      NSFileManager *manager = [NSFileManager defaultManager];
      if(![manager fileExistsAtPath:[path stringByAppendingString:kAvrdudePath]])
        path = [path stringByAppendingString:@"/Contents/Resources/Java"];
      if(![manager fileExistsAtPath:[path stringByAppendingString:kAvrdudePath]]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Selected directory does not contain an Arduino SDK."
                                         defaultButton:@"OK" alternateButton:nil otherButton:nil
                             informativeTextWithFormat:@"Select a correct Arduino SDK directory."];
        [alert runModal];
      } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:path forKey:ArduinoPluginArduinoLocationKey];
        [defaults synchronize];
        [self loadPreferences];
      }
    }
  }];
  
}

- (void)loadPreferences {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *loc = [defaults valueForKey:ArduinoPluginArduinoLocationKey];
  self.boardPreferences = [[P5Preferences alloc] initWithContentsOfFile:[loc stringByAppendingString:kBoardsTxtPath]];
  self.programmerPreferences = [[P5Preferences alloc] initWithContentsOfFile:[loc stringByAppendingString:kProgrammersTxtPath]];
  
  NSInteger idx = 0;
  NSInteger selectedIndex = 0;
  NSString *key = nil;
  NSString *name = nil;
  NSString *value = nil;
  NSArray *keys = nil;
  NSDictionary *obj = nil;
  P5Preferences *prefs = nil;
  NSMenuItem *item = nil;
  SEL action = nil;
  NSPopUpButton *button = nil;
  
  //
  
  prefs = self.boardPreferences;
  action = @selector(didSelectBoard:);
  value = [defaults valueForKey:ArduinoPluginBoardKey];
  button = self.boardPopUpButton;
  
  [button removeAllItems];
  keys = prefs.allKeys;
  for(idx = 0, selectedIndex = 0;idx < keys.count; idx++) {
    key = [keys objectAtIndex:idx];
    obj = [prefs objectForKey:key];
    name = [obj valueForKey:@"name"];
    item = [[NSMenuItem alloc] initWithTitle:name action:action keyEquivalent:@""];
    item.tag = idx;
    if([value isEqualToString:key])
      selectedIndex = idx;
    [button.menu addItem:item];
  }
  [button selectItemAtIndex:selectedIndex];
  
  //
  
  prefs = self.programmerPreferences;
  action = @selector(didSelectBoard:);
  value = [defaults valueForKey:ArduinoPluginProgrammerKey];
  button = self.programmerPopUpButton;
  
  [button removeAllItems];
  keys = prefs.allKeys;
  for(idx = 0, selectedIndex = 0;idx < keys.count; idx++) {
    key = [keys objectAtIndex:idx];
    obj = [prefs objectForKey:key];
    name = [obj valueForKey:@"name"];
    item = [[NSMenuItem alloc] initWithTitle:name action:action keyEquivalent:@""];
    item.tag = idx;
    if([value isEqualToString:key])
      selectedIndex = idx;
    [button.menu addItem:item];
  }
  [button selectItemAtIndex:selectedIndex];
  
}

- (void)refreshSerialPorts {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *port = [defaults valueForKey:ArduinoPluginSerialPortKey];
  NSInteger selectedIndex = 0;
  NSInteger index = 0;
  io_object_t serialPort;
  io_iterator_t serialPortIterator;
  IOServiceGetMatchingServices(
                               kIOMasterPortDefault, 
                               IOServiceMatching(kIOSerialBSDServiceValue), 
                               &serialPortIterator);
  [self.serialPortPopUpButton.menu removeAllItems];
  while ((serialPort = IOIteratorNext(serialPortIterator))) {
    CFStringRef ref = IORegistryEntryCreateCFProperty(serialPort, CFSTR(kIOCalloutDeviceKey), kCFAllocatorDefault, 0);
    NSString *path = [[NSString alloc] initWithFormat:@"%@", ref];
    NSMenuItem *item = [self.serialPortPopUpButton.menu addItemWithTitle:path action:@selector(didSelectSerialPort:) keyEquivalent:@""];
    if(port&&[path isEqualToString:port])
      selectedIndex = index;
    item.tag = index++;
    IOObjectRelease(serialPort);
  }
  [self.serialPortPopUpButton selectItemAtIndex:selectedIndex];
  IOObjectRelease(serialPortIterator);
}

- (void)didSelectBoard:(id)sender {
  NSMenuItem *item = sender;
  NSString *key = [self.boardPreferences.allKeys objectAtIndex:item.tag];
  NSLog(@"%@", key);
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setValue:key forKey:ArduinoPluginBoardKey];
  [defaults synchronize];
}

- (void)didSelectProgrammer:(id)sender {
  NSMenuItem *item = sender;
  NSString *key = [self.programmerPreferences.allKeys objectAtIndex:item.tag];
  NSLog(@"%@", key);
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setValue:key forKey:ArduinoPluginProgrammerKey];
  [defaults synchronize];
}

- (void)didSelectSerialPort:(id)sender {
  NSMenuItem *item = sender;
  NSString *key = item.title;
  NSLog(@"%@", key);
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setValue:key forKey:ArduinoPluginSerialPortKey];
  [defaults synchronize];
}

@end
