//
//  Photo.h
//  ReddericLarson
//
//  Created by Travis Siems on 9/9/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Photo : NSObject

@property (strong,nonatomic) NSString* id;
@property (strong,nonatomic) NSURL* url;
@property (strong,nonatomic) NSString* title;
@property (strong,nonatomic) NSArray* metadata;

@end
