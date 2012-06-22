//
//  ProgressWindowController.m
//  Arduino
//
//  Created by Atsushi Nagase on 6/22/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "ProgressWindowController.h"

@interface ProgressWindowController ()

@end

@implementation ProgressWindowController
@synthesize outputTextView = _outputTextView;
@synthesize scrollView = _scrollView;
@synthesize progresIndicator = _progresIndicator;

- (id)init {
  if(self=[super initWithWindowNibName:@"ProgressWindow" owner:self]) {
  }
  return self;
}

- (void)windowDidLoad {
  [super windowDidLoad];
  NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
  [p setLineSpacing:9];
  [self.outputTextView setDefaultParagraphStyle:p];
}

- (void)setOutputText:(NSString *)outputText {
  [self.outputTextView setString:outputText];
  [self.outputTextView setTextColor:[NSColor whiteColor] range:NSMakeRange(0, self.outputTextView.string.length)];
  [self.outputTextView scrollRangeToVisible:NSMakeRange(self.outputTextView.string.length, 0)];
}

- (NSString *)outputText {
  return self.outputTextView.string;
}

@end
