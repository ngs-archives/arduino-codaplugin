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
- (id)get:(NSString *)key;
- (NSString *)getString:(NSString *)key;
- (P5Preferences *)preferencesForKey:(NSString *)key;
+ (P5Preferences *)boardPreferences;
+ (P5Preferences *)programmerPreferences;
+ (P5Preferences *)selectedBoardPreferences;
+ (P5Preferences *)selectedProgrammerPreferences;

@end
