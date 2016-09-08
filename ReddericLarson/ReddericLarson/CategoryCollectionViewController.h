//
//  CategoryCollectionViewController.h
//  ReddericLarson
//
//  Created by Erik Gabrielsen on 9/7/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CategoryCollectionViewController : UICollectionViewController

@property (strong,nonatomic) NSString* tag;
@property (strong,nonatomic) NSArray* links;
@end
