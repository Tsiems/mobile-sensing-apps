//
//  ImageModel.m
//  ReddericLarson
//
//  Created by Travis Siems on 9/7/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import "ImageModel.h"
#import "FlickrKit/FlickrKit.h"
#import "Photo.h"


@interface ImageModel()

@property (strong,nonatomic) NSArray* images;
@property (strong,nonatomic) NSString* tag;

@end



@implementation ImageModel
@synthesize images = _images;
@synthesize tag = _tag;

-(NSArray*)images{
    if(!_images) {
        _images = @[];
    }
    return _images;
}

-(NSString*)tag{
    if(!_tag) {
        _tag = @"London";
    }
    return _tag;
}

+(ImageModel*)sharedInstance{
    static ImageModel * _sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate,^{
        _sharedInstance = [[ImageModel alloc] init];
    });
    
    return _sharedInstance;
}

-(void)loadImages: (NSNumber*)num_results {
    [[FlickrKit sharedFlickrKit] initializeWithAPIKey:@"9e4dfb22612734eb30eefba263607c44" sharedSecret:@"df674246cac5a293"];
    FlickrKit *fk = [FlickrKit sharedFlickrKit];
    
    id<RefreshDelegate> strongDelegate = self.delegate;
    
    [[FlickrKit sharedFlickrKit] call:@"flickr.photos.search" args:@{@"tags": self.tag, @"per_page": [num_results stringValue]} maxCacheAge:FKDUMaxAgeOneHour completion:^(NSDictionary *response, NSError *error) {
        NSMutableArray *photos = [NSMutableArray array];
        if (response) {
            for (NSDictionary *photoData in [response valueForKeyPath:@"photos.photo"]) {
                NSURL *url = [fk photoURLForSize:FKPhotoSizeSmall240 fromPhotoDictionary:photoData];
                Photo *thisPhoto = [[Photo alloc] init];
                thisPhoto.url = url;
                thisPhoto.id = [photoData valueForKey:@"id"];
                thisPhoto.title = [photoData valueForKey:@"title"];
                
                [photos addObject:thisPhoto];
//                NSLog(@"url = %@",url);
            }
            
            // copy the photo objects into the photos backing variable
            self.images = [photos copy];
            
            // refresh images in the main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongDelegate refreshImages];
            });
        }
        else {
            NSLog(@"Failed: %@",error);
        }
    }];

}

-(NSArray*)getImages {
    return self.images;
}

-(NSInteger*)getImageCount {
    NSArray *array = [self getImages];
    return (NSInteger*)[array count];
}

-(void)setTag:(NSString *)name {
    _tag = name;
}

@end

