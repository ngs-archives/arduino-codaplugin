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


@implementation AVRCompiler

@synthesize buildPath = _buildPath
, source = _source
, progressHandler = _progressHandler
, currentProgress = _currentProgress
;

#pragma mark - Accessors

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
  [super setPath:path];
  NSError *error = nil;
  _source = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
  if(error) NSLog(@"%@", error);
  NSString *filename = [[[path lastPathComponent] componentsSeparatedByString:@"."] objectAtIndex:0];
  NSString*tmp = NSTemporaryDirectory();
  do {
    self.buildPath = [NSString stringWithFormat:@"%@org.ngsdev.codaplugin.arduino.build-%@%d", tmp, filename, rand()];
  } while([[NSFileManager defaultManager] fileExistsAtPath:self.buildPath]);
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

- (BOOL)compile:(BOOL)verbose
withProgressHandler:(void (^)(double progress))progressHandler
completeHandler:(void (^)(void))completeHandler
   errorHandler:(void (^)(NSError *error))errorHandler {
  self.completeHandler = completeHandler;
  self.progressHandler = progressHandler;
  self.errorHandler = errorHandler;
  if(self.buildQueue)
    dispatch_suspend(self.buildQueue);
  self.buildQueue = dispatch_queue_create("org.ngsdev.avrcompiler.build-queue", NULL);
  dispatch_async(self.buildQueue, ^{
    NSMutableSet *objects = [NSMutableSet set];
    NSSet *compiledObjects = nil;
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
    compiledObjects = [self compileFiles:self.buildPath
                               buildPath:self.buildPath
                            includePaths:includePaths
                                 verbose:verbose];
    if(!compiledObjects) return;
    [objects unionSet:compiledObjects];
    //
    // 2. compile the libraries, outputting .o files to: <buildPath>/<library>/
    for (lib in self.importedLibraries) {
      NSString *utilityFolder = [lib stringByAppendingString:@"/utility"];
      path = [self.buildPath stringByAppendingFormat:@"/%@", [lib lastPathComponent]];
      [self createFolder:path];
      [includePaths addObject:utilityFolder];
      compiledObjects = [self compileFiles:lib
                                 buildPath:path
                              includePaths:includePaths
                                   verbose:verbose];
      if(!compiledObjects) return;
      [objects unionSet:compiledObjects];
      path = [self.buildPath
              stringByAppendingFormat:@"/%@/utility",
              [lib lastPathComponent]];
      [self createFolder:path];
      compiledObjects = [self compileFiles:utilityFolder
                                 buildPath:path
                              includePaths:includePaths
                                   verbose:verbose];
      if(!compiledObjects) return;
      [objects unionSet:compiledObjects];
      [includePaths removeObject:utilityFolder];
    }
    //
    // 3. compile the core, outputting .o files to <buildPath> and then
    // collecting them into the core.a library file.
    if(![self compileRuntimeLibrary:verbose]) return;
    //
    // 4. link it all together into the .elf file
    if(![self linkObjects:objects verbose:verbose]) return;
    self.currentProgress += 0.1;
    //
    // 5. extract EEPROM data (from EEMEM directive) to .eep file.
    if(![self extractEEPROM:verbose]) return;
    self.currentProgress += 0.1;
    //
    // 6. build the .hex file
    if(![self buildHex:verbose]) return;
    self.currentProgress += 0.1;
    //
    dispatch_async(dispatch_get_main_queue(), ^{
      if(completeHandler)
        completeHandler();
    });
  });
  return YES;
}

#pragma mark - Private

- (BOOL)compileRuntimeLibrary:(BOOL)verbose {
  NSMutableSet *includePaths = [NSMutableSet setWithObject:self.corePath];
  if(self.variantPath)
    [includePaths addObject:self.variantPath];
  NSSet *objects = [self compileFiles:self.corePath
                            buildPath:self.buildPath
                         includePaths:includePaths
                              verbose:verbose];
  if(!objects) return NO;
  for (NSString *obj in objects) {
    NSTask *task = [[NSTask alloc] init];
    NSArray *args = [NSArray arrayWithObjects:@"rcs", self.runtimeLibraryName, obj, nil];
    [task setLaunchPath:self.avrarPath];
    [task setArguments:args];
    if(![self launchTask:task verbose:verbose]) return NO;
    self.currentProgress += 1/objects.count/10;
  }
  return YES;
}

- (BOOL)linkObjects:(NSSet *)objects verbose:(BOOL)verbose {
  return [self launchTask:[self commandLinkerWithObjectFiles:objects] verbose:verbose];
}

- (BOOL)extractEEPROM:(BOOL)verbose {
  return [self launchTask:[self commandExtractEEPROM] verbose:verbose];
}

- (BOOL)buildHex:(BOOL)verbose {
  return [self launchTask:[self commandBuildHex] verbose:verbose];
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
    if(![self launchTask:
         [self commandCompilerS:f
                         object:o
                   includePaths:includePaths
                        verbose:verbose]
                 verbose:verbose]) return nil;
    [objects addObject:o];
    self.currentProgress += 1 / t / 10.0;
  }
  for (f in cSources) {
    o = [self objectNameForSource:f buildPath:buildPath];
    if(![self launchTask:
         [self commandCompilerC:f
                         object:o
                   includePaths:includePaths
                        verbose:verbose]
                 verbose:verbose]) return nil;
    [objects addObject:o];
    self.currentProgress += 1 / t / 10.0;
  }
  for (f in cppSources) {
    o = [self objectNameForSource:f buildPath:buildPath];
    if(![self launchTask:
         [self commandCompilerCPP:f
                           object:o
                     includePaths:includePaths
                          verbose:verbose]
                 verbose:verbose]) return nil;
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


@end
