//
//  ImageScrollViewController.m
//  ReddericLarson
//
//  Created by Danh Nguyen on 9/9/16.
//  Copyright © 2016 MobileSensing. All rights reserved.
//

#import "ImageScrollViewController.h"
@interface ImageScrollViewController () <UIScrollViewDelegate>
@property (strong, nonatomic) NSDictionary* photoData;
@end

@implementation ImageScrollViewController
-(NSDictionary*)photoData{
    if(!_photoData) {
        _photoData = [[NSDictionary alloc] init];
    }
    return _photoData;
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
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.imageView;
}

//send photo id to segue for photo info


@end



