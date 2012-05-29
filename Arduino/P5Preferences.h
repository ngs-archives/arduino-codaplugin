//
//  P5Preferences.h
//  Arduino
//
//  Created by Atsushi Nagase on 5/29/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface P5Preferences : NSObject<NSFastEnumeration>

@property (strong) NSString *string;

- (id)initWithString:(NSString *)string;
- (id)initWithContentsOfFile:(NSString *)path;
- (id)objectForKey:(id)key;
- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, BOOL *stop))block;
- (NSArray *)allKeys;

@end
