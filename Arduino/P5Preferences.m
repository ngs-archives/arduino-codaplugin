//
//  P5Preferences.m
//  Arduino
//
//  Created by Atsushi Nagase on 5/29/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "P5Preferences.h"
#import "ArduinoPlugin.h"

#define kBoardsTxtPath @"/hardware/arduino/boards.txt"
#define kProgrammersTxtPath @"/hardware/arduino/programmers.txt"

@interface P5Preferences ()

@property (strong) NSMutableDictionary *table;

- (void)parseString;

@end

@implementation P5Preferences
@synthesize string = _string
, table = _table
;

- (id)initWithContentsOfFile:(NSString *)path {
  NSError *error = nil;
  self = [self initWithString:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error]];
  if(error) {
    NSLog(@"%@", error);
    return nil;
  }
  return self;
}

- (id)initWithString:(NSString *)string {
  if(self=[super init]) {
    self.table = [NSMutableDictionary dictionary];
    self.string = string;
  }
  return self;
}

- (void)setString:(NSString *)string {
  _string = string;
  [self parseString];
}

- (NSString *)string {
  return _string;
}

- (void)parseString {
  NSArray *lines = [self.string componentsSeparatedByString:@"\n"];
  for (NSString *line in lines) {
    if(line.length == 0 || [line hasPrefix:@"#"]) continue;
    NSInteger equals = [line rangeOfString:@"="].location;
    if(equals != NSNotFound) {
      __block NSMutableDictionary *map = self.table;
      NSArray *keys = [[[line substringToIndex:equals]
                       stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]]
                       componentsSeparatedByString:@"."];
      NSString *value = [[line substringFromIndex:equals+1]
                       stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];;
      NSInteger len = keys.count;
      for (NSInteger idx=0; idx<len; idx++) {
        NSString *key = [keys objectAtIndex:idx];
        if(idx==len-1) {
          [map setValue:value forKey:key];
          map = self.table;
        } else if(![[map objectForKey:key] isKindOfClass:[NSMutableDictionary class]]) {
          NSMutableDictionary *dic = [NSMutableDictionary dictionary];
          [map setObject:dic forKey:key];
          map = dic;
        } else {
          map = [map objectForKey:key];
          if(![map isKindOfClass:[NSMutableDictionary class]])
            NSAssert1([map isKindOfClass:[NSMutableDictionary class]], @"map should be a NSMutableDictionary, but a %@", map);
        }
      }
    }
  }
}

#pragma mark -

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len {
  return [self.table countByEnumeratingWithState:state objects:buffer count:len];
}

- (id)objectForKey:(id)key {
  return [self.table objectForKey:key];
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id, id, BOOL *))block {
  [self.table enumerateKeysAndObjectsUsingBlock:block];
}

- (NSArray *)allKeys {
  return [self.table allKeys];
}

- (id)get:(NSString *)key {
  NSArray *keys = [key componentsSeparatedByString:@"."];
  id ret = nil;
  for (NSInteger i=0; i<keys.count; i++) {
    NSString *k = [keys objectAtIndex:i];
    ret = ret ? [ret objectForKey:k] : [self objectForKey:k];
    if(!ret) break;
  }
  return ret;
}

- (NSString *)getString:(NSString *)key {
  id obj = [self get:key];
  if(!obj || ![obj isKindOfClass:[NSString class]])
    obj = @"null";
  return obj;
}

- (P5Preferences *)preferencesForKey:(NSString *)key {
  P5Preferences *pref = [[P5Preferences alloc] init];
  pref.table = [[self objectForKey:key] mutableCopy];
  return pref;
}

#pragma mark -

+ (P5Preferences *)boardPreferences {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *loc = [defaults valueForKey:ArduinoPluginArduinoLocationKey];
  return [[P5Preferences alloc] initWithContentsOfFile:[loc stringByAppendingString:kBoardsTxtPath]];
}

+ (P5Preferences *)programmerPreferences {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *loc = [defaults valueForKey:ArduinoPluginArduinoLocationKey];
  return [[P5Preferences alloc] initWithContentsOfFile:[loc stringByAppendingString:kProgrammersTxtPath]];
}

+ (P5Preferences *)selectedBoardPreferences {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *key = [defaults valueForKey:ArduinoPluginBoardKey];
  return [[self boardPreferences] preferencesForKey:key];
}

+ (P5Preferences *)selectedProgrammerPreferences {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *key = [defaults valueForKey:ArduinoPluginProgrammerKey];
  return [[self boardPreferences] preferencesForKey:key];
}

@end
