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
#define RANGE_OF_AVERAGE 25

@interface DopplerViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (weak, nonatomic) IBOutlet UILabel *sliderLabel;
@property (weak, nonatomic) IBOutlet UISlider *frequencySlider;
@property (weak, nonatomic) IBOutlet UIImageView *gestureImages;
@property double frequency;
@property BOOL calibrateFlag;
@property float *fftMagnitude;
@property double baselineLeftAverage;
@property double baselineRightAverage;
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
    [self.graphHelper setScreenBoundsBottomHalf];
    
    __block DopplerViewController * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
    
    self.frequency = (double)self.frequencySlider.value;
    self.sliderLabel.text = [NSString stringWithFormat:@"%0.0f Hz", self.frequencySlider.value];
    self.frequencySlider.continuous = NO;
    
    // register calibration tap
    self.calibrateFlag = NO;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                     initWithTarget:self action:@selector(imageTap:)];
    tap.delegate = self;
    [self.gestureImages addGestureRecognizer:tap];
    
    self.baselineLeftAverage = 0;
    self.baselineRightAverage = 0;
    
    [self.audioManager play];
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
}

-(void)viewDidDisappear:(BOOL)animated{
    
    [self.audioManager pause];
    [super viewDidDisappear:animated];
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    // just plot the audio stream
    
    // get audio stream data
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    _fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
    //send off for graphing
    [self.graphHelper setGraphData:arrayData
                    withDataLength:BUFFER_SIZE
                     forGraphIndex:0];
    
    
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:_fftMagnitude];
    
    
    [self.gestureImages setImage:[UIImage imageNamed:@"still"]];
    
    [self calibrate]; // call every time, only actually do it when flag is set
    
    // calculate doppler
    [self calculateDoppler];
    
    // graph the FFT Data
    [self.graphHelper setGraphData:_fftMagnitude
                    withDataLength:BUFFER_SIZE/2
                     forGraphIndex:1
                 withNormalization:100.0
                     withZeroValue:-60];
    
    [self.graphHelper update]; // update the graph
    free(arrayData);
    free(_fftMagnitude);
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
        if(self.audioManager.outputBlock){
            [self updateFrequency];
        }
    }
}

# pragma mark UI Interactions
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
    self.calibrateFlag = YES; // calibrate when frequency plays or changes
}

- (IBAction)stopSound:(id)sender {
    [self.audioManager setOutputBlock:nil];
}

- (void)imageTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (self.audioManager.outputBlock) {
        self.calibrateFlag = YES;
    }
}

#pragma mark Doppler Calculations
// calibrate only when is playing
-(void) calibrate{
    if (self.calibrateFlag) {
        self.baselineLeftAverage = [self calcSideAverage:(NO)];
        self.baselineRightAverage = [self calcSideAverage:(YES)];
        self.calibrateFlag = NO;
    }
}


-(double) calcSideAverage: (BOOL) isRight{
    int peakIndex = (int) (((float)self.frequency)/(((float)self.audioManager.samplingRate)/(((float)BUFFER_SIZE))));
    double average = 0;
    if(isRight){
        peakIndex += RANGE_OF_AVERAGE;
    }
    for (int i = peakIndex-RANGE_OF_AVERAGE; i <= peakIndex; ++i) {
        average += _fftMagnitude[i];
    }
    average /= RANGE_OF_AVERAGE;
    return average;
}

// will only be called when frequency is playing and baselines calculated (not 0)
-(void) calculateDoppler{
    //when playing frequency
    if(self.audioManager.outputBlock) {
        int peakIndex = (int) (((float)self.frequency)/(((float)self.audioManager.samplingRate)/(((float)BUFFER_SIZE))));
        
        [self.graphHelper setGraphData:&_fftMagnitude[peakIndex-50] withDataLength:100 forGraphIndex:2 withNormalization:100 withZeroValue:-70];
        
        //right
        double rightValue = [self calcSideAverage:(YES)];

        //left
        double leftValue = [self calcSideAverage:(NO)];

        double threshold = 10; //decibels;
        
        if(self.baselineRightAverage != 0 && rightValue - self.baselineRightAverage > threshold) {
            [self.gestureImages setImage:[UIImage imageNamed:@"towards"]];
        }
        if (self.baselineLeftAverage != 0 && leftValue - self.baselineLeftAverage > threshold) {
            [self.gestureImages setImage:[UIImage imageNamed:@"away"]];
        }
        
    }

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
