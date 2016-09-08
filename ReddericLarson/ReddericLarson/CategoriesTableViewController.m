//
//  CategoriesTableViewController.m
//  ReddericLarson
//
//  Created by Erik Gabrielsen on 9/7/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import "CategoriesTableViewController.h"
#import "CategoryTableViewCell.h"
#import <FlickrKit/FlickrKit.h>

@interface CategoriesTableViewController ()
@property (strong, nonatomic) NSArray* categoryPhotos;
@end

@implementation CategoriesTableViewController
@synthesize categoryPhotos = _categoryPhotos;
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
            for (NSDictionary *photoData in [response valueForKeyPath:@"photos.photo"]) {
                [tempPhotos addObject:photoData];
            }
            
            self.categoryPhotos = [tempPhotos copy];
            
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
    return [self categoryPhotos].count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CategoryTableViewCell *cell = (CategoryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"categoryCell" forIndexPath:indexPath];
    
    FlickrKit *fk = [FlickrKit sharedFlickrKit];
    NSDictionary *cellPhoto = self.categoryPhotos[indexPath.row];
    
    // Configure the cell...
    [fk call:@"flickr.photos.getInfo" args: @{@"photo_id": [cellPhoto valueForKeyPath:@"id"]} completion:^(NSDictionary *response, NSError *error) {
        // Note this is not the main thread!
        if (response) {
            NSDictionary *tag = [response valueForKeyPath:@"photo.tags.tag"][0];
            NSString* tagName = [tag valueForKeyPath:@"raw"];
            dispatch_async(dispatch_get_main_queue(), ^{
                // Any GUI related operations here
                cell.titleLabel.text = [NSString stringWithFormat:@"%@", tagName];
                NSURL *url = [fk photoURLForSize:FKPhotoSizeMedium640 fromPhotoDictionary:cellPhoto];
                NSData *data = [[NSData alloc] initWithContentsOfURL:url];
                UIImage *tmpImage = [[UIImage alloc] initWithData:data];
                cell.imageVIew.image = tmpImage;

            });
        }
        else {
            NSLog(@"Failed: %@", error);
        }
    }];
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
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
