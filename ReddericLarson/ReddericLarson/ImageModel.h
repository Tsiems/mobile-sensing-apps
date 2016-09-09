//
//  ImageModel.h
//  ReddericLarson
//
//  Created by Travis Siems on 9/7/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol RefreshDelegate <NSObject>
@required
- (void)refreshImages;
@end

@interface ImageModel : NSObject

+(ImageModel*) sharedInstance;

-(NSArray*)getImages;

-(NSInteger*)getImageCount;

-(void)loadImages:(NSNumber*)num_results;

-(void)getImageMetadata:(NSString*)photo_id;

-(void)setTag:(NSString*)name;

@property (nonatomic, weak) id < RefreshDelegate > delegate;

@end

