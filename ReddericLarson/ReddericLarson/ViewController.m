//
//  ViewController.m
//  ReddericLarson
//
//  Created by Travis Siems on 8/31/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import "ViewController.h"
#import "FlickrKit/FlickrKit.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
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
                NSLog(@"url = %@",url);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                // Any GUI related operations here
            });
        }   
    }];
    
    [[FlickrKit sharedFlickrKit] call:@"flickr.photos.search" args:@{@"text": @"cat", @"per_page": @"15"} maxCacheAge:FKDUMaxAgeOneHour completion:^(NSDictionary *response, NSError *error) {
        NSMutableArray *photoURLs = [NSMutableArray array];
        if (response) {
            for (NSDictionary *photoData in [response valueForKeyPath:@"photos.photo"]) {
                NSURL *url = [fk photoURLForSize:FKPhotoSizeSmall240 fromPhotoDictionary:photoData];
                [photoURLs addObject:url];
                NSLog(@"cat_url = %@",url);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (response) {
                    // extract images from the response dictionary
                    
                } else {
                    // show the error
                }
            });
        }
        else {
            NSLog(@"Failed");
        }
    }];
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
