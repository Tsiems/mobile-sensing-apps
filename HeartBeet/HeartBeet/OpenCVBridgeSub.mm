//
//  OpenCVBridgeSub.m
//  ImageLab
//
//  Created by Eric Larson on 10/4/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import "OpenCVBridgeSub.h"

#import "AVFoundation/AVFoundation.h"


using namespace cv;
#define SAMPLE_SIZE 200

@interface OpenCVBridgeSub()
@property (nonatomic) cv::Mat image;
@property float* averageReds;
@property float* averageBlues;
@property float* averageGreens;
@property int arrayLoc;
@end

@implementation OpenCVBridgeSub
@dynamic image;

-(instancetype)init{
    self = [super init];
    
    if(self != nil){
        self.averageReds = new float[SAMPLE_SIZE];
        self.averageBlues = new float[SAMPLE_SIZE];
        self.averageGreens = new float[SAMPLE_SIZE];
        self.arrayLoc = 0;
        
    }
    return self;
}

-(void) processImage {
//    framerate logging
//    static NSDate *start = [NSDate date];
//    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
//    start = [NSDate date];
//    NSLog(@"time:  %f", timeInterval);
    
    cv::Mat image = self.image;
    cv::Mat frame_gray,image_copy;
    char text[50];
    
    Scalar avgPixelIntensity;
    cvtColor(self.image, image_copy, CV_RGBA2BGR); // get rid of alpha for processing
    avgPixelIntensity = cv::mean( image_copy );
    
    float avgBlue = avgPixelIntensity.val[0];
    float avgGreen = avgPixelIntensity.val[1];
    float avgRed = avgPixelIntensity.val[2];
    
    
    
    if ((avgRed >= 160 && avgBlue < 40) && avgGreen < 40) {
        cv::putText(image, "FINGER!", cv::Point(50, 100), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleOn" object:nil userInfo: @{@"toggleOn": @"On"}];
        
        if (self.arrayLoc < SAMPLE_SIZE) {
            self.averageReds[self.arrayLoc] = avgRed;
            self.averageBlues[self.arrayLoc] = avgBlue;
            self.averageGreens[self.arrayLoc] = avgGreen;
            
            self.arrayLoc += 1;
            if (self.arrayLoc >= SAMPLE_SIZE) {
                NSLog(@"Arrays Full");
            }
        }
        
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleOn" object:nil userInfo: @{@"toggleOn": @"OFF"}];
    }
    
    sprintf(text,"Avg. B: %.0f, G: %.0f, R: %.0f", avgPixelIntensity.val[0],avgPixelIntensity.val[1],avgPixelIntensity.val[2]);
    cv::putText(image, text, cv::Point(50, 75), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
    self.image = image;
    
}

-(float*) getRed {
    return self.averageReds;
}

@end
