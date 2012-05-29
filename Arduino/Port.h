//
//  Port.h
//  Arduino
//
//  Created by Atsushi Nagase on 5/29/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Port : NSObject

- (id)initWithPath:(NSString *)path;

- (void)watch:(BOOL (^)(NSString *status))handler;
- (NSInteger)open;
- (void)close;
- (void)send:(NSString *)text;
  
@property (strong) NSFileHandle *fileHandle;
@property (strong) NSString *path;
@property (readonly) BOOL opened;
@property (readonly) dispatch_queue_t queue;

@end
