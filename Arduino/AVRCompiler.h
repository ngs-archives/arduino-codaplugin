//
//  AVRCompiler.h
//  Arduino
//
//  Created by Atsushi Nagase on 5/30/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVRCompiler : NSObject

@property (strong) NSString *path;
@property (readonly) NSString *source;
@property (strong) NSDictionary *boardPreferences;

- (NSString *)gccPath;
- (NSArray *)extraImports;

- (id)initWithPath:(NSString *)path
  boardPreferences:(NSDictionary *)boardPreferences;

- (BOOL)compile:(BOOL)verbose;

- (NSArray *)commandCompilerS:(BOOL)verbose;

- (NSArray *)commandCompilerC:(BOOL)verbose;

+ (NSArray *)commandCompilerCPP:(BOOL)verbose;

- (void)createFolder:(NSString *)path;

- (NSArray *)fileInFolder:(NSString *)path
            withExtention:(NSString *)extention
                recursive:(BOOL)recursive;



@end
