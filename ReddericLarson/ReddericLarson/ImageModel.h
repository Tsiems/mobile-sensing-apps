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
@optional
- (void)refreshImages;
- (void)refreshImagesWithData: (NSArray*)data;
@end

@interface ImageModel : NSObject

+(ImageModel*) sharedInstance;

-(NSArray*)getImages;

-(NSInteger*)getImageCount;

-(void)loadImages:(NSNumber*)num_results;

-(void)setTag:(NSString*)name;

-(void)loadPopularTags;

@property (nonatomic, weak) id < RefreshDelegate > delegate;

@end

