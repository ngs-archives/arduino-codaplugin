//
//  P5Preferences.h
//  Arduino
//
//  Created by Atsushi Nagase on 5/29/12.
//  Copyright (c) 2012 LittleApps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface P5Preferences : NSObject

@property (strong) NSString *string;

- (id)initWithString:(NSString *)string;

@end
