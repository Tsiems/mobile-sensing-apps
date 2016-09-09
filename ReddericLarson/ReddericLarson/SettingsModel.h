//
//  SettingsModel.h
//  ReddericLarson
//
//  Created by Travis Siems on 9/9/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SettingsModel : NSObject

@property (strong,nonatomic) NSNumber* numberOfResults;

+(SettingsModel*) sharedInstance;

@end
