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

#define BUFFER_SIZE 2048*8

#define WINDOW_DIVISOR 300

@interface ViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (strong, nonatomic) NSNumber* testNumber;

@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel;

@end



@implementation ViewController

#pragma mark Lazy Instantiation
-(Novocaine*)audioManager{
    if(!_audioManager){
        _audioManager = [Novocaine audioManager];
    }
    return _audioManager;
}

-(NSNumber*)testNumber{
    if(!_testNumber){
        _testNumber = (NSNumber*) 0;
    }
    return _testNumber;
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
                                                       numGraphs:3
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
    
    if (self.audioManager.outputBlock) {
        [self.audioManager setOutputBlock:nil];
    }
    [self.audioManager play];
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    // just plot the audio stream
    
    // get audio stream data
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
    float* equalizer = malloc(sizeof(float)*WINDOW_DIVISOR);
//    float* magnitude = malloc(sizeof(float)*BUFFER_SIZE/4);
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
    //send off for graphing
    [self.graphHelper setGraphData:arrayData
                    withDataLength:BUFFER_SIZE
                     forGraphIndex:0];
    
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:fftMagnitude];
    
    // break up fftmagnitude into chunks
    for(int i = 0; i <  WINDOW_DIVISOR; i++) {
        // NSRange *range = &((NSRange){i, i+(sizeof fftMagnitude)/20});
        
        float max = -2000000;
        for(int j = i*BUFFER_SIZE/2/WINDOW_DIVISOR; j < (i+1)*BUFFER_SIZE/2/WINDOW_DIVISOR; j+=1) {
            if(fftMagnitude[j] > max){
                max = fftMagnitude[j];
                
            }
        }
        equalizer[i] = max;
    }
    
    
    int max_window_index = 0;
    float max_value = -2000000;
    
    int max2_window_index = -1;
    float max2_value = -200000;
    
    for(int i = 0; i < WINDOW_DIVISOR; i++) {
        if(equalizer[i] > max_value) {
            
            //move 2nd highest down
            max2_window_index = max_window_index;
            max2_value = max_value;
            
            //set highest
            max_window_index = i;
            max_value = equalizer[i];
            
            
        } else if(equalizer[i] > max2_value) {
            //set second highest
            max2_window_index = i;
            max2_value = equalizer[i];
        }
    }
    
    
    
    float max = -2000000;
//    float max2 = -2000000;
    int max_index = 0;
//    int max2_index = 0;
    
//    for(int i = (BUFFER_SIZE/2)/WINDOW_DIVISOR*(max_window_index-1); i<(BUFFER_SIZE/2)/WINDOW_DIVISOR*(max_window_index+2); i++) {
//        if(fftMagnitude[i] > max){
//            max = fftMagnitude[i];
//            max_index = i;
//        }
//    }
    
    for(int i = 0; i<BUFFER_SIZE/2; i++) {
        if(fftMagnitude[i] > max){
            max = fftMagnitude[i];
            max_index = i;
        }
    }
    
    float max2 = -2000000;
    int max2_index = WINDOW_DIVISOR*max2_window_index;
    
    for(int i = (BUFFER_SIZE/2)/WINDOW_DIVISOR*(max2_window_index); i<(BUFFER_SIZE/2)/WINDOW_DIVISOR*(max2_window_index+1); i++) {
        if(fftMagnitude[i] > max2){
            max2 = fftMagnitude[i];
            max2_index = i;
        }
    }

    float max_freq = (max_index*self.audioManager.samplingRate/(BUFFER_SIZE));
//    float max2_freq = (max2_index*self.audioManager.samplingRate/(BUFFER_SIZE));
    NSLog(@"Max Hz: %f   %i",max_freq,max_index);
    
    float second_max_freq = (max2_index *  self.audioManager.samplingRate/(BUFFER_SIZE));
//    NSLog(@"Max2 Hz: %f   %i",max2_freq,max2_index);
    
    NSLog(@"Max2 Hz: %f   %i",second_max_freq,max2_window_index);
    
    // SET THE FREQUENCY LABEL TEXT
    self.frequencyLabel.text = [NSString stringWithFormat:@"%.2f Hz",max_freq];
    
    
    // graph the FFT Data
    [self.graphHelper setGraphData:fftMagnitude
                    withDataLength:BUFFER_SIZE/2
                     forGraphIndex:1
                 withNormalization:64.0
                     withZeroValue:-60];
    
    [self.graphHelper setGraphData:equalizer
                    withDataLength:WINDOW_DIVISOR
                     forGraphIndex:2
                 withNormalization:48.0
                     withZeroValue:0];
    
    [self.graphHelper update]; // update the graph
    free(arrayData);
    free(fftMagnitude);
//    free(magnitude);
    free(equalizer);
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}
- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}


- (void) viewWillDisappear:(BOOL)animated {
    [self.audioManager pause];
}


@end
