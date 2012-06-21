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

- (NSString *)corePath;
- (NSString *)arduinoPath;
- (NSString *)variantPath;
- (NSString *)gccPath;
- (NSString *)gccppPath;
- (NSString *)librariesPath;
- (NSSet *)extraImports;
- (NSSet *)includePaths;
- (NSString *)avrBasePath;
- (NSString *)hardwarePath;
- (NSString *)currentMessage;
- (NSString *)objectNameForSource:(NSString *)source;

- (id)initWithPath:(NSString *)path
  boardPreferences:(P5Preferences *)boardPreferences;

- (BOOL)compile:(BOOL)verbose;

- (NSTask *)commandCompilerS:(NSString *)source object:(NSString *)object verbose:(BOOL)verbose;

- (NSTask *)commandCompilerC:(NSString *)source object:(NSString *)object verbose:(BOOL)verbose;

- (NSTask *)commandCompilerCPP:(NSString *)source object:(NSString *)object verbose:(BOOL)verbose;

- (void)createFolder:(NSString *)path;

- (NSSet *)fileInPath:(NSString *)path
          withExtention:(NSString *)extention
              recursive:(BOOL)recursive;



@end
