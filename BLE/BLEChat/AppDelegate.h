//
//  AppDelegate.h
//  BLEChat
//
//  Created by Cheong on 15/8/12.
//  Copyright (c) 2012 RedBear Lab., All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"

#define kBleConnectNotification @"BLEDidConnect"
#define kBleDisconnectNotification @"BLEDidDisconnect"
#define kBleRSSINotification @"BLEUpdatedRSSI"
#define kBleReceivedDataNotification @"BLEReceievedData"

@interface AppDelegate : UIResponder <UIApplicationDelegate,BLEDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) BLE* bleShield;


@end
