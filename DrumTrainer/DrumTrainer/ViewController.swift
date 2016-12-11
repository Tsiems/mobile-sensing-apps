//
//  ViewController.swift
//  DrumTrainer
//
//  Created by Danh Nguyen on 12/6/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit
import CoreMotion 

class ViewController: UIViewController, URLSessionTaskDelegate {
    
    @IBOutlet weak var gestureLabel: UILabel!
    @IBOutlet weak var firstButton: UIButton!
    @IBOutlet weak var secondButton: UIButton!
    @IBOutlet weak var thirdButton: UIButton!
    @IBOutlet weak var fourthButton: UIButton!
    @IBOutlet weak var fifthButton: UIButton!
    @IBOutlet weak var dsidLabel: UITextField!
    
    var session = URLSession()
    let cmMotionManager = CMMotionManager()
    let backQueue = OperationQueue()
    var ringBuffer = RingBuffer()
    var orientationBuffer = RingBuffer()
    let magValue = 1.0
    var numDataPoints = 0
    
    let gestures = ["Gesture 1", "Gesture 2", "Gesture 3", "Gesture 4", "Gesture 5"]
    
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
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.cmMotionManager.stopDeviceMotionUpdates()
        super.viewWillDisappear(animated)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareForSample(gestureName:String) {
        self.gestureLabel.text = "\(gestureName)"
        
        let fftVector = (self.orientationBuffer.getDataAsVector()) as NSArray
        self.sendFeatureArray(data: fftVector, label: self.gestureLabel.text!)
    }
    
    
    func handleMotion(motion:CMDeviceMotion?, error:Error?)->Void{
        self.ringBuffer.addNewData(Float((motion?.userAcceleration.x)!), withY: Float((motion?.userAcceleration.y)!), withZ: Float((motion?.userAcceleration.z)!))
//
        self.orientationBuffer.addNewData(Float((motion?.attitude.pitch)!), withY: Float((motion?.attitude.roll)!), withZ: Float((motion?.attitude.yaw)!))
        
//        let mag = fabs((motion?.userAcceleration.x)!)+fabs((motion?.userAcceleration.y)!)+fabs((motion?.userAcceleration.z)!)
//        
//        if(mag > self.magValue) {
//            print(mag)
//            self.backQueue.addOperation({() -> Void in self.motionEventOccurred()})
//        }
    }
    
    func startCMMonitoring(){
        if self.cmMotionManager.isDeviceMotionAvailable {
            // update from this queue
            self.cmMotionManager.deviceMotionUpdateInterval = UPDATE_INTERVAL
            self.cmMotionManager.startDeviceMotionUpdates(to: backQueue, withHandler:self.handleMotion)
        }
    }
    
    func motionEventOccurred() {
//        let data = self.ringBuffer.getDataAsVector() as NSArray
//        
//        if data[0] as! Double == 0.0 {
//            print("not full full")
//        } else {
//            
//            //get the FFT of both buffers and add them up for feature data
//            let fftVector = (self.orientationBuffer.getDataAsVector()) as NSArray
//            
//            self.sendFeatureArray(data: fftVector, label: self.gestureLabel.text!)
//            //self.sendFeatureArray(data: data, label: self.gestureLabel.text!)
//        }
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
    
    @IBAction func trainFirst(_ sender: Any) {
//        self.firstButton.isEnabled = false
//        self.secondButton.isEnabled = true
//        self.thirdButton.isEnabled = true
//        self.fourthButton.isEnabled = true
//        self.fifthButton.isEnabled = true
        prepareForSample(gestureName: gestures[0])
    }
    
    @IBAction func trainSecond(_ sender: Any) {
//        self.firstButton.isEnabled = true
//        self.secondButton.isEnabled = false
//        self.thirdButton.isEnabled = true
//        self.fourthButton.isEnabled = true
//        self.fifthButton.isEnabled = true
        prepareForSample(gestureName: gestures[1])
    }
    
    @IBAction func trainThird(_ sender: Any) {
//        self.firstButton.isEnabled = true
//        self.secondButton.isEnabled = true
//        self.thirdButton.isEnabled = false
//        self.fourthButton.isEnabled = true
//        self.fifthButton.isEnabled = true
        prepareForSample(gestureName: gestures[2])
    }

    @IBAction func trainFourth(_ sender: Any) {
//        self.firstButton.isEnabled = true
//        self.secondButton.isEnabled = true
//        self.thirdButton.isEnabled = true
//        self.fourthButton.isEnabled = false
//        self.fifthButton.isEnabled = true
        prepareForSample(gestureName: gestures[3])
    }

    @IBAction func trainFifth(_ sender: Any) {
//        self.firstButton.isEnabled = true
//        self.secondButton.isEnabled = true
//        self.thirdButton.isEnabled = true
//        self.fourthButton.isEnabled = true
//        self.fifthButton.isEnabled = false
        prepareForSample(gestureName: gestures[4])
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


