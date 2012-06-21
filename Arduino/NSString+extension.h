//
//  NSString+extension.h
//  Arduino
//
//  Created by Atsushi Nagase on 6/22/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (extension)

- (NSString *)replacePathExtension:(NSString *)extension inDirectory:(NSString *)directory;

@end
