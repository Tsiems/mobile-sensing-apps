//
//  ViewController.m
//  BLEChat
//
//  Created by Cheong on 15/8/12.
//  Modified by Eric Larson, 2014
//  Copyright (c) 2012 RedBear Lab., All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *peripheralLabel;
@property (weak, nonatomic) IBOutlet UISlider *servoSlider;

@end

@implementation ViewController

// CHANGE 3: Add support for lazy instantiation (like we did in the table view controller)
-(BLE*)bleShield
{
    if (!_bleShield) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        _bleShield = appDelegate.bleShield;
    }
    return _bleShield;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // CHANGE 1.a: change this as you no longer need to instantiate the BLE Object like this
    // nor should this ViewController be the delegate
//    bleShield = [[BLE alloc] init];
//    [bleShield controlSetup];
//    bleShield.delegate = self;
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"startmeup" ofType:@"mp3"];
    NSURL* file = [NSURL fileURLWithPath:path];
    // thanks @gebirgsbaerbel
    
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:file error:nil];
    [audioPlayer setVolume:0.5];
    [audioPlayer prepareToPlay];
    
    //CHANGE 4: add subscription to notifications from the app delegate
    //These selector functions should be created from the old BLEDelegate functions
    // One example has already been completed for you on the receiving of data function
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBLEDidConnect:) name:kBleConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBLEDidDisconnect:) name:kBleDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBLEDidUpdateRSSI:) name:kBleRSSINotification object:nil];
    
    // this example function "onBLEDidReceiveData:" is done for you, see below
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (onBLEDidReceiveData:) name:kBleReceivedDataNotification object:nil];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [audioPlayer pause];
    audioPlayer = nil;
}

-(void) playMP3 {
    if ([audioPlayer isPlaying]) {
        [audioPlayer pause];
    } else {
        [audioPlayer play];
    }
}

//setup auto rotation in code
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - RSSI timer
NSTimer *rssiTimer;
-(void) readRSSITimer:(NSTimer *)timer
{
    [self.bleShield readRSSI]; // be sure that the RSSI is up to date
}

#pragma mark - BLEdelegate protocol methods
-(void) onBLEDidUpdateRSSI:(NSNotification *)notification
{
    NSNumber *rssi =[notification.userInfo objectForKey:@"RSSI"];
    self.labelRSSI.text = rssi.stringValue; // when RSSI read is complete, display it
}

// OLD FUNCTION: parse the received data using BLEDelegate protocol
-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
    NSData *d = [NSData dataWithBytes:data length:length];
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    self.label.text = s;
}

