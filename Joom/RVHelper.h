//
//  RVHelper.h
//  Joom
//
//  Created by Rohit Verma on 2014-07-23.
//  Copyright (c) 2014 rohitv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RVPlatform.h"
#import "RVAppDelegate.h"
@interface RVHelper : RVAppDelegate
+(int)getDistance:(RVPlatform*)prevPlatform;
@end
