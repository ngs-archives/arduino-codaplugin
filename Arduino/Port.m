//
//  Port.m
//  Arduino
//
//  Created by Atsushi Nagase on 5/29/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "Port.h"

@interface Port ()


@end

@implementation Port

@synthesize opened = _opened
, path = _path
, queue = _queue
, fileHandle = _fileHandle
;


- (id)initWithPath:(NSString *)path {
  if(self=[super init]) {
    self.path = path;
  }
  return self;
}

#pragma mark - Accessors

- (dispatch_queue_t)queue {
  if(!_queue)
    _queue = dispatch_queue_create([[NSString stringWithFormat:@"org.ngsdev.codapplugin.Arduino.Port-%d", self.path, self] UTF8String] , NULL);
  return _queue;
}

// http://arduino.cc/playground/Interfacing/Cocoa

- (NSInteger)open {
  _opened = YES;
  int fd = open(self.path.UTF8String, O_RDWR|O_NOCTTY);
  self.fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fd];
  return self.fileHandle.fileDescriptor;
}

- (void)close {
  [self.fileHandle closeFile];
  self.fileHandle = nil;
  _opened = NO;
}

- (void)watch:(BOOL (^)(NSString *status))handler {
  [self open];
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];  
  [notificationCenter
   addObserverForName:NSFileHandleReadCompletionNotification
   object:self.fileHandle
   queue:[NSOperationQueue mainQueue]
   usingBlock:^(NSNotification *note) {
     dispatch_async(dispatch_get_main_queue(), ^{
       if(_opened) {
         NSData *data = [note.userInfo objectForKey:NSFileHandleNotificationDataItem];
         NSString *status = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
         if(handler(status) && self.fileHandle.fileDescriptor > 0)
           [self.fileHandle readInBackgroundAndNotify];
       }
     });
   }];
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.fileHandle readInBackgroundAndNotify];
  });
}

- (void)send:(NSString *)text {
  [self.fileHandle writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
