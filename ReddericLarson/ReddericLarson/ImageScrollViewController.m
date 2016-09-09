//
//  ImageScrollViewController.m
//  ReddericLarson
//
//  Created by Danh Nguyen on 9/9/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import "ImageScrollViewController.h"
#import "InfoTableViewController.h"
#import "ImageModel.h"

@interface ImageScrollViewController () <UIScrollViewDelegate>
@property (strong,nonatomic) ImageModel* imageModel;
@end

@implementation ImageScrollViewController

-(Photo*)photo {
    if (!_photo) {
        _photo = [[Photo alloc]init];
    }
    return _photo;
}

-(ImageModel*)imageModel{
    if(!_imageModel) {
        _imageModel = [ImageModel sharedInstance];
    }
    return _imageModel;
}

- (IBAction)infoButton:(id)sender {
    [self performSegueWithIdentifier:@"openInfo" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"openInfo"])
    {
        InfoTableViewController *vc = [segue destinationViewController];
        self.imageModel.selectedPhoto = self.photo;
    }
}


-(UIImageView*)imageView{
    
    if(!_imageView) {
        _imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mountains"]];
    }
    return _imageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.scrollView addSubview:self.imageView];
    self.scrollView.contentSize = self.imageView.image.size;
    self.scrollView.minimumZoomScale = 0.1;
    self.scrollView.delegate = self;
    self.imageView.image = self.photo.image;
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.imageView;
}

//send photo id to segue for photo info


@end



