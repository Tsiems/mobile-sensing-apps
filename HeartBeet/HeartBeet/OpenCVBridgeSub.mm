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
@property (strong, nonatomic) CircularBuffer *averageRedBuffer;
@property int arrayLoc;
@end

@implementation OpenCVBridgeSub
@dynamic image;

-(instancetype)init{
    self = [super init];
    
    if(self != nil){
        self.averageReds = new float[SAMPLE_SIZE];
        self.arrayLoc = 0;
        
        //initialize with 240
        for (int i = 0; i < SAMPLE_SIZE; i++) {
            self.averageReds[i] = 240;
        }
        
    }
    return self;
}

-(CircularBuffer*)averageRedBuffer{
    if(!_averageRedBuffer){
        _averageRedBuffer = [[CircularBuffer alloc]initWithNumChannels:1 andBufferSize:SAMPLE_SIZE];
    }
    return _averageRedBuffer;
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
    
    
    
    if ((avgRed >= 160 && avgBlue < 50) && avgGreen < 50) {
        cv::putText(image, "FINGER!", cv::Point(50, 100), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleOn" object:nil userInfo: @{@"toggleOn": @"On"}];
        
        if (self.arrayLoc < SAMPLE_SIZE) {
            self.averageReds[self.arrayLoc] = avgRed;
    
            [self.averageRedBuffer addNewFloatData:_averageReds withNumSamples:SAMPLE_SIZE];

            self.arrayLoc += 1;
            if (self.arrayLoc >= SAMPLE_SIZE) {
                NSLog(@"Arrays Full");
                self.arrayLoc = 0;
            }
        }
        
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleOn" object:nil userInfo: @{@"toggleOn": @"OFF"}];
    }
    
    sprintf(text,"Avg. B: %.0f, G: %.0f, R: %.0f", avgPixelIntensity.val[0],avgPixelIntensity.val[1],avgPixelIntensity.val[2]);
    cv::putText(image, text, cv::Point(50, 75), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
    self.image = image;
    
}

-(CircularBuffer*) getRedBuffer {
    return self.averageRedBuffer;
}

-(float*) getRed {
    return self.averageReds;
}

-(float*) getScaledRedArray {
    float* returnArray = new float[SAMPLE_SIZE];
    [self.averageRedBuffer fetchFreshData:returnArray withNumSamples:SAMPLE_SIZE];
    
    // find absolute min max
    float max = returnArray[0];
    float min = returnArray[0];
    
    for (int i = 0; i < SAMPLE_SIZE; i++) {
        if (returnArray[i] > max) max = returnArray[i];
        else if (returnArray[i] < min) min = returnArray[i];
    }
    
//    NSLog(@"%f, %f", max, min);

    // subtract min and divide by (max-min)
    for (int i = 0; i < SAMPLE_SIZE; i++) {
        returnArray[i] = (float)(returnArray[i]-min)/((float)max-(float)min);
        NSLog(@"%f", returnArray[i]);
    }
    
    return returnArray;
}

@end
