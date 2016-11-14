//
//  ViewController.swift
//  AirDrummer
//
//  Created by Danh Nguyen on 11/7/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController, URLSessionTaskDelegate {

    @IBOutlet weak var instrumentLabel: UILabel!
    @IBOutlet weak var snareButton: UIButton!
    @IBOutlet weak var hihatbutton: UIButton!
    @IBOutlet weak var dsidLabel: UITextField!
    
    var session = URLSession()
    let cmMotionManager = CMMotionManager()
    let backQueue = OperationQueue()
    var ringBuffer = RingBuffer()
    var orientationBuffer = RingBuffer()
    let magValue = 1.0
    var numDataPoints = 0
    var timer = Timer()
    var bufferChanged:Bool = false
    var counterVal = 0
    let instruments = ["Hi-Hat", "Snare"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print()
        // setup URLSession 
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        self.session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        self.startCMMonitoring()
        
//        self.timer = Timer.scheduledTimer(timeInterval: 1,
//                             target: self,
//                             selector: #selector(self.updateTime),
//                             userInfo: nil,
//                             repeats: true)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        /// stop timer when leave screen
        self.timer.invalidate()
        self.cmMotionManager.stopDeviceMotionUpdates()
        super.viewWillDisappear(animated)
    }
    
    func updateTime() {
//        print("Sup")
//        if self.bufferChanged {
//            self.counterVal = 0
//            self.bufferChanged = false
//            print("buffer changed")
//        } else {
//            self.counterVal += 1
//            if counterVal >= 2 {
//                self.ringBuffer = RingBuffer()
//                self.orientationBuffer = RingBuffer()
//                print("emptied ring buffer")
//                self.counterVal = 0
//                prepareForSample(instrumentName: instruments[self.currentInstrument])
//            }
//        }
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
        
        self.orientationBuffer.addNewData(Float((motion?.attitude.pitch)!), withY: Float((motion?.attitude.roll)!), withZ: Float((motion?.attitude.yaw)!))
        
        let mag = fabs((motion?.userAcceleration.x)!)+fabs((motion?.userAcceleration.y)!)+fabs((motion?.userAcceleration.z)!)
        
        if(mag > self.magValue) {
            print(mag)
            bufferChanged = true
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
        let data = self.ringBuffer.getDataAsVector() as NSArray
        
        if data[0] as! Double == 0.0 {
            print("not full full")
        } else {
            
            //get the FFT of both buffers and add them up for feature data
            let fftVector = (self.ringBuffer.getDataAsVector()+self.orientationBuffer.getDataAsVector()) as NSArray
            
            self.sendFeatureArray(data: fftVector, label: self.instrumentLabel.text!)
            //self.sendFeatureArray(data: data, label: self.instrumentLabel.text!)
        }
    }
    
    func postFeatureHandler(data:Data?, urlResponse:URLResponse?, error:Error?) -> Void{
        if(!(error != nil)){
            print(urlResponse!)
            let responseData = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
            print(responseData ?? "No data")
            
        } else{
            print(error!)
        }

    }
    
    func sendFeatureArray(data:NSArray, label:String) {
        let baseUrl = "\(SERVER_URL)/AddDataPoint"
        let postUrl = NSURL(string: baseUrl)
        self.numDataPoints = self.numDataPoints + 1
        
        
        let jsonUpload:NSDictionary = ["feature": data, "label": label, "dsid": DSID]
        
        let requestBody = try! JSONSerialization.data(withJSONObject: jsonUpload, options: JSONSerialization.WritingOptions.prettyPrinted)
        var request = URLRequest(url: postUrl as! URL)
        request.httpBody = requestBody
        request.httpMethod = "POST"
        
        
        let postTask = self.session.dataTask(with: request, completionHandler: postFeatureHandler)
        
        
        
        postTask.resume()
        print(self.numDataPoints)
    }
    
    @IBAction func sendUpdate(_ sender: Any) {
        let baseUrl = "\(SERVER_URL)/UpdateModel"
        let postUrl = NSURL(string: baseUrl)
        self.numDataPoints = self.numDataPoints + 1
        
        
        let jsonUpload:NSDictionary = ["dsid": DSID]
        
        let requestBody = try! JSONSerialization.data(withJSONObject: jsonUpload, options: JSONSerialization.WritingOptions.prettyPrinted)
        var request = URLRequest(url: postUrl as! URL)
        request.httpBody = requestBody
        request.httpMethod = "POST"
        
        
        let postTask = self.session.dataTask(with: request, completionHandler: postFeatureHandler)
        
        
        
        postTask.resume()
    }
    
    @IBAction func trainSnare(_ sender: Any) {
        self.hihatbutton.isEnabled = true
        self.snareButton.isEnabled = false
        prepareForSample(instrumentName: "Snare")
    }
    
    @IBAction func trainHiHat(_ sender: Any) {
        self.hihatbutton.isEnabled = false
        self.snareButton.isEnabled = true
        prepareForSample(instrumentName: "Hi-Hat")
    }
    
    @IBAction func updateDSID(_ sender: Any) {
        DSID = Int(self.dsidLabel.text!)!
        view.endEditing(true)
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    

    
}

