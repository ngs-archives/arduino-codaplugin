//
//  FoundationNamedAdditions.h
//
//  Created by Atsushi Nagase on 5/11/11.
//  Copyright 2011 LittleApps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (NamedAddition)
+ (NSArray *)arrayNamed:(NSString *)name;
+ (NSArray *)arrayNamed:(NSString *)name bundleIdentifier:(NSString *)bundleIdentifier;
@end

@interface NSDictionary (NamedAddition)
+ (NSDictionary *)dictionaryNamed:(NSString *)name;
+ (NSDictionary *)dictionaryNamed:(NSString *)name bundleIdentifier:(NSString *)bundleIdentifier;
@end

@interface NSString (NamedAddition)
+ (NSString *)stringNamed:(NSString *)name;
+ (NSString *)stringNamed:(NSString *)name bundleIdentifier:(NSString *)bundleIdentifier;
@end

@interface NSData (NamedAddition)
+ (NSData *)dataNamed:(NSString *)name;
+ (NSData *)dataNamed:(NSString *)name bundleIdentifier:(NSString *)bundleIdentifier;
@end

@interface NSBundle (NamedAddition)
- (NSString *)pathForNamedAsset:(NSString *)name;
@end
