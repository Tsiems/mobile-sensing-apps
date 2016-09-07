//
//  ImageModel.h
//  ReddericLarson
//
//  Created by Travis Siems on 9/7/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageModel : NSObject

+(ImageModel*) sharedInstance;

//-(NSArray*)getImage:(NSInteger*)index;

-(NSArray*)getLinks;
//-(NSArray*)getImages;

-(NSInteger*)getImageCount;

-(void)setTag:(NSString*)name;

@end
