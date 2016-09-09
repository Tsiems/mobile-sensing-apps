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
//@property (strong,nonatomic) NSString* numberOfResults;
@property (strong,nonatomic) NSString* sortValue;

+(SettingsModel*) sharedInstance;

@end
