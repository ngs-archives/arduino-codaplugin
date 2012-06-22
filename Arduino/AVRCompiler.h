//
//  AVRCompiler.h
//  Arduino
//
//  Created by Atsushi Nagase on 5/30/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const AVRCompileException;

@class P5Preferences;
@interface AVRCompiler : NSObject

@property (strong) NSString *path;
@property (strong) NSString *buildPath;
@property (readonly) NSString *source;
@property (strong) P5Preferences *boardPreferences;
@property (strong) NSMutableArray *messages;
@property (nonatomic) dispatch_queue_t buildQueue;
@property (copy) void (^progressHandler) (double progress);
@property (copy) void (^completeHandler) (void);
@property (nonatomic) double currentProgress;

- (NSString *)corePath;
- (NSString *)arduinoPath;
- (NSString *)variantPath;
- (NSString *)gccPath;
- (NSString *)gccppPath;
- (NSString *)avrarPath;
- (NSString *)avrobjcopyPath;
- (NSString *)runtimeLibraryName;
- (NSString *)librariesPath;
- (NSSet *)extraImports;
- (NSSet *)importedLibraries;
- (NSString *)avrBasePath;
- (NSString *)hardwarePath;
- (NSString *)currentMessage;
- (NSString *)objectNameForSource:(NSString *)source buildPath:(NSString *)buildPath;

- (id)initWithPath:(NSString *)path
  boardPreferences:(P5Preferences *)boardPreferences;

- (BOOL)compile:(BOOL)verbose withProgressHandler:(void (^)(double progress))progressHandler completeHandler:(void (^)(void))completeHandler;

- (NSSet *)fileInPath:(NSString *)path
          withExtention:(NSString *)extention
              recursive:(BOOL)recursive;



@end
