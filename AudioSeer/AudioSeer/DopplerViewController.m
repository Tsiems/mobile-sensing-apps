//
//  DopplerViewController.m
//  AudioSeer
//
//  Created by Danh Nguyen on 9/20/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

#import "DopplerViewController.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "SMUGraphHelper.h"
#import "FFTHelper.h"
#import "PeakFinder.h"

#define BUFFER_SIZE 2048*4

@interface DopplerViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (weak, nonatomic) IBOutlet UILabel *sliderLabel;
@property (weak, nonatomic) IBOutlet UISlider *frequencySlider;
@property double frequency;
@end

@implementation DopplerViewController

#pragma mark Lazy Instantiation
-(Novocaine*)audioManager{
    if(!_audioManager){
        _audioManager = [Novocaine audioManager];
    }
    return _audioManager;
}


-(CircularBuffer*)buffer{
    if(!_buffer){
        _buffer = [[CircularBuffer alloc]initWithNumChannels:1 andBufferSize:BUFFER_SIZE];
    }
    return _buffer;
}

-(SMUGraphHelper*)graphHelper{
    if(!_graphHelper){
        _graphHelper = [[SMUGraphHelper alloc]initWithController:self
                                        preferredFramesPerSecond:15
                                                       numGraphs:2
                                                       plotStyle:PlotStyleSeparated
                                               maxPointsPerGraph:BUFFER_SIZE];
    }
    return _graphHelper;
}

-(FFTHelper*)fftHelper{
    if(!_fftHelper){
        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
    }
    
    return _fftHelper;
}


#pragma mark VC Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //[self setPauseOnWillResignActive:false];
    [self.graphHelper setScreenBoundsBottomHalf];
    
    __block DopplerViewController * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
    
    self.frequency = (double)self.frequencySlider.value;
    self.sliderLabel.text = [NSString stringWithFormat:@"%0.0f Hz", self.frequencySlider.value];
    self.frequencySlider.continuous = NO;
    
    [self.audioManager play];
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    // just plot the audio stream
    
    // get audio stream data
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    float* arrayData2 = malloc(sizeof(float)*BUFFER_SIZE);
    float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
    float* fftMagnitude2 = malloc(sizeof(float)*BUFFER_SIZE/2);
    float* fftAverage = malloc(sizeof(float)*BUFFER_SIZE/2);
    float* equalizer = malloc(sizeof(float)*20);
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    [self.buffer fetchFreshData:arrayData2 withNumSamples:BUFFER_SIZE];
    
    //send off for graphing
    [self.graphHelper setGraphData:arrayData
                    withDataLength:BUFFER_SIZE
                     forGraphIndex:0];
    
    
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:fftMagnitude];
    
    [self.fftHelper performForwardFFTWithData:arrayData2
                   andCopydBMagnitudeToBuffer:fftMagnitude2];
    
    for(int i = 0; i < BUFFER_SIZE/2; ++i) {
        fftAverage[i] = (fftMagnitude[i]+fftMagnitude2[i])/2.0;
    }
    
    // break up fftaverage into chunks
    for(int i = 0; i <  20; i+=1) {
        
        float max = -2000000;
        for(int j = i*BUFFER_SIZE/40; j < (i+1)*BUFFER_SIZE/40; j+=1) {
            if(fftMagnitude[j] > max){
                max = fftAverage[j];
                
            }
        }
        equalizer[i] = max;
    }
    
    // calculate local/abs peaks
    PeakFinder *peakFinder = [[PeakFinder alloc] initWithFrequencyResolution:self.audioManager.samplingRate/(BUFFER_SIZE/2)];
//
//    NSArray* peaks = [peakFinder getFundamentalPeaksFromBuffer:fftMagnitude withLength:BUFFER_SIZE/2 usingWindowSize:5 andPeakMagnitudeMinimum:10 aboveFrequency:200];
//    
//    for( int i = 0; i<peaks.count; i++) {
//        NSLog(@"Peak Frequency: %f   magnitude: %f",[(Peak*)peaks[i] frequency]/2, [(Peak*)peaks[i] magnitude]);
//    }
//
    
    //when playing frequency
    if(self.audioManager.outputBlock) {
        
    }
    
    
    // graph the FFT Data
    [self.graphHelper setGraphData:fftAverage
                    withDataLength:BUFFER_SIZE/2
                     forGraphIndex:1
                 withNormalization:100.0
                     withZeroValue:-60];
    
    [self.graphHelper update]; // update the graph
    free(arrayData);
    free(fftMagnitude);
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

- (IBAction)changeFrequency:(id)sender {
    if (sender == self.frequencySlider) {
        self.frequency = roundl(self.frequencySlider.value);
        self.sliderLabel.text = [NSString stringWithFormat:@"%0.0f Hz", self.frequencySlider.value];
        
        // if sound is playing ie output block exists
        if(self.audioManager.outputBlock)
            [self updateFrequency];
    }
}

- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
    [self.audioManager pause];
}

- (IBAction)playSound:(id)sender {
    [self updateFrequency];
}

- (void) updateFrequency {
    __block double phase = 0.0;
    double phaseIncrement = 2.0*M_PI*((double)self.frequency)/((double)self.audioManager.samplingRate);
    double phaseMax = 2.0*M_PI;
    [self.audioManager setOutputBlock:^(float* data, UInt32 numFrames, UInt32 numChannels){
        for(int i=0; i<numFrames;++i){
            for(int j=0;j<numChannels;++j){
                data[numChannels*i+j] = sin(phase);
            }
            phase+=phaseIncrement;
            if (phase>phaseMax){
                phase -= phaseMax;
            }
        }
        
    }];
    
}

- (IBAction)stopSound:(id)sender {
    [self.audioManager setOutputBlock:nil];
}



-(void)viewWillDisappear:(BOOL)animated{
    
    [self.audioManager pause];
    [super viewWillDisappear:animated];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
