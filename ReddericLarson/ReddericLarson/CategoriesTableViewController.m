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

@end

@implementation CategoriesTableViewController
@synthesize categoryPhotoData = _categoryPhotoData;
@synthesize categoryTags = _categoryTags;
@synthesize photoImages = _photoImages;
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [[FlickrKit sharedFlickrKit] initializeWithAPIKey:@"9e4dfb22612734eb30eefba263607c44" sharedSecret:@"df674246cac5a293"];
    
    FlickrKit *fk = [FlickrKit sharedFlickrKit];
    [fk call:@"flickr.interestingness.getList" args: @{@"per_page": @"5", @"page": @"1"} completion:^(NSDictionary *response, NSError *error) {
        // Note this is not the main thread!
        if (response) {
            NSMutableArray* tempPhotos = [NSMutableArray array];
            NSMutableDictionary* tempImages = [NSMutableDictionary dictionary];
            __block NSMutableDictionary* tempTags = [NSMutableDictionary dictionary];
            
            // yay callback hell to get tags
            for (NSDictionary *photoData in [response valueForKeyPath:@"photos.photo"]) {
                [tempPhotos addObject:photoData];
                __block NSString *photoID = [photoData valueForKeyPath:@"id"];

                NSURL *url = [fk photoURLForSize:FKPhotoSizeMedium640 fromPhotoDictionary:photoData];
                NSData *data = [[NSData alloc] initWithContentsOfURL:url];
                [tempImages setObject:[[UIImage alloc] initWithData:data] forKey:photoID];
                self.photoImages = [tempImages copy];
                
                [fk call:@"flickr.photos.getInfo" args: @{@"photo_id": photoID} completion:^(NSDictionary *response, NSError *error) {
                    // Note this is not the main thread!
                    if (response) {
                        NSDictionary *tag = [response valueForKeyPath:@"photo.tags.tag"][0];
                        [tempTags setObject:[tag valueForKeyPath:@"raw"] forKey:photoID];
                    }
                    self.categoryTags = [tempTags copy];
                }];
            }
            self.categoryPhotoData = [tempPhotos copy];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // Any GUI related operations here
                [self.tableView reloadData];
            });
        }
        else {
            NSLog(@"Failed: %@", error);
        }
    }];
    

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
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
    return [self categoryPhotoData].count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CategoryTableViewCell *cell = (CategoryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"categoryCell" forIndexPath:indexPath];
    
    NSString *photoID = [self.categoryPhotoData[indexPath.row] valueForKeyPath:@"id"];
    NSString *tag = [self.categoryTags objectForKey: photoID];
    cell.imageVIew.image = [self.photoImages objectForKey:photoID];
    cell.titleLabel.text = [NSString stringWithFormat:@"%@", tag];

    return cell;
}


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showCategory" sender:self];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
        NSString *photoID = [self.categoryPhotoData[selectedIndexPath.row] valueForKeyPath:@"id"];
        NSString *tag = [self.categoryTags objectForKey: photoID];
        vc.tag = tag;
    }
}


@end
