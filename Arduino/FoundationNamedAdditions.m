//
//  FoundationNamedAdditions.m
//
//  Created by Atsushi Nagase on 5/11/11.
//  Copyright 2011 LittleApps Inc. All rights reserved.
//

#import "FoundationNamedAdditions.h"

@implementation NSArray (NamedAddition)

+ (NSArray *)arrayNamed:(NSString *)name {
  return [NSArray arrayNamed:name bundleIdentifier:nil];
}

+ (NSArray *)arrayNamed:(NSString *)name bundleIdentifier:(NSString *)bundleIdentifier {
  NSBundle *bundle = bundleIdentifier && bundleIdentifier.length > 0 ?
  [NSBundle bundleWithIdentifier:bundleIdentifier] : [NSBundle mainBundle];
  return [NSArray arrayWithContentsOfFile:[bundle pathForNamedAsset:name]];
}

@end

@implementation NSString (NamedAddition)

+ (NSString *)stringNamed:(NSString *)name {
  return [NSString stringNamed:name bundleIdentifier:nil];
}

+ (NSString *)stringNamed:(NSString *)name bundleIdentifier:(NSString *)bundleIdentifier {
  NSBundle *bundle = bundleIdentifier && bundleIdentifier.length > 0 ?
  [NSBundle bundleWithIdentifier:bundleIdentifier] : [NSBundle mainBundle];
  return [NSString stringWithContentsOfFile:[bundle pathForNamedAsset:name] encoding:NSUTF8StringEncoding error:nil];
}

@end

@implementation NSBundle (NamedAddition)

- (NSString *)pathForNamedAsset:(NSString *)name {
  NSMutableArray *ar = [[name componentsSeparatedByString:@"."] mutableCopy];
  NSString *ext = @"plist";
  if([ar count]>=2) {
    ext = [ar lastObject];
    [ar removeLastObject];
  }
  name = [ar componentsJoinedByString:@"."];
  NSString *ret = [self pathForResource:name ofType:ext];
  return ret;
}

@end
