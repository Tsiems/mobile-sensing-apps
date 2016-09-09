//
//  InfoTableViewController.m
//  ReddericLarson
//
//  Created by mdev on 9/9/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import "InfoTableViewController.h"
#import "ImageModel.h"

@interface InfoTableViewController();
@property (strong,nonatomic) NSString* id;
@property (strong, nonatomic) ImageModel* imageModel;
@end
@implementation InfoTableViewController
- (IBAction)closeButton:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}


-(void)viewDidLoad{
    [super viewDidLoad];
    [self.imageModel getImageMetadata:_id];
}

-(ImageModel*)imageModel{
    if(!_imageModel) {
        _imageModel = [ImageModel sharedInstance];
    }
    return _imageModel;
}

-(NSString*)id{
    if(!_id) {
        _id = @"";
    }
    return _id;
}


@end
