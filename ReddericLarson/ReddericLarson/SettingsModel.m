//
//  SettingsModel.m
//  ReddericLarson
//
//  Created by Travis Siems on 9/9/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import "SettingsModel.h"

@implementation SettingsModel

-(NSNumber*)numberOfResults {
    if(!_numberOfResults) {
        _numberOfResults = @15;
    }
    return _numberOfResults;
}


+(SettingsModel*)sharedInstance{
    static SettingsModel * _sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate,^{
        _sharedInstance = [[SettingsModel alloc] init];
    });
    
    return _sharedInstance;
}


@end
