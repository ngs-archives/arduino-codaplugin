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
#import "NSString+extension.h"

#define REVISION @"101"
#define CPP_PREFIX @"#include \"Arduino.h\"\nvoid setup();\nvoid loop();"

NSString *const AVRCompileException = @"org.ngsdev.codaplugin.arduino.AVRCompileException";

@implementation AVRCompiler

@synthesize path = _path
, buildPath = _buildPath
, boardPreferences = _boardPreferences
, source = _source
, messages = _messages
, buildQueue = _buildQueue
, progressHandler = _progressHandler
, completeHandler = _completeHandler
, currentProgress = _currentProgress
;

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

- (NSString *)runtimeLibraryName {
  return [self.buildPath stringByAppendingString:@"/core.a"];
}

- (NSString *)elfPath {
  return [self.path replacePathExtension:@"cpp.elf" inDirectory:self.buildPath];
}

- (NSString *)hexPath {
  return [self.path replacePathExtension:@"cpp.hex" inDirectory:self.buildPath];
}

- (NSString *)eepPath {
  return [self.path replacePathExtension:@"cpp.eep" inDirectory:self.buildPath];
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

- (NSSet *)importedLibraries {
  NSMutableSet *paths = [NSMutableSet set];
  for (NSString *h in self.extraImports) {
    [paths addObject:[self.librariesPath stringByAppendingFormat:@"/%@", [h stringByReplacingOccurrencesOfString:@".h" withString:@""]]];
  }
  return [paths copy];
}

- (NSString *)currentMessage {
  return [self.messages lastObject];
}

- (void)setCurrentProgress:(double)currentProgress {
  _currentProgress = currentProgress;
  if(self.progressHandler)
    dispatch_async(dispatch_get_main_queue(), ^{
      self.progressHandler(currentProgress);
    });
}

- (double)currentProgress {
  return _currentProgress;
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

- (BOOL)compile:(BOOL)verbose withProgressHandler:(void (^)(double progress))progressHandler completeHandler:(void (^)(void))completeHandler {
  self.completeHandler = completeHandler;
  self.progressHandler = progressHandler;
  if(self.buildQueue)
    dispatch_suspend(self.buildQueue);
  self.buildQueue = dispatch_queue_create("org.ngsdev.avrcompiler.build-queue", NULL);
  dispatch_async(self.buildQueue, ^{
    NSMutableSet *objects = [NSMutableSet set];
    NSMutableSet *includePaths = nil;
    NSString *path = nil;
    NSString *lib = nil;
    self.messages = [NSMutableArray array];
    includePaths = [NSMutableSet setWithObject:self.corePath];
    if(self.variantPath)
      [includePaths addObject:self.variantPath];
    [self createFolder:self.buildPath];
    for (lib in self.importedLibraries) {
      [includePaths addObject:lib];
    }
    //
    // 1. compile the sketch
    [self writeProgram];
    self.currentProgress += 0.1;
    [objects unionSet:
     [self compileFiles:self.buildPath
              buildPath:self.buildPath
           includePaths:includePaths
                verbose:verbose]];
    //
    // 2. compile the libraries, outputting .o files to: <buildPath>/<library>/
    for (lib in self.importedLibraries) {
      NSString *utilityFolder = [lib stringByAppendingString:@"/utility"];
      path = [self.buildPath stringByAppendingFormat:@"/%@", [lib lastPathComponent]];
      [self createFolder:path];
      [includePaths addObject:utilityFolder];
      [objects unionSet:
       [self compileFiles:lib
                buildPath:path
             includePaths:includePaths
                  verbose:verbose]];
      path = [self.buildPath
              stringByAppendingFormat:@"/%@/utility",
              [lib lastPathComponent]];
      [self createFolder:path];
      [objects unionSet:
       [self compileFiles:utilityFolder
                buildPath:path
             includePaths:includePaths
                  verbose:verbose]];
      [includePaths removeObject:utilityFolder];
    }
    //
    // 3. compile the core, outputting .o files to <buildPath> and then
    // collecting them into the core.a library file.
    [self compileRuntimeLibrary:verbose];
    //
    // 4. link it all together into the .elf file
    [self linkObjects:objects verbose:verbose];
    self.currentProgress += 0.1;
    //
    // 5. extract EEPROM data (from EEMEM directive) to .eep file.
    [self extractEEPROM:verbose];
    self.currentProgress += 0.1;
    //
    // 6. build the .hex file
    [self buildHex:verbose];
    self.currentProgress += 0.1;
    //
    dispatch_async(dispatch_get_main_queue(), ^{
      if(completeHandler)
        completeHandler();
    });
  });
  return YES;
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

#pragma mark - Private

- (void)compileRuntimeLibrary:(BOOL)verbose {
  NSMutableSet *includePaths = [NSMutableSet setWithObject:self.corePath];
  if(self.variantPath)
    [includePaths addObject:self.variantPath];
  NSSet *objects = [self compileFiles:self.corePath
                            buildPath:self.buildPath
                         includePaths:includePaths
                              verbose:verbose];
  for (NSString *obj in objects) {
    NSTask *task = [[NSTask alloc] init];
    NSArray *args = [NSArray arrayWithObjects:@"rcs", self.runtimeLibraryName, obj, nil];
    [task setLaunchPath:self.avrarPath];
    [task setArguments:args];
    [self launchTask:task verbose:verbose];
    self.currentProgress += 1/objects.count/10;
  }
}

- (void)linkObjects:(NSSet *)objects verbose:(BOOL)verbose {
  [self launchTask:[self commandLinkerWithObjectFiles:objects] verbose:verbose];
}

- (void)extractEEPROM:(BOOL)verbose {
  [self launchTask:[self commandExtractEEPROM] verbose:verbose];
}

- (void)buildHex:(BOOL)verbose {
  [self launchTask:[self commandBuildHex] verbose:verbose];
}

- (NSSet *)compileFiles:(NSString *)sourcePath
              buildPath:(NSString *)buildPath
           includePaths:(NSSet *)includePaths
                verbose:(BOOL)verbose {
  NSMutableSet *objects = [NSMutableSet set];
  NSSet *sSources = [self fileInPath:sourcePath withExtention:@"S" recursive:NO];
  NSSet *cSources = [self fileInPath:sourcePath withExtention:@"c" recursive:NO];
  NSSet *cppSources = [self fileInPath:sourcePath withExtention:@"cpp" recursive:NO];
  NSString *f = nil;
  NSString *o = nil;
  double t = sSources.count + cSources.count + cppSources.count;
  for (f in sSources) {
    o = [self objectNameForSource:f buildPath:buildPath];
    [self launchTask:
     [self commandCompilerS:f
                     object:o
               includePaths:includePaths
                    verbose:verbose]
             verbose:verbose];
    [objects addObject:o];
    self.currentProgress += 1 / t / 10.0;
  }
  for (f in cSources) {
    o = [self objectNameForSource:f buildPath:buildPath];
    [self launchTask:
     [self commandCompilerC:f
                     object:o
               includePaths:includePaths
                    verbose:verbose]
             verbose:verbose];
    [objects addObject:o];
    self.currentProgress += 1 / t / 10.0;
  }
  for (f in cppSources) {
    o = [self objectNameForSource:f buildPath:buildPath];
    [self launchTask:
     [self commandCompilerCPP:f
                       object:o
                 includePaths:includePaths
                      verbose:verbose]
             verbose:verbose];
    [objects addObject:o];
    self.currentProgress += 1 / t / 10.0;
  }
  return [objects copy];
}

- (void)writeProgram {
  NSString *content = [NSString stringWithFormat:@"%@\n\n%@", CPP_PREFIX, self.source];
  NSString *output = [self.path replacePathExtension:@"cpp" inDirectory:self.buildPath];
  NSFileManager *manager = [NSFileManager defaultManager];
  if([manager fileExistsAtPath:output])
    [manager removeItemAtPath:output error:nil];
  [manager createFileAtPath:output contents:[content dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
}

- (NSString *)objectNameForSource:(NSString *)source buildPath:(NSString *)buildPath {
  return [source replacePathExtension:[source.pathExtension stringByAppendingString:@".o"] inDirectory:buildPath];
}

- (void)createFolder:(NSString *)path{
  NSFileManager *manager = [NSFileManager defaultManager];
  [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
}

#pragma mark - NSTasks

- (NSTask *)commandCompilerS:(NSString *)source
                      object:(NSString *)object
                includePaths:(NSSet *)includePaths
                     verbose:(BOOL)verbose {
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
  for (NSString *p in includePaths) {
    [args addObject:[NSString stringWithFormat:@"-I%@", p]];
  }
  [args addObject:source];
  [args addObject:[NSString stringWithFormat:@"-o%@", object]];
  [task setArguments:args];
  return task;
}

// avr-gcc -c -g -Os -Wall -ffunction-sections -fdata-sections
//   -mmcu=atmega328p -DF_CPU=16000000L -MMD -DUSB_VID=null -DUSB_PID=null
//   -DARDUINO=101
//   -I/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino
//   -I/Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/variants/standard
//   /Applications/Arduino.app/Contents/Resources/Java/hardware/arduino/cores/arduino/WInterrupts.c
//   -o /var/folders/dh/v8b0d1kj7k1crx8mx5d65bl40000gn/T/build805200626271849655.tmp/WInterrupts.c.o

- (NSTask *)commandCompilerC:(NSString *)source
                      object:(NSString *)object
                includePaths:(NSSet *)includePaths
                     verbose:(BOOL)verbose {
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
  for (NSString *p in includePaths) {
    [args addObject:[NSString stringWithFormat:@"-I%@", p]];
  }
  [args addObject:source];
  [args addObject:@"-o"];
  [args addObject:object];
  [task setArguments:args];
  return task;
}

- (NSTask *)commandCompilerCPP:(NSString *)source
                        object:(NSString *)object
                  includePaths:(NSSet *)includePaths
                       verbose:(BOOL)verbose {
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
  for (NSString *p in includePaths) {
    [args addObject:[NSString stringWithFormat:@"-I%@", p]];
  }
  [args addObject:source];
  [args addObject:@"-o"];
  [args addObject:object];
  [task setArguments:args];
  return task;
}

// avr-gcc -Os -Wl,--gc-sections -mmcu=atmega328p -o #{name}.cpp.elf #{name}.cpp.o /var/folders/dh/v8b0d1kj7k1crx8mx5d65bl40000gn/T/build805200626271849655.tmp/core.a -L/var/folders/dh/v8b0d1kj7k1crx8mx5d65bl40000gn/T/build805200626271849655.tmp -lm

- (NSTask *)commandLinkerWithObjectFiles:(NSSet *)objects {
  NSString *optRelax = @"";
  NSString *mcu = [self.boardPreferences getString:@"build.mcu"];
  // For atmega2560, need --relax linker option to link larger
  // programs correctly.
  if([mcu isEqualToString:@"atmega2560"])
    optRelax = @",--relax";
  NSTask *task = [[NSTask alloc] init];
  NSMutableArray *args = 
  [NSMutableArray arrayWithObjects:
   @"-Os",
   [NSString stringWithFormat:@"-Wl,--gc-sections%@", optRelax],
   [NSString stringWithFormat:@"-mmcu=%@", mcu],
   @"-o",
   self.elfPath,
   nil];
  for (NSString *o in objects) {
    [args addObject:o];
  }
  [args addObject:self.runtimeLibraryName];
  [args addObject:[NSString stringWithFormat:@"-L%@", self.buildPath]]; 
  [args addObject:@"-lm"];
  [task setLaunchPath:self.gccPath];
  [task setArguments:args];
  return task;
}

// avr-objcopy -O ihex -j .eeprom --set-section-flags=.eeprom=alloc,load --no-change-warnings --change-section-lma .eeprom=0 #{name}.cpp.elf #{name}.cpp.eep 

- (NSTask *)commandExtractEEPROM {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:self.avrobjcopyPath];
  [task setArguments:
   [NSArray arrayWithObjects:
    @"-O",
    @"ihex",
    @"-j",
    @".eeprom",
    @"--set-section-flags=.eeprom=alloc,load",
    @"--no-change-warnings",
    @"--change-section-lma",
    @".eeprom=0",
    self.elfPath,
    self.eepPath,
    nil]];
  return task;
}

// avr-objcopy -O ihex -R .eeprom #{name}.cpp.elf #{name}.cpp.hex 

- (NSTask *)commandBuildHex {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:self.avrobjcopyPath];
  [task setArguments:
   [NSArray arrayWithObjects:
    @"-O",
    @"ihex",
    @"-R",
    @".eeprom",
    self.elfPath,
    self.hexPath,
    nil]];
  return task;
}

- (void)launchTask:(NSTask *)task verbose:(BOOL)verbose {
  NSPipe *outpipe = [NSPipe pipe];
  [task setStandardOutput:outpipe];
  if(verbose)
    [self.messages addObject:
     [NSString stringWithFormat:@"%@ %@", task.launchPath, [task.arguments componentsJoinedByString:@" "]]];
  [task launch];
  [task waitUntilExit];
  NSString* message =
  [[NSString alloc] initWithData:
   [[outpipe fileHandleForReading] readDataToEndOfFile]
                        encoding:NSUTF8StringEncoding];
  if(message&&message.length>0)
    [self.messages addObject:message];
  
}


@end
