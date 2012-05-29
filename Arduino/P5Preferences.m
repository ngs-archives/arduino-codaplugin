//
//  P5Preferences.m
//  Arduino
//
//  Created by Atsushi Nagase on 5/29/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "P5Preferences.h"

@interface P5Preferences ()

@property (strong) NSMutableDictionary *table;

- (void)parseString;

@end

@implementation P5Preferences
@synthesize string = _string
, table = _table
;

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


@end
