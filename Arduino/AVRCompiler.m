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
#define REVISION @"101"

NSString *const AVRCompileException = @"org.ngsdev.codaplugin.arduino.AVRCompileException";

@implementation AVRCompiler

@synthesize path = _path
, buildPath = _buildPath
, boardPreferences = _boardPreferences
, source = _source
, messages = _messages
, buildQueue = _buildQueue
;

#pragma mark - Accessors

- (NSString *)gccPath {
  return [self.avrBasePath stringByAppendingString:@"/avr-gcc"];
}

- (NSString *)gccppPath {
  return [self.avrBasePath stringByAppendingString:@"/avr-g++"];
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
  NSURL *URL = [NSURL fileURLWithPath:path];
  NSMutableArray *comps = [[URL pathComponents] mutableCopy];
  [comps replaceObjectAtIndex:comps.count-1 withObject:@"build"];
  self.buildPath = [[NSURL fileURLWithPathComponents:comps] path];
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
  return [self.hardwarePath stringByAppendingString:@"/arduino"];
}

- (NSString *)librariesPath {
  return [[[NSUserDefaults standardUserDefaults] valueForKey:ArduinoPluginArduinoLocationKey] stringByAppendingString:@"/libraries"];
}

- (NSString *)avrBasePath {
  return [self.hardwarePath stringByAppendingString:@"/tools/avr/bin"];
}

- (NSString *)hardwarePath {
  return [[[NSUserDefaults standardUserDefaults] valueForKey:ArduinoPluginArduinoLocationKey] stringByAppendingString:@"/hardware"];
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

- (NSString *)currentMessage {
  return [self.messages lastObject];
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
  if(self.buildQueue)
  dispatch_suspend(self.buildQueue);
  self.buildQueue = dispatch_queue_create("org.ngsdev.avrcompiler.build-queue", NULL);
  dispatch_async(self.buildQueue, ^{
    self.messages = [NSMutableArray array];
    NSString *path = nil;
    for (path in self.includePaths) {
      [self compileFiles:path buildPath:self.buildPath verbose:verbose];
    }
  });
  return YES;
}

- (NSTask *)commandCompilerS:(NSString *)source object:(NSString *)object verbose:(BOOL)verbose {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:self.gccPath];
  NSMutableArray *args = 
  [NSMutableArray arrayWithObjects:
   @"-c", // compile, don't link
   @"-g", // include debugging info (so errors include line numbers)
   @"-assembler-with-cpp",
   [@"-mmcu=" stringByAppendingString:[self.boardPreferences getString:@"build.mcu"]],
   [@"-DF_CPU=" stringByAppendingString:[self.boardPreferences getString:@"build.f_cpu"]],
   @"-MMD", // output dependancy info
   [@"-DUSB_VID=" stringByAppendingString:[self.boardPreferences getString:@"build.vid"]],
   [@"-DUSB_PID=" stringByAppendingString:[self.boardPreferences getString:@"build.pid"]],
   [@"-DARDUINO=" stringByAppendingString:REVISION],
   nil];
  for (NSString *p in self.includePaths) {
    [args addObject:[NSString stringWithFormat:@"-I%@", p]];
  }
  [args addObject:source];
  [args addObject:[NSString stringWithFormat:@"-o%@", object]];
  [task setArguments:args];
  return task;
}

- (NSTask *)commandCompilerC:(NSString *)source object:(NSString *)object verbose:(BOOL)verbose {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:self.gccPath];
  NSMutableArray *args = 
  [NSMutableArray arrayWithObjects:
   @"-c", // compile, don't link
   @"-g", // include debugging info (so errors include line numbers)
   @"-Os", // optimize for size
   verbose ? @"-Wall" : @"-w", // show warnings if verbose
   @"-ffunction-sections", // place each function in its own section
   @"-fdata-sections",
   [@"-mmcu=" stringByAppendingString:[self.boardPreferences getString:@"build.mcu"]],
   [@"-DF_CPU=" stringByAppendingString:[self.boardPreferences getString:@"build.f_cpu"]],
   @"-MMD", // output dependancy info
   [@"-DUSB_VID=" stringByAppendingString:[self.boardPreferences getString:@"build.vid"]],
   [@"-DUSB_PID=" stringByAppendingString:[self.boardPreferences getString:@"build.pid"]],
   [@"-DARDUINO=" stringByAppendingString:REVISION],
   nil];
  for (NSString *p in self.includePaths) {
    [args addObject:[NSString stringWithFormat:@"-I%@", p]];
  }
  [args addObject:source];
  [args addObject:@"-o"];
  [args addObject:object];
  [task setArguments:args];
  return task;
}

