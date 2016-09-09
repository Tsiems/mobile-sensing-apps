//
//  ImageScrollViewController.m
//  ReddericLarson
//
//  Created by Danh Nguyen on 9/9/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import "ImageScrollViewController.h"
@interface ImageScrollViewController () <UIScrollViewDelegate>

@end

@implementation ImageScrollViewController

- (IBAction)infoButton:(id)sender {
    [self performSegueWithIdentifier:@"openInfo" sender:self];
}


@end



