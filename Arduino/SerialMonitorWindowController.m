//
//  SerialMonitorWindowController.m
//  Arduino
//
//  Created by Atsushi Nagase on 5/28/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "SerialMonitorWindowController.h"
#import "ArduinoPlugin.h"
#import "Port.h"

@interface SerialMonitorWindowController ()

@property (atomic, strong) NSLock *termioLock;
@property (strong) Port *port;

@end

@implementation SerialMonitorWindowController
@synthesize inputTextField = _inputTextField;
@synthesize outputTextView = _outputTextView;
@synthesize scrollView = _scrollView;

@synthesize plugin = _plugin
, termioLock = _termioLock
, port = _port
;

- (id)initWithPlugin:(ArduinoPlugin *)plugin {
  if(self=[super initWithWindowNibName:@"SerialMonitorWindow" owner:self]) {
    self.plugin = plugin;
    self.termioLock = [[NSLock alloc] init];
    self.port = [[Port alloc] initWithPath:@"/dev/cu.usbmodemfd4131"];
  }
  return self;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
  if(commandSelector == @selector(insertNewline:)) {
    [self.port send:textView.string];
    textView.string = @"";
    return NO;
  }
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  [textView performSelector:(SEL)commandSelector];
  #pragma clang diagnostic pop
  return YES;
}

- (void)windowDidLoad {
  [super windowDidLoad];
  id tf = [self.inputTextField currentEditor];
  [tf setInsertionPointColor:[NSColor whiteColor]];
  NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
  [p setLineSpacing:10];
  [self.outputTextView setDefaultParagraphStyle:p];
}

- (void)showWindow:(id)sender {
  [super showWindow:sender];
  [self.port watch:^BOOL(NSString *status) {
    [self.outputTextView replaceCharactersInRange:NSMakeRange(self.outputTextView.string.length, 0) withString:status];
    [self.outputTextView setTextColor:[NSColor whiteColor] range:NSMakeRange(0, self.outputTextView.string.length)];
    [self.outputTextView scrollRangeToVisible:NSMakeRange(self.outputTextView.string.length, 0)];
    return YES;
  }];
}

-(void)windowWillClose:(NSNotification *)aNotification {
  [self.port close];
}



@end
