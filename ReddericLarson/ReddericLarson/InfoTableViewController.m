//
//  InfoTableViewController.m
//  ReddericLarson
//
//  Created by mdev on 9/9/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import "InfoTableViewController.h"
#import "InfoTableViewCell.h"
#import "ImageModel.h"

@interface InfoTableViewController();
@property (strong, nonatomic) ImageModel* imageModel;
@end
@implementation InfoTableViewController
- (IBAction)closeButton:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

-(void)refreshImages{
    
    [self.tableView reloadData];
}


-(void)viewDidLoad{
    [super viewDidLoad];
    self.imageModel.delegate = self;
    self.id = self.imageModel.selectedId;
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.imageModel.metadata.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    InfoTableViewCell *cell = (InfoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"infoCell" forIndexPath:indexPath];
    
    cell.titleLabel.text = [self.imageModel.metadata[indexPath.row] valueForKey:@"label"];
    cell.subcontent.text = [[self.imageModel.metadata[indexPath.row] valueForKey:@"raw"] valueForKey:@"_content"];

    
    return cell;
}


@end
