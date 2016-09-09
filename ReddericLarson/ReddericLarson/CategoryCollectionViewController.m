//
//  CategoryCollectionViewController.m
//  ReddericLarson
//
//  Created by Erik Gabrielsen on 9/7/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import "CategoryCollectionViewController.h"
#import "CategoryCollectionViewCell.h"
#import "FlickrKit/FlickrKit.h"
#import "SettingsModel.h"
#import "Photo.h"

@interface CategoryCollectionViewController ()

@property (strong, nonatomic) SettingsModel* settingsModel;

@end

@implementation CategoryCollectionViewController

static NSString * const reuseIdentifier = @"cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
//    [self.collectionView registerClass:[CategoryCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
    
    self.title = self.tag;
    
    
    [[FlickrKit sharedFlickrKit] initializeWithAPIKey:@"9e4dfb22612734eb30eefba263607c44" sharedSecret:@"df674246cac5a293"];
    FlickrKit *fk = [FlickrKit sharedFlickrKit];
    
    // round to int
    int per_page = (int)([self.settingsModel.numberOfResults floatValue] + 0.5);
    self.settingsModel.numberOfResults = [NSNumber numberWithInteger:per_page];
    NSLog(@"%@",self.settingsModel.numberOfResults);
    
    [[FlickrKit sharedFlickrKit] call:@"flickr.photos.search" args:@{@"tags": self.tag, @"per_page": [self.settingsModel.numberOfResults stringValue]} maxCacheAge:FKDUMaxAgeOneHour completion:^(NSDictionary *response, NSError *error) {
        NSMutableArray *photos = [NSMutableArray array];
        if (response) {
            for (NSDictionary *photoData in [response valueForKeyPath:@"photos.photo"]) {
                NSURL *url = [fk photoURLForSize:FKPhotoSizeSmall240 fromPhotoDictionary:photoData];
                Photo *thisPhoto = [[Photo alloc] init];
                thisPhoto.url = url;
                thisPhoto.id = [photoData valueForKey:@"id"];
                thisPhoto.title = [photoData valueForKey:@"title"];
                
                
                [photos addObject:thisPhoto];
                
                NSLog(@"url = %@",url);
            }
            
            // copy the photo objects into the photos backing variable
            _photos = [photos copy];
            
            //reload view
            dispatch_async(dispatch_get_main_queue(), ^{
                // Any GUI related operations here
                [self.collectionView reloadData];
            });
            
        }
        else {
            NSLog(@"Failed: %@",error);
        }
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString*)tag{
    if(!_tag) {
        _tag = @"London";
    }
    return _tag;
}

-(NSArray*)photos{
    if(!_photos) {
        _photos = @[];
    }
    return _photos;
}

-(SettingsModel*)settingsModel{
    if(!_settingsModel) {
        _settingsModel = [SettingsModel sharedInstance];
    }
    return _settingsModel;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}



- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CategoryCollectionViewCell *cell = (CategoryCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    
    [cell.pictureView setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString: [NSString stringWithFormat:@"%@",[(Photo*)self.photos[indexPath.row] url]]]]]];
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/


// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}


@end
