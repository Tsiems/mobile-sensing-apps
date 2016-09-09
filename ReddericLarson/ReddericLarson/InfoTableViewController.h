//
//  InfoTableViewController.h
//  ReddericLarson
//
//  Created by mdev on 9/9/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageModel.h"

@interface InfoTableViewController : UITableViewController <RefreshDelegate>
@property (strong,nonatomic) NSString* id;

@end
