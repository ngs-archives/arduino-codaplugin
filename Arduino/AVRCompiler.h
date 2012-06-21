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
@property (readonly) NSString *source;
@property (strong) P5Preferences *boardPreferences;

- (NSString *)corePath;
- (NSString *)arduinoPath;
- (NSString *)variantPath;
- (NSString *)gccPath;
- (NSArray *)extraImports;
- (NSSet *)includePaths;

- (id)initWithPath:(NSString *)path
  boardPreferences:(P5Preferences *)boardPreferences;

- (BOOL)compile:(BOOL)verbose;

- (NSArray *)commandCompilerS:(BOOL)verbose;

- (NSArray *)commandCompilerC:(BOOL)verbose;

+ (NSArray *)commandCompilerCPP:(BOOL)verbose;

- (void)createFolder:(NSString *)path;

- (NSSet *)fileInPath:(NSString *)path
          withExtention:(NSString *)extention
              recursive:(BOOL)recursive;



@end
