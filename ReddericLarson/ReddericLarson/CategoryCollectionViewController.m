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

@property (strong, nonatomic) ImageModel* imageModel;

@end

@implementation CategoryCollectionViewController

static NSString * const reuseIdentifier = @"cell";

// delegate function
- (void)refreshImages {
    self.photos = [self.imageModel getImages];
    [self.collectionView reloadData];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set delegate
    self.imageModel.delegate = self;
    
    // set title
    self.title = self.tag;
    
    // round desired number of results to int
    int per_page = (int)([self.settingsModel.numberOfResults floatValue] + 0.5);
    self.settingsModel.numberOfResults = [NSNumber numberWithInteger:per_page];
    
    // load images
    [self.imageModel setTag:self.tag];
    [self.imageModel loadImages: self.settingsModel.numberOfResults];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



// Lazy instantiations
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

-(ImageModel*)imageModel{
    if(!_imageModel) {
        _imageModel = [ImageModel sharedInstance];
    }
    return _imageModel;
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
