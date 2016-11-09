//
//  ViewController.swift
//  AirDrummer
//
//  Created by Danh Nguyen on 11/7/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit
import CoreMotion

let SERVER_URL = "http://10.8.110.111:8000"
let UPDATE_INTERVAL = 1/10.0

class ViewController: UIViewController, URLSessionTaskDelegate {

    @IBOutlet weak var instrumentLabel: UILabel!
    
    var session = URLSession()
    let cmMotionManager = CMMotionManager()
    let backQueue = OperationQueue()
    let ringBuffer = RingBuffer()
    let magValue = 0.1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // setup URLSession 
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        self.session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        self.startCMMonitoring()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareForSample(instrumentName:String) {
        self.instrumentLabel.text = "Play \(instrumentName)"
    }

    
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
        self.sendFeatureArray(data: self.ringBuffer.getDataAsVector() as NSArray, label: self.instrumentLabel.text!)
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

