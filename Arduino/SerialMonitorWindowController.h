//
//  SerialMonitorWindowController.h
//  Arduino
//
//  Created by Atsushi Nagase on 5/28/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ArduinoPlugin;
@interface SerialMonitorWindowController : NSWindowController<NSTableViewDelegate, NSTextFieldDelegate>

- (id)initWithPlugin:(ArduinoPlugin *)plugin;

@property (weak) ArduinoPlugin *plugin;
@property (weak) IBOutlet NSTextField *inputTextField;
@property (unsafe_unretained) IBOutlet NSTextView *outputTextView;
@property (weak) IBOutlet NSScrollView *scrollView;

@end
