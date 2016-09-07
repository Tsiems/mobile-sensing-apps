//
//  ImageModel.m
//  ReddericLarson
//
//  Created by Travis Siems on 9/7/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import "ImageModel.h"
#import "FlickrKit/FlickrKit.h"


@interface ImageModel()

@property (strong,nonatomic) NSArray* links;
@property (strong,nonatomic) NSArray* images;
@property (strong,nonatomic) NSString* tag;

@end



@implementation ImageModel
@synthesize links = _links;
@synthesize tag = _tag;

-(NSArray*)links{
    
    if(!_links) {
        
        [[FlickrKit sharedFlickrKit] initializeWithAPIKey:@"9e4dfb22612734eb30eefba263607c44" sharedSecret:@"df674246cac5a293"];
        FlickrKit *fk = [FlickrKit sharedFlickrKit];
        
        [[FlickrKit sharedFlickrKit] call:@"flickr.photos.search" args:@{@"tags": self.tag, @"per_page": @"15"} maxCacheAge:FKDUMaxAgeOneHour completion:^(NSDictionary *response, NSError *error) {
            NSMutableArray *photoURLs = [NSMutableArray array];
            if (response) {
                for (NSDictionary *photoData in [response valueForKeyPath:@"photos.photo"]) {
                    NSURL *url = [fk photoURLForSize:FKPhotoSizeSmall240 fromPhotoDictionary:photoData];
                    [photoURLs addObject:url];
                    NSLog(@"url = %@",url);
                }
                
                // copy the photo urls into the links backing variable
                _links = [photoURLs copy]; // !!!!! MAY HAVE ISSUES WITH THIS NOT FINISHING BEFORE WE RETURN !!!!!
            }
            else {
                NSLog(@"Failed: %@",error);
            }
        }];
        
    }
    
    return _links;
}

-(NSString*)tag{
    if(!_tag) {
        _tag = @"cat";
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

-(NSArray*)getLinks {
    return self.links;
}

-(NSInteger*)getImageCount {
    NSArray *array = [self getLinks];
    return (NSInteger*)[array count];
}

-(void)setTag:(NSString *)name {
    _tag = name;
}




//-(NSArray*)getImage:(NSInteger *)index{
//    UIImage* image = nil;
//    image = [self getImages][(int) index];
//    
//    NSString* name = nil;
//    name = [self getLinks][(int) index];
//    return @[image,name];
//}



//-(NSArray*)getImages {
//    if(!_images) {
//        NSArray* links = [self getLinks];
//        NSMutableArray *tempImages = [NSMutableArray new];
//        for (NSString* name in links) {
//            [tempImages addObject:[self getImageWithName:name]];
//        }
//        _images = [tempImages copy];
//    }
//    
//    return _images;
//}





@end