- (NSTask *)commandCompilerCPP:(NSString *)source object:(NSString *)object verbose:(BOOL)verbose {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:self.gccppPath];
  NSMutableArray *args = 
  [NSMutableArray arrayWithObjects:
   @"-c", // compile, don't link
   @"-g", // include debugging info (so errors include line numbers)
   @"-Os", // optimize for size
   verbose ? @"-Wall" : @"-w", // show warnings if verbose
   @"-fno-exceptions",
   @"-ffunction-sections", // place each function in its own section
   @"-fdata-sections",
   [@"-mmcu=" stringByAppendingString:[self.boardPreferences getString:@"build.mcu"]],
   [@"-DF_CPU=" stringByAppendingString:[self.boardPreferences getString:@"build.f_cpu"]],
   @"-MMD", // output dependancy info
   [@"-DUSB_VID=" stringByAppendingString:[self.boardPreferences getString:@"build.vid"]],
   [@"-DUSB_PID=" stringByAppendingString:[self.boardPreferences getString:@"build.pid"]],
   [@"-DARDUINO=" stringByAppendingString:REVISION],
   nil];
  for (NSString *p in self.includePaths) {
    [args addObject:[NSString stringWithFormat:@"-I%@", p]];
  }
  [args addObject:source];
  [args addObject:@"-o"];
  [args addObject:object];
  [task setArguments:args];
  return task;
}

- (NSArray *)compileFiles:(NSString *)sourcePath buildPath:(NSString *)buildPath verbose:(BOOL)verbose {
  NSMutableArray *objects = [NSMutableArray array];
  NSSet *sources = nil;
  NSPipe *outpipe = nil;
  NSTask *task = nil;
  NSString *message = nil;
  NSString *f = nil;
  NSString *o = nil;
  sources = [self fileInPath:sourcePath withExtention:@"S" recursive:NO];
  for (f in sources) {
    o = [self objectNameForSource:f];
    task = [self commandCompilerS:f object:o verbose:verbose];
    outpipe = [NSPipe pipe];
    [task setStandardOutput:outpipe];
    [task launch];
    [task waitUntilExit];
    message =
    [[NSString alloc] initWithData:
     [[outpipe fileHandleForReading] readDataToEndOfFile]
                          encoding:NSUTF8StringEncoding];
    if(message)
      [self.messages addObject:message];
    [objects addObject:o];
  }
  sources = [self fileInPath:sourcePath withExtention:@"c" recursive:NO];
  for (f in sources) {
    o = [self objectNameForSource:f];
    task = [self commandCompilerC:f object:o verbose:verbose];
    outpipe = [NSPipe pipe];
    [task setStandardOutput:outpipe];
    [task launch];
    [task waitUntilExit];
    message =
    [[NSString alloc] initWithData:
     [[outpipe fileHandleForReading] readDataToEndOfFile]
                          encoding:NSUTF8StringEncoding];
    if(message)
      [self.messages addObject:message];
    [objects addObject:o];
  }
  sources = [self fileInPath:sourcePath withExtention:@"cpp" recursive:NO];
  for (f in sources) {
    o = [self objectNameForSource:f];
    task = [self commandCompilerCPP:f object:o verbose:verbose];
    outpipe = [NSPipe pipe];
    [task setStandardOutput:outpipe];
    [task launch];
    [task waitUntilExit];
    message =
    [[NSString alloc] initWithData:
     [[outpipe fileHandleForReading] readDataToEndOfFile]
                          encoding:NSUTF8StringEncoding];
    if(message)
      [self.messages addObject:message];
    [objects addObject:o];
  }
  return [objects copy];
}

- (NSString *)objectNameForSource:(NSString *)source {
  NSString *filename = [source lastPathComponent];
  NSMutableArray *parts = [[filename componentsSeparatedByString:@"."] mutableCopy];
  [parts replaceObjectAtIndex:parts.count-1 withObject:@"o"];
  return [self.buildPath stringByAppendingFormat:@"/%@", [parts componentsJoinedByString:@"."]];
}

- (void)createFolder:(NSString *)path{
  NSFileManager *manager = [NSFileManager defaultManager];
  
  
  
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
