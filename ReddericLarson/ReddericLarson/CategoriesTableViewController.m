//
//  CategoriesTableViewController.m
//  ReddericLarson
//
//  Created by Erik Gabrielsen on 9/7/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import "CategoriesTableViewController.h"
#import "CategoryTableViewCell.h"
#import "CategoryCollectionViewController.h"
#import <FlickrKit/FlickrKit.h>

@interface CategoriesTableViewController ()

@property (strong,nonatomic) ImageModel* imageModel;

@end

@implementation CategoriesTableViewController
@synthesize categoryPhotoData = _categoryPhotoData;


-(ImageModel*)imageModel{
    if(!_imageModel) {
        _imageModel = [ImageModel sharedInstance];
    }
    return _imageModel;
}


// delegate function
- (void) refreshImagesWithData:(NSArray *)data {
    self.categoryPhotoData = data;
    
    [self.tableView reloadData];
    NSLog(@"Reloaded!");
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageModel.delegate = self;
    [self.imageModel loadPopularTags];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)openSettings:(id)sender {
    [self performSegueWithIdentifier:@"showSettings" sender:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"%lu",(unsigned long)[self categoryPhotoData].count);
    return [self categoryPhotoData].count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CategoryTableViewCell *cell = (CategoryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"categoryCell" forIndexPath:indexPath];
    

    NSString *tag = [self.categoryPhotoData[indexPath.row] objectForKey: @"tags"];
    cell.imageVIew.image = [self.categoryPhotoData[indexPath.row] objectForKey:@"image"];
    cell.titleLabel.text = [NSString stringWithFormat:@"%@", tag];

    return cell;
}


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showCategory" sender:self];
}






/*
#pragma mark - Navigation*/

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"showCategory"])
    {
        CategoryCollectionViewController *vc = [segue destinationViewController];
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        NSString *tag = [self.categoryPhotoData[selectedIndexPath.row] valueForKey:@"tags"];
        vc.tag = tag;
    }
}


@end
