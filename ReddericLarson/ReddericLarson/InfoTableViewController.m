//
//  InfoTableViewController.m
//  ReddericLarson
//
//  Created by mdev on 9/9/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import "InfoTableViewController.h"
@interface InfoTableViewController();
@property (strong,nonatomic) NSString* id;
@end
@implementation InfoTableViewController
- (IBAction)closeButton:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}


-(void)viewDidLoad{
    [super viewDidLoad];
    
}

@end
