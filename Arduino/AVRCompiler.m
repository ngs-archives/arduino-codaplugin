//
//  AVRCompiler.m
//  Arduino
//
//  Created by Atsushi Nagase on 5/30/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "AVRCompiler.h"
#import "P5Preferences.h"
#import "ArduinoPlugin.h"

NSString *const AVRCompileException = @"org.ngsdev.codaplugin.arduino.AVRCompileException";

@implementation AVRCompiler

@synthesize path = _path
, boardPreferences = _boardPreferences
, source = _source
;

#pragma mark - Accessors

- (NSString *)gccPath {
  return nil;
}

- (NSSet *)extraImports {
  NSError *error = nil;
  NSRegularExpression *re = [[NSRegularExpression alloc] initWithPattern:@"\\s*#include\\s+[<\"](\\S+)[\">]" options:0 error:&error];
  NSArray *m = [re matchesInString:self.source options:0 range:NSMakeRange(0, self.source.length)];
  __block NSMutableSet *buf = [NSMutableSet set];
  [m
   enumerateObjectsWithOptions:NSEnumerationConcurrent
   usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
     NSTextCheckingResult *m = obj;
     NSString *str = [self.source substringWithRange:m.range];
     str = [re stringByReplacingMatchesInString:str options:0 range:NSMakeRange(0, str.length) withTemplate:@"$1"];
     [buf addObject:str];
   }];
  return [buf copy];;
}

- (void)setPath:(NSString *)path {
  _path = path;
  NSError *error = nil;
  _source = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
  if(error) NSLog(@"%@", error);
}

- (NSString *)path {
  return _path;
}

- (void)setBoardPreferences:(P5Preferences *)boardPreferences {
  _boardPreferences = boardPreferences;
}

- (P5Preferences *)boardPreferences {
  if(nil==_boardPreferences)
    _boardPreferences = [P5Preferences selectedBoardPreferences];
  return _boardPreferences;
}

- (NSString *)arduinoPath {
  return [[[NSUserDefaults standardUserDefaults] valueForKey:ArduinoPluginArduinoLocationKey] stringByAppendingString:@"/hardware/arduino"];
}

- (NSString *)librariesPath {
  return [[[NSUserDefaults standardUserDefaults] valueForKey:ArduinoPluginArduinoLocationKey] stringByAppendingString:@"/libraries"];
}

- (NSString *)pathForPreferenceKey:(NSString *)key inFolder:(NSString *)folder {
  NSString *conf = [self.boardPreferences get:key];
  if(!conf) return nil;
  NSRange range = [conf rangeOfString:@":"];
  if(range.location != NSNotFound)
    conf = [conf substringWithRange:NSMakeRange(0, range.location)];
  return [[self arduinoPath] stringByAppendingFormat:@"/%@/%@",folder,conf];
}

- (NSString *)corePath {
  NSString *path = [self pathForPreferenceKey:@"build.core" inFolder:@"cores"];
  if(!path)
    [NSException raise:AVRCompileException format:@"No board selected"];
  return path;
}

- (NSString *)variantPath {
  return [self pathForPreferenceKey:@"build.variant" inFolder:@"variants"];
}

- (NSSet *)includePaths {
  NSMutableSet *paths = [NSMutableSet set];
  [paths addObject:self.corePath];
  if(self.variantPath)
    [paths addObject:self.variantPath];
  for (NSString *h in self.extraImports) {
    [paths addObject:[self.librariesPath stringByAppendingFormat:@"/@", [h stringByReplacingOccurrencesOfString:@".h" withString:@""]]];
  }
  return [paths copy];
}

#pragma mark -

- (id)initWithPath:(NSString *)path
  boardPreferences:(P5Preferences *)boardPreferences {
  if(self=[super init]) {
    self.path = path;
    self.boardPreferences = boardPreferences;
  }
  return self;
}

- (BOOL)compile:(BOOL)verbose {
  
  
  return YES;
}

- (NSArray *)commandCompilerS:(BOOL)verbose {
  return nil;
}

- (NSArray *)commandCompilerC:(BOOL)verbose {
  return nil;
}

+ (NSArray *)commandCompilerCPP:(BOOL)verbose {
  return nil;
}

- (void)createFolder:(NSString *)path{
  
}

- (NSSet *)fileInPath:(NSString *)path
          withExtention:(NSString *)extention
              recursive:(BOOL)recursive {
  NSMutableSet *set = [NSMutableSet set];
  NSFileManager *manager = [NSFileManager defaultManager];
  NSError *error = nil;
  NSArray *contents = [manager contentsOfDirectoryAtPath:path error:&error];
  if(error)
    [NSException raise:error.domain format:error.localizedDescription];
  for (NSString *filename in contents) {
    NSString *fullpath = [NSString stringWithFormat:@"%@/%@", path, filename];
    BOOL isDir = NO;
    [manager fileExistsAtPath:fullpath isDirectory:&isDir];
    NSArray *comps = [filename componentsSeparatedByString:@"."];
    if(!isDir &&
       (!extention ||
        (comps.count >= 2 &&
         [[comps objectAtIndex:0] length] > 0 &&
         [[[comps lastObject] uppercaseString] isEqualToString:[extention uppercaseString]])))
      [set addObject:fullpath];
    else if(isDir && recursive)
      [set unionSet:[self fileInPath:fullpath withExtention:extention recursive:YES]];
  }
  return [set copy];
}


@end
