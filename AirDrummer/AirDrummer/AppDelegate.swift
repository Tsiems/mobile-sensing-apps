//
//  AppDelegate.swift
//  AirDrummer
//
//  Created by Danh Nguyen on 11/7/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit
import CoreData
import CoreMotion


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, URLSessionTaskDelegate {

    var window: UIWindow?
    
    // adding motion and url session vars 
    var session = URLSession()
    let cmMotionManager = CMMotionManager()
    let backQueue = OperationQueue()
    let ringBuffer = RingBuffer()
    let magValue = 0.1
    var instrument = "Hi Hats"
    
    var playingMode = false


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // setup URLSession
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        self.session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        self.startCMMonitoring()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "AirDrummer")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Getting and sending motion data to web server
    
    func handleMotion(motion:CMDeviceMotion?, error:Error?)->Void{
        self.ringBuffer.addNewData(Float((motion?.userAcceleration.x)!), withY: Float((motion?.userAcceleration.y)!), withZ: Float((motion?.userAcceleration.z)!))
        let mag = fabs((motion?.userAcceleration.x)!)+fabs((motion?.userAcceleration.y)!)+fabs((motion?.userAcceleration.z)!)
        if(mag > self.magValue) {
            print(mag)
            self.backQueue.addOperation({() -> Void in self.motionEventOccurred()})
        }
    }
    
    func startCMMonitoring(){
        if self.cmMotionManager.isDeviceMotionAvailable {
            // update from this queue
            self.cmMotionManager.deviceMotionUpdateInterval = UPDATE_INTERVAL
            self.cmMotionManager.startDeviceMotionUpdates(to: backQueue, withHandler:self.handleMotion)
        }
    }
    
    func motionEventOccurred() {
        // if we are in training mode, send data with labels
        if (!self.playingMode) {
            self.sendFeatureArray(data: self.ringBuffer.getDataAsVector() as NSArray, label: self.instrument)
        }
        // if we are in playing mode, send data for predictions
    }
    
    func postFeatureHandler(data:Data?, urlResponse:URLResponse?, error:Error?) -> Void{
        if(!(error != nil)){
            print(urlResponse!)
            let responseData = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
            print(responseData)
            
        } else{
            print(error!)
        }
        
    }
    
    func sendFeatureArray(data:NSArray, label:String) {
        let baseUrl = "\(SERVER_URL)/AddDataPoint"
        let postUrl = NSURL(string: baseUrl)
        
        let jsonUpload:NSDictionary = ["feature": data, "label": label]
        
        let requestBody = try! JSONSerialization.data(withJSONObject: jsonUpload, options: JSONSerialization.WritingOptions.prettyPrinted)
        var request = URLRequest(url: postUrl as! URL)
        request.httpBody = requestBody
        request.httpMethod = "POST"
        
        
        let postTask = self.session.dataTask(with: request, completionHandler: postFeatureHandler)
        
        postTask.resume()
    }


}

