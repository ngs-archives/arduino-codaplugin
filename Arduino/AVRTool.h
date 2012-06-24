//
//  AVRTool.h
//  Arduino
//
//  Created by Atsushi Nagase on 6/23/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const AVRCompileException;

@class P5Preferences;
@interface AVRTool : NSObject


@property (strong) P5Preferences *boardPreferences;
@property (nonatomic) dispatch_queue_t buildQueue;
@property (strong) NSString *path;
@property (copy) void (^completeHandler) (void);
@property (copy) void (^errorHandler) (NSError *error);
@property (strong) NSMutableArray *messages;

- (NSString *)avrdudePath;
- (NSString *)avrdudeConfPath;
- (NSString *)corePath;
- (NSString *)arduinoPath;
- (NSString *)variantPath;
- (NSString *)gccPath;
- (NSString *)gccppPath;
- (NSString *)avrarPath;
- (NSString *)avrobjcopyPath;
- (NSString *)avrBasePath;
- (NSString *)hardwarePath;
- (NSString *)librariesPath;

- (id)initWithPath:(NSString *)path
  boardPreferences:(P5Preferences *)boardPreferences;

- (NSSet *)fileInPath:(NSString *)path
        withExtention:(NSString *)extention
            recursive:(BOOL)recursive;

- (BOOL)launchTask:(NSTask *)task verbose:(BOOL)verbose;

@end
