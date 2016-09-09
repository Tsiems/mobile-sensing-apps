//
//  CategoryCollectionViewController.h
//  ReddericLarson
//
//  Created by Erik Gabrielsen on 9/7/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageModel.h"

@interface CategoryCollectionViewController : UICollectionViewController <RefreshDelegate>

@property (strong,nonatomic) NSString* tag;
@property (strong,nonatomic) NSArray* photos;
@end
