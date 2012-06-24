//
//  AVRDudeUploader.m
//  Arduino
//
//  Created by Atsushi Nagase on 6/23/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "AVRDudeUploader.h"
#import "P5Preferences.h"

/*
 Options:
 -p <partno>                Required. Specify AVR device.
 -b <baudrate>              Override RS-232 baud rate.
 -B <bitclock>              Specify JTAG/STK500v2 bit clock period (us).
 -C <config-file>           Specify location of configuration file.
 -c <programmer>            Specify programmer type.
 -D                         Disable auto erase for flash memory
 -i <delay>                 ISP Clock Delay [in microseconds]
 -P <port>                  Specify connection port.
 -F                         Override invalid signature check.
 -e                         Perform a chip erase.
 -O                         Perform RC oscillator calibration (see AVR053). 
 -U <memtype>:r|w|v:<filename>[:format]
 Memory operation specification.
 Multiple -U options are allowed, each request
 is performed in the order specified.
 -n                         Do not write anything to the device.
 -V                         Do not verify.
 -u                         Disable safemode, default when running from a scrip
 t.
 -s                         Silent safemode operation, will not ask you if
 fuses should be changed back.
 -t                         Enter terminal mode.
 -E <exitspec>[,<exitspec>] List programmer exit specifications.
 -x <extended_param>        Pass <extended_param> to programmer.
 -y                         Count # erase cycles in EEPROM.
 -Y <number>                Initialize erase cycle # in EEPROM.
 -v                         Verbose output. -v -v for more.
 -q                         Quell progress output. -q -q for less.
 -?                         Display this usage.
 
 avrdude version 5.11, URL: <http://savannah.nongnu.org/projects/avrdude/>
*/

@implementation AVRDudeUploader
@synthesize path = _path
, className = _className
;

- (id)initWithPath:(NSString *)path className:(NSString *)className {
  if(self=[super init]) {
    self.path = path;
    self.className = className;
  }
  return self;
}

- (BOOL)uploadUsingPreferences:(BOOL)usingProgrammer {
  return YES;
}

- (BOOL)uploadViaBootloader {
  return YES;
}

- (BOOL)burnBootloader {
  return YES;
}

#pragma mark - NSTasks

- (NSTask *)avrdude:(NSArray *)params verbose:(BOOL)verbose {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:self.avrdudePath];
  NSMutableArray *args = [NSMutableArray array];
  [args addObject:[NSString stringWithFormat:@"-C%@", self.avrdudeConfPath]];
  if(verbose) {
    [args addObject:@"-v"];
    [args addObject:@"-v"];
    [args addObject:@"-v"];
    [args addObject:@"-v"];
  } else {
    [args addObject:@"-q"];
    [args addObject:@"-q"];
  }
  [args addObject:[NSString stringWithFormat:@"-p%@", [self.boardPreferences getString:@"build.mcu"]]];
  if([params isKindOfClass:[NSArray class]] && params.count > 0)
    [args addObjectsFromArray:params];
  [task setArguments:args];
  return task;
}



@end
