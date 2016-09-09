//
//  ViewController.m
//  ReddericLarson
//
//  Created by Travis Siems on 8/31/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import "ViewController.h"
#import "FlickrKit/FlickrKit.h"
#import "ImageModel.h"
#import "JHUD.h"

@interface ViewController ()


@property (strong, nonatomic) ImageModel* imageModel;
@property (nonatomic) JHUD *hudView;

@end

@implementation ViewController

-(ImageModel*)imageModel {
    if (!_imageModel) {
        _imageModel = [ImageModel sharedInstance];
    }
    return _imageModel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.hudView = [[JHUD alloc]initWithFrame:self.view.bounds];
    
    self.hudView.messageLabel.text = @"hello ,this is a circle animation";
    
    //show
    [self.hudView showAtView:self.view hudType:JHUDLoadingTypeCircle];
    
    //hide
    
    [[FlickrKit sharedFlickrKit] initializeWithAPIKey:@"9e4dfb22612734eb30eefba263607c44" sharedSecret:@"df674246cac5a293"];
    
    FlickrKit *fk = [FlickrKit sharedFlickrKit];
    FKFlickrInterestingnessGetList *interesting = [[FKFlickrInterestingnessGetList alloc] init];
    [fk call:interesting completion:^(NSDictionary *response, NSError *error) {
        // Note this is not the main thread!
        if (response) {
            NSMutableArray *photoURLs = [NSMutableArray array];
            for (NSDictionary *photoData in [response valueForKeyPath:@"photos.photo"]) {
                NSURL *url = [fk photoURLForSize:FKPhotoSizeSmall240 fromPhotoDictionary:photoData];
                [photoURLs addObject:url];
//                NSLog(@"url = %@",url);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                // Any GUI related operations here
                [self.hudView hide];
            });
        }   
    }];
    
//    [[FlickrKit sharedFlickrKit] call:@"flickr.photos.search" args:@{@"text": @"cat", @"per_page": @"15"} maxCacheAge:FKDUMaxAgeOneHour completion:^(NSDictionary *response, NSError *error) {
//        NSMutableArray *photoURLs = [NSMutableArray array];
//        if (response) {
//            for (NSDictionary *photoData in [response valueForKeyPath:@"photos.photo"]) {
//                NSURL *url = [fk photoURLForSize:FKPhotoSizeSmall240 fromPhotoDictionary:photoData];
//                [photoURLs addObject:url];
////                NSLog(@"cat_url = %@",url);
//            }
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if (response) {
//                    // extract images from the response dictionary
//                    
//                } else {
//                    // show the error
//                }
//            });
//        }
//        else {
//            NSLog(@"Failed");
//        }
//    }];
    
//    [self.imageModel setTag:@"donald"];
//    NSArray* links = [self.imageModel getImages]; //returns null :(
//    NSLog(@"Links: %@",links);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
