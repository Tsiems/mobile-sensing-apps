//
//  ViewController.h
//  BLEChat
//
//  Created by Cheong on 15/8/12.
//  Copyright (c) 2012 RedBear Lab., All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "BLE.h"
#import "AppDelegate.h"


//CHANGE 2a: No longer need to be a delegate
@interface ViewController : UIViewController <BLEDelegate> {
    
    AVAudioPlayer* audioPlayer;
}

@property (weak, nonatomic) IBOutlet UILabel *label2;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *labelRSSI;
@property (strong, nonatomic) BLE* bleShield;
@property (weak, nonatomic) IBOutlet UIProgressView *volumeView;

@end
