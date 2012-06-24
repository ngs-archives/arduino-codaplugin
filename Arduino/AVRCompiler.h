//
//  AVRCompiler.h
//  Arduino
//
//  Created by Atsushi Nagase on 5/30/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVRTool.h"

@class P5Preferences;
@interface AVRCompiler : AVRTool


@property (strong) NSString *buildPath;
@property (readonly) NSString *source;
@property (copy) void (^progressHandler) (double progress);
@property (nonatomic) double currentProgress;

- (NSString *)runtimeLibraryName;
- (NSString *)elfPath;
- (NSString *)hexPath;
- (NSString *)eepPath;
- (NSSet *)extraImports;
- (NSSet *)importedLibraries;
- (NSString *)currentMessage;
- (NSString *)objectNameForSource:(NSString *)source buildPath:(NSString *)buildPath;

- (BOOL)compile:(BOOL)verbose
withProgressHandler:(void (^)(double progress))progressHandler
completeHandler:(void (^)(void))completeHandler
   errorHandler:(void (^)(NSError *error))errorHandler;



@end
