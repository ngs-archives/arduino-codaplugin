//
//  AVRTool.m
//  Arduino
//
//  Created by Atsushi Nagase on 6/23/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "AVRTool.h"
#import "P5Preferences.h"
#import "ArduinoPlugin.h"

NSString *const AVRCompileException = @"org.ngsdev.codaplugin.arduino.AVRCompileException";

@implementation AVRTool
@synthesize boardPreferences = _boardPreferences
, buildQueue = _buildQueue
, path = _path
, messages = _messages
, completeHandler = _completeHandler
, errorHandler = _errorHandler
;

#pragma mark -

- (id)initWithPath:(NSString *)path
  boardPreferences:(P5Preferences *)boardPreferences {
  if(self=[super init]) {
    self.path = path;
    self.boardPreferences = boardPreferences;
  }
  return self;
}

#pragma mark - Accessors

- (NSString *)gccPath {
  return [self.avrBasePath stringByAppendingString:@"/avr-gcc"];
}

- (NSString *)gccppPath {
  return [self.avrBasePath stringByAppendingString:@"/avr-g++"];
}

- (NSString *)avrarPath {
  return [self.avrBasePath stringByAppendingString:@"/avr-ar"];
}

- (NSString *)avrobjcopyPath {
  return [self.avrBasePath stringByAppendingString:@"/avr-objcopy"];
}

- (NSString *)avrdudePath {
  return [self.avrBasePath stringByAppendingString:@"/avrdude"];
}

- (NSString *)avrdudeConfPath {
  return [self.hardwarePath stringByAppendingString:@"/tools/avr/etc/avrdude.conf"];
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


- (NSSet *)fileInPath:(NSString *)path
        withExtention:(NSString *)extention
            recursive:(BOOL)recursive {
  NSMutableSet *set = [NSMutableSet set];
  NSFileManager *manager = [NSFileManager defaultManager];
  if(![manager fileExistsAtPath:path]) return [set copy];
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

- (BOOL)launchTask:(NSTask *)task verbose:(BOOL)verbose {
  NSPipe *outpipe = [NSPipe pipe];
  NSPipe *errorpipe = [NSPipe pipe];
  [task setStandardOutput:outpipe];
  [task setStandardError:errorpipe];
  [task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
  if(verbose)
    [self.messages addObject:
     [NSString stringWithFormat:@"%@ %@", task.launchPath, [task.arguments componentsJoinedByString:@" "]]];
  [task launch];
  [task waitUntilExit];
  NSString* message =
  [[NSString alloc] initWithData:
   [[outpipe fileHandleForReading] readDataToEndOfFile]
                        encoding:NSUTF8StringEncoding];
  NSString* errorMessage =
  [[NSString alloc] initWithData:
   [[errorpipe fileHandleForReading] readDataToEndOfFile]
                        encoding:NSUTF8StringEncoding];
  if(message&&message.length>0)
    [self.messages addObject:message];
  int st = task.terminationStatus;
  if(st == 1 && errorMessage && errorMessage.length>0) {
    NSError *error = [NSError
                      errorWithDomain:AVRCompileException
                      code:1
                      userInfo:[NSDictionary dictionaryWithObject:errorMessage
                                                           forKey:@"message"]];
    [self.messages addObject:errorMessage];
    if(self.errorHandler)
      dispatch_async(dispatch_get_main_queue(), ^{
        self.errorHandler(error);
      });
    return NO;
  }
  return YES;
}


@end
