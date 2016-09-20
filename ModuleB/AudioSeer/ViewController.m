//
//  ViewController.m
//  AudioLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import "ViewController.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "SMUGraphHelper.h"
#import "FFTHelper.h"

#define BUFFER_SIZE 2048*2

@interface ViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (weak, nonatomic) IBOutlet UISlider *frequencySlider;
@property double frequency;
@end



@implementation ViewController

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
    [self.graphHelper setFullScreenBounds];
    
    __block ViewController * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
    
    self.frequency = (double)self.frequencySlider.value;
    self.frequencySlider.continuous = NO;
    
    [self.audioManager play];
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    // just plot the audio stream
    
    // get audio stream data
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
    float* equalizer = malloc(sizeof(float)*20);
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
    //send off for graphing
    [self.graphHelper setGraphData:arrayData
                    withDataLength:BUFFER_SIZE
                     forGraphIndex:0];
    
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:fftMagnitude];
    
    // break up fftmagnitude into chunks
    for(int i = 0; i <  20; i+=1) {
        // NSRange *range = &((NSRange){i, i+(sizeof fftMagnitude)/20});
        
        float max = -2000000;
        for(int j = i*BUFFER_SIZE/40; j < (i+1)*BUFFER_SIZE/40; j+=1) {
            if(fftMagnitude[j] > max){
                max = fftMagnitude[j];
                
            }
        }
        equalizer[i] = max;
    }
    
    
    // graph the FFT Data
    [self.graphHelper setGraphData:fftMagnitude
                    withDataLength:BUFFER_SIZE/2
                     forGraphIndex:1
                 withNormalization:64.0
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
        self.frequency = self.frequencySlider.value;
        
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


@end
