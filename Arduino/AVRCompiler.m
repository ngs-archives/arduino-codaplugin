//
//  AVRCompiler.m
//  Arduino
//
//  Created by Atsushi Nagase on 5/30/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "AVRCompiler.h"

@implementation AVRCompiler

@synthesize path = _path
, boardPreferences = _boardPreferences
, source = _source
;

#pragma mark - Accessors

- (NSString *)gccPath {
  return nil;
}

- (NSArray *)extraImports {
  NSError *error = nil;
  NSRegularExpression *re = [[NSRegularExpression alloc] initWithPattern:@"\\s*#include\\s+[<\"](\\S+)[\">]" options:0 error:&error];
  NSArray *m = [re matchesInString:self.source options:0 range:NSMakeRange(0, self.source.length)];
  __block NSMutableArray *buf = [NSMutableArray array];
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



#pragma mark -

- (id)initWithPath:(NSString *)path
  boardPreferences:(NSDictionary *)boardPreferences {
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

- (NSArray *)fileInFolder:(NSString *)path
            withExtention:(NSString *)extention
                recursive:(BOOL)recursive {
  return nil;
}


@end
