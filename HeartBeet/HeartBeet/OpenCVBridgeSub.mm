//
//  OpenCVBridgeSub.m
//  ImageLab
//
//  Created by Eric Larson on 10/4/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import "OpenCVBridgeSub.h"
#import "PeakFinder.h"
#import "AVFoundation/AVFoundation.h"


using namespace cv;
#define SAMPLE_SIZE 200

@interface OpenCVBridgeSub()
@property (nonatomic) cv::Mat image;
@property float* averageReds;
@property float* scaledAverageReds;
@property float absMax;
@property float absMin;
@property (strong, nonatomic) CircularBuffer *averageRedBuffer;
@property int arrayLoc;
@property (strong, nonatomic) PeakFinder *finder;
@property (nonatomic) float bpm;
@property (nonatomic) double frametime;
@end

@implementation OpenCVBridgeSub
@dynamic image;

-(PeakFinder*)finder{
    if(!_finder){
        _finder = [[PeakFinder alloc]initWithFrequencyResolution:(30/SAMPLE_SIZE)];
    }
    return _finder;
}

-(float)bpm{
    if(!_bpm){
        _bpm = 0.0;
    }
    return _bpm;
}

-(double)frametime{
    if(!_frametime){
        _frametime = 0.0;
    }
    return _frametime;
}

-(instancetype)init{
    self = [super init];
    
    if(self != nil){
        self.averageReds = new float[SAMPLE_SIZE];
        self.scaledAverageReds = new float[SAMPLE_SIZE];
        self.arrayLoc = 0;
        
        //initialize with 0
        for (int i = 0; i < SAMPLE_SIZE; i++) {
            self.averageReds[i] = 0;
            self.scaledAverageReds[i] = 0;
        }
        
        self.absMax = 0;
        self.absMin = 255;
        
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
    static NSDate *start = [NSDate date];
    static double framesum = 0.0;
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    start = [NSDate date];
    framesum += -timeInterval;
    if(self.arrayLoc == SAMPLE_SIZE - 1){
        self.frametime = framesum/((double)SAMPLE_SIZE);
        framesum = 0.0;
    }
    
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
        if(self.bpm != 0.0){
            char text [50];
            sprintf(text,"BPM: %.0f", self.bpm);
            cv::putText(image, text, cv::Point(50, 150), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
        }
        else{
            cv::putText(image, "Calculating...", cv::Point(50, 150), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
        }
        cv::putText(image, "FINGER!", cv::Point(50, 100), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleOn" object:nil userInfo: @{@"toggleOn": @"On"}];
        
        if (self.arrayLoc < SAMPLE_SIZE) {
            self.averageReds[self.arrayLoc] = avgRed;

            self.arrayLoc += 1;
            if (self.arrayLoc >= SAMPLE_SIZE) {
                NSLog(@"Arrays Full");
//                [self.averageRedBuffer addNewFloatData:_averageReds withNumSamples:SAMPLE_SIZE];
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
    
    // get current absolute min max
    float max = self.absMax;
    float min = self.absMin;
    
    // find new abs when buffer is full
    if (self.arrayLoc >= SAMPLE_SIZE) {
        // reset max and min values
        max = 0;
        min = 255;
        for (int i = 0; i < SAMPLE_SIZE; i++) {
            if (self.averageReds[i] > max) max = self.averageReds[i];
            else if (self.averageReds[i] < min) min = self.averageReds[i];
        }
        self.arrayLoc = 0;
        
    }
    
    // subtract min and divide by (max-min) if they're not initial values
    // do this even when buffer size isn't full
    if (max > 0 && min < 255) {
        for (int i = 0; i < SAMPLE_SIZE; i++) {
            self.scaledAverageReds[i] = (float)(self.averageReds[i]-min)/((float)max-(float)min);
        }
        self.absMax = max;
        self.absMin = min;
        //calc heartbeat
        if(self.arrayLoc == 0){
            NSMutableArray *peaks = [[NSMutableArray alloc] init];
            for (int i = 1; i<SAMPLE_SIZE; i++){
                if(self.averageReds[i] > self.averageReds[i-1] && self.averageReds[i] > self.averageReds[i+1])
                    [peaks addObject:[NSNumber numberWithInt:i]];
            }
        [self calcBPM:peaks];
        }
    }
    
    
    return self.scaledAverageReds;
}

-(void) calcBPM:(NSArray*) peakArray{
    NSUInteger numPeaks = peakArray.count;
    float lastPeak = [peakArray[numPeaks-1] floatValue];
    float firstPeak = [peakArray[0] floatValue];
    float effectiveBuffer = lastPeak - firstPeak;
    self.bpm = (((float)numPeaks) / ((effectiveBuffer * self.frametime)/60.0))/2.0;
}


@end
