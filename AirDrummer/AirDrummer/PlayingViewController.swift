//
//  SpriteViewController.swift
//  AirDrummer
//
//  Created by Danh Nguyen on 11/7/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit
import CoreMotion
import AVFoundation

class PlayingViewController: UIViewController, URLSessionTaskDelegate {
    
    var session = URLSession()
    let cmMotionManager = CMMotionManager()
    let backQueue = OperationQueue()
    var ringBuffer = RingBuffer()
    var orientationBuffer = RingBuffer()
    let magValue = 1.0
    var numDataPoints = 0
    
    var hihatPlayer = AVAudioPlayer()
    var snarePlayer = AVAudioPlayer()
    var kickdrumPlayer = AVAudioPlayer()


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // setup URLSession
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        // set up sound
        let hihatSound = NSURL(fileURLWithPath: Bundle.main.path(forResource: "hihat", ofType: "wav")!)
        
        do {
            self.hihatPlayer = try AVAudioPlayer(contentsOf: hihatSound as URL)
            self.hihatPlayer.prepareToPlay()
        }
        catch {
            //
        }
        
        let kickdrumSound = NSURL(fileURLWithPath: Bundle.main.path(forResource: "kickdrum", ofType: "wav")!)
        
        do {
            self.kickdrumPlayer = try AVAudioPlayer(contentsOf: kickdrumSound as URL)
            self.kickdrumPlayer.prepareToPlay()
        }
        catch {
            //
        }

        
        let snareSound = NSURL(fileURLWithPath: Bundle.main.path(forResource: "snare", ofType: "wav")!)
        
        do {
            self.snarePlayer = try AVAudioPlayer(contentsOf: snareSound as URL)
            self.snarePlayer.prepareToPlay()
        }
        catch {
            //
        }

        
        self.hihatPlayer.play()
        self.snarePlayer.play()
        self.kickdrumPlayer.play()
        
        self.session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        self.startCMMonitoring()
        
    

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.cmMotionManager.stopDeviceMotionUpdates()
    }
    

    func handleMotion(motion:CMDeviceMotion?, error:Error?)->Void{
        self.ringBuffer.addNewData(Float((motion?.userAcceleration.x)!), withY: Float((motion?.userAcceleration.y)!), withZ: Float((motion?.userAcceleration.z)!))
        
        self.orientationBuffer.addNewData(Float((motion?.attitude.pitch)!), withY: Float((motion?.attitude.roll)!), withZ: Float((motion?.attitude.yaw)!))
        
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
        let data = self.ringBuffer.getDataAsVector() as NSArray
        if data[0] as! Double == 0.0 {
            print("not full full")
        } else {
            
            //get the FFT of both buffers and add them up for prediction data
            self.getPredictionData(data: (self.ringBuffer.getFFT().getDataAsVector()+self.orientationBuffer.getFFT().getDataAsVector()) as NSArray )
            
            print(self.orientationBuffer.getFFT().getDataAsVector())
            print(self.orientationBuffer.getDataAsVector())
//            self.getPredictionData(data: data)
            
        }
    }
    
    func postFeatureHandler(data:Data?, urlResponse:URLResponse?, error:Error?) -> Void{
        if(!(error != nil)){
            print(urlResponse!)
            if let responseData = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, Any> {
                print(responseData)
                
                if let prediction = responseData["prediction"] as? String {
                    switch prediction {
                    case "['Play Hi-Hat']":
                        self.hihatPlayer.play()
                    case "['Play Snare']":
                        self.snarePlayer.play()
                    case "['Play Kick Drum']":
                        self.kickdrumPlayer.play()
                    default:
                        print("UNKNOWN")
                    }
                }
                else {
                    print("could not convert prediction to string")
                }
            }
            else {
                print("Could not convert to dict")
            }
            
        } else{
            print(error!)
        }
        
    }
    
    func getPredictionData(data:NSArray) {
        let baseUrl = "\(SERVER_URL)/PredictOne"
        let postUrl = NSURL(string: baseUrl)
        self.numDataPoints = self.numDataPoints + 1
        
        
        let jsonUpload:NSDictionary = ["feature": data, "dsid": DSID]
        
        let requestBody = try! JSONSerialization.data(withJSONObject: jsonUpload, options: JSONSerialization.WritingOptions.prettyPrinted)
        var request = URLRequest(url: postUrl as! URL)
        request.httpBody = requestBody
        request.httpMethod = "POST"
        
        
        let postTask = self.session.dataTask(with: request, completionHandler: postFeatureHandler)
        
        
        
        postTask.resume()
        print(self.numDataPoints)
    }


}
