//
//  AVRDudeUploader.h
//  Arduino
//
//  Created by Atsushi Nagase on 6/23/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVRTool.h"

@interface AVRDudeUploader : AVRTool

- (id)initWithPath:(NSString *)path className:(NSString *)className;

@property (strong) NSString *path;
@property (strong) NSString *className;

- (BOOL)uploadUsingPreferences:(BOOL)usingProgrammer;
- (BOOL)uploadViaBootloader;
- (BOOL)burnBootloader;



@end
