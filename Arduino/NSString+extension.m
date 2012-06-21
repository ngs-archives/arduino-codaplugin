//
//  NSString+extension.m
//  Arduino
//
//  Created by Atsushi Nagase on 6/22/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import "NSString+extension.h"

@implementation NSString (extension)

- (NSString *)replacePathExtension:(NSString *)extension inDirectory:(NSString *)directory {
  NSString *filename = [self lastPathComponent];
  NSMutableArray *parts = [[filename componentsSeparatedByString:@"."] mutableCopy];
  [parts replaceObjectAtIndex:parts.count-1 withObject:extension];
  return [directory stringByAppendingFormat:@"/%@", [parts componentsJoinedByString:@"."]];
}

@end
