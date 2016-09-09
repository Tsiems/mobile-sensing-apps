//
//  ImageScrollViewController.h
//  ReddericLarson
//
//  Created by Danh Nguyen on 9/9/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FlickrKit/FlickrKit.h>
#import "ImageModel.h"

@interface ImageScrollViewController : UIViewController
//@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView* imageView;
@end