// NEW FUNCTION EXAMPLE: parse the received data from NSNotification
-(void) onBLEDidReceiveData:(NSNotification *)notification
{
    NSData* d = [[notification userInfo] objectForKey:@"data"];
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    NSArray *array = [s componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([array[0]  isEqual: @"BTN"]) {
        self.label.text = s;
        if ([array[1] isEqual:@"HOLD"]) {
            NSLog(@"play!");
            [self playMP3];
        }
    } else if ([array[0]  isEqual: @"POT"]) {
        NSLog(@"%@", array[1]);
        float volume = (float)([array[1] integerValue]/4) / 255.0;
        NSLog(@"VOLUME: %.f", volume);
        [audioPlayer setVolume:volume];
        [self.volumeView setProgress:volume];
        NSString *ds = [NSString stringWithFormat: @"%.f", (float)([array[1] integerValue]/4)];
        self.label2.text = ds;
    }
    
}

// we disconnected, stop running
- (void) onBLEDidDisconnect:(NSNotification *)notification
{
    //CHANGE 5.b: remove all instances of the button at top
//    [self.buttonConnect setTitle:@"Connect" forState:UIControlStateNormal];
    
    [rssiTimer invalidate];
}

//CHANGE 7: create function called from "BLEDidConnect" notification (you can change the function below)
// in this function, update a label on the UI to have the name of the active peripheral
// you might be interested in the following method:
// NSString *deviceName =[notification.userInfo objectForKey:@"deviceName"];
// now just wait to send or receive
-(void) onBLEDidConnect:(NSNotification *)notification
{
    //CHANGE 5.a: Remove all usage of the connect button and remove from storyboard
    [self.spinner stopAnimating];
//    [self.buttonConnect setTitle:@"Disconnect" forState:UIControlStateNormal];
    NSString *deviceName =[notification.userInfo objectForKey:@"deviceName"];
    self.peripheralLabel.text = deviceName;
    
    // Schedule to read RSSI every 1 sec.
    rssiTimer = [NSTimer scheduledTimerWithTimeInterval:(float)1.0 target:self selector:@selector(readRSSITimer:) userInfo:nil repeats:YES];
}



#pragma mark - UI operations storyboard
- (IBAction)BLEShieldSend:(id)sender
{
    
    //Note: this function only needs a name change, the BLE writing does not change
    NSString *s;
    NSData *d;
    
    if (self.textField.text.length > 16)
        s = [self.textField.text substringToIndex:16];
    else
        s = self.textField.text;

    s = [NSString stringWithFormat:@"%@\r\n", s];
    d = [s dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.bleShield write:d];
}


// CHANGE 1.b: change this as you no longer need to search for perpipherals in this view controller
//- (IBAction)BLEShieldScan:(id)sender
//{
//    // disconnect from any peripherals
//    if (bleShield.activePeripheral)
//        if(bleShield.activePeripheral.state == CBPeripheralStateConnected)
//        {
//            [[bleShield CM] cancelPeripheralConnection:[bleShield activePeripheral]];
//            return;
//        }
//    
//    // set peripheral to nil
//    if (bleShield.peripherals)
//        bleShield.peripherals = nil;
//    
//    //start search for peripherals with a timeout of 3 seconds
//    // this is an asynchronous call and will return before search is complete
//    [bleShield findBLEPeripherals:3];
//    
//    // after three seconds, try to connect to first peripheral
//    [NSTimer scheduledTimerWithTimeInterval:(float)3.0
//                                     target:self
//                                   selector:@selector(connectionTimer:)
//                                   userInfo:nil
//                                    repeats:NO];
//    
//    // give connection feedback to the user
//    [self.spinner startAnimating];
//}

// CHANGE 1.c: change this as you no longer need to create the connection in this view controller
// Called when scan period is over to connect to the first found peripheral
//-(void) connectionTimer:(NSTimer *)timer
//{
//    if(bleShield.peripherals.count > 0)
//    {
//        // connect to the first found peripheral
//        [bleShield connectPeripheral:[bleShield.peripherals objectAtIndex:0]];
//    }
//    else
//    {
//        [self.spinner stopAnimating];
//    }
//}
- (IBAction)switched:(id)sender {
    UISwitch *mySwitch = (UISwitch *)sender;
    if ([mySwitch isOn]) {
        NSLog(@"its on!");
        NSString *s;
        NSData *d;
        
        s = @"Light ON;";
        
        s = [NSString stringWithFormat:@"%@\r\n", s];
        d = [s dataUsingEncoding:NSUTF8StringEncoding];
        
        [self.bleShield write:d];
    } else {
        NSLog(@"its off!");
        NSString *s;
        NSData *d;
        
        s = @"Light OFF;";
        
        s = [NSString stringWithFormat:@"%@\r\n", s];
        d = [s dataUsingEncoding:NSUTF8StringEncoding];
        
        [self.bleShield write:d];
    }
}

- (IBAction)servoChange:(id)sender {
    UISlider *slider = (UISlider *)sender;
    NSInteger sliderValue;
    sliderValue = (int)[slider value];
    NSString *s;
    NSData *d;
    
    
    s = [NSString stringWithFormat: @"Servo %ld;", (long)sliderValue];

    
    s = [NSString stringWithFormat:@"%@\r\n", s];
    d = [s dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.bleShield write:d];

    
}



@end
