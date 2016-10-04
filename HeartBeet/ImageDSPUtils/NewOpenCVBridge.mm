//
//  NewOpenCVBridge.m
//  ImageLab
//
//  Created by Danh Nguyen on 10/4/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import "NewOpenCVBridge.h"
#import "AVFoundation/AVFoundation.h"
#import <opencv2/opencv.hpp>
#import <opencv2/highgui/cap_ios.h>

using namespace cv;

@interface NewOpenCVBridge()
    @property (nonatomic) cv::Mat image;
    @property (strong,nonatomic) CIImage* frameInput;
    @property (nonatomic) CGRect bounds;
    @property (nonatomic) CGAffineTransform transform;
    @property (nonatomic) CGAffineTransform inverseTransform;
    @property (atomic) cv::CascadeClassifier classifier;
@end


@implementation NewOpenCVBridge
 @end
