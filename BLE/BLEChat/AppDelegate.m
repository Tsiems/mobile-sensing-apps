//
//  AppDelegate.m
//  BLEChat
//
//  Created by Cheong on 15/8/12.
//  Copyright (c) 2012 RedBear Lab., All rights reserved.
//

#import "AppDelegate.h"



@implementation AppDelegate


#pragma mark - BLE Delegate
-(void) bleDidConnect
{
    NSLog(@"BLE Connected");
    [[NSNotificationCenter defaultCenter] postNotificationName:kBleConnectNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self.bleShield.activePeripheral.name,@"deviceName", nil]];
}
-(void) bleDidDisconnect
{
    NSLog(@"BLE Disconnected");
    [[NSNotificationCenter defaultCenter] postNotificationName:kBleDisconnectNotification object:self] ;
}
-(void) bleDidUpdateRSSI:(NSNumber *) rssi
{
    // note that this does not run consistently in the app delegate
    NSLog(@"BLE Updated RSSI");
    [[NSNotificationCenter defaultCenter] postNotificationName:kBleRSSINotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:rssi,@"RSSI", nil]];
}
-(void) bleDidReceiveData:(unsigned char *) data length:(int) length
{
    NSLog(@"BLE ReceivedData");
    
    NSData* myData = [NSData dataWithBytes:data length:length];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kBleReceivedDataNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys: myData, @"data",nil]] ;
    
}
#pragma mark - Application Delegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    self.bleShield = [[BLE alloc] init];
    [self.bleShield controlSetup];
    self.bleShield.delegate = self;
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
