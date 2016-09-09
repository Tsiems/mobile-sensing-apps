//
//  CategoriesTableViewController.h
//  ReddericLarson
//
//  Created by Erik Gabrielsen on 9/7/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CategoriesTableViewController : UITableViewController
@property (strong, nonatomic) NSArray* categoryPhotoData;
@property (strong, nonatomic) NSDictionary* categoryTags;
@property (strong, nonatomic) NSDictionary* photoImages;
@end
