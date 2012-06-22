//
//  ProgressWindowController.h
//  Arduino
//
//  Created by Atsushi Nagase on 6/22/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ProgressWindowController : NSWindowController
@property (unsafe_unretained) IBOutlet NSTextView *outputTextView;
@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet NSProgressIndicator *progresIndicator;
@property (strong) NSString *outputText;

@end
