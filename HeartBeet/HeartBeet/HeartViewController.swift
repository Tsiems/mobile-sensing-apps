//
//  HeartViewController.swift
//  HeartBeet
//
//  Created by Danh Nguyen on 10/7/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import GLKit

class HeartViewController: GLKViewController {

    @IBOutlet weak var graph: UIView!
    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    var BUFFER_SIZE = 200
//    lazy var graphHelper:SMUGraphHelper = SMUGraphHelper(controller: self,
//                                                    preferredFramesPerSecond: 10,
//                                                    numGraphs: 1,
//                                                    plotStyle: PlotStyleSeparated,
//                                                    maxPointsPerGraph: 200)
    let pinchFilterIndex = 2
    var detector:CIDetector! = nil
    let bridge = OpenCVBridgeSub()
    var displayGraph = false
    
    //MARK: Outlets in view
    @IBOutlet weak var flashSlider: UISlider!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        self.setupFilters()
        
        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(AVCaptureDevicePosition.back)
        self.videoManager.setPreset("AVCaptureSessionPresetMedium")
        
        // create dictionary for face detection
        // HINT: you need to manipulate these proerties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyLow,CIDetectorTracking:true] as [String : Any]
        
        // setup a face detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                   context: self.videoManager.getCIContext(), // perform on the GPU is possible
            options: (optsDetector as [String : AnyObject]))
        
        self.videoManager.setProcessingBlock(self.processImage)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.toggleButton(notification:)), name: NSNotification.Name(rawValue: "toggleOn"), object: nil)
        
        self.graph.isHidden = true
        
    }
    
    func toggleButton(notification: NSNotification) {
        let userInfo:Dictionary<String, AnyObject> = notification.userInfo as! Dictionary<String,AnyObject>
        let toggleOn = userInfo["toggleOn"]! as! String
        if toggleOn == "On" {
            DispatchQueue.main.async{
                self.flashButton.isEnabled = false
                self.cameraButton.isEnabled = false
            }
            
        } else {
            DispatchQueue.main.async{
                self.flashButton.isEnabled = true
                self.cameraButton.isEnabled = true
            }
        }
    }
    
    @IBAction func displayGraphButtonAction(_ sender: AnyObject) {
        toggleGraphDisplay()
    }
    func toggleGraphDisplay() {
        if self.displayGraph == false {
            self.graph.isHidden = false
            self.displayGraph = true
        } else {
            self.graph.isHidden = true
            self.displayGraph = false
        }
    }
    
    
    //MARK: Process image output
    func processImage(_ inputImage:CIImage) -> CIImage{
        
        // if no faces, just return original image
        // if f.count == 0 { return inputImage }
        
        var retImage = inputImage
        
        self.bridge.setTransforms(self.videoManager.transform)
        self.bridge.setImage(retImage,
                             withBounds: retImage.extent,
                             andContext: self.videoManager.getCIContext())
        
        self.bridge.processImage()
        retImage = self.bridge.getImageComposite() // get back opencv processed part of the image (overlayed on original)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "bridge"), object: nil, userInfo: ["bridge": self.bridge])
        return retImage
    }
    
    //MARK: Setup filtering
    func setupFilters(){
        filters = []
        
        let filterPinch = CIFilter(name:"CIBumpDistortion")!
        filterPinch.setValue(-0.5, forKey: "inputScale")
        filterPinch.setValue(75, forKey: "inputRadius")
        filters.append(filterPinch)
        
        //        let filterPosterize = CIFilter(name:"CIColorPosterize")!
        //        filters.append(filterPosterize)
    }
    
    
    //MARK: Apply filters and apply feature detectors
    func applyFiltersToFaces(_ inputImage:CIImage,features:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        var filterCenter = CGPoint()
        
        for f in features {
            //set where to apply filter
            filterCenter.x = f.bounds.midX
            filterCenter.y = f.bounds.midY
            
            //do for each filter (assumes all filters have property, "inputCenter")
            for filt in filters{
                
                let inputKeys = filt.inputKeys
                
                filt.setValue(retImage, forKey: kCIInputImageKey)
                
                if inputKeys.contains("inputCenter") {
                    filt.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
                }
                // could also manipualte the radius of the filter based on face size!
                retImage = filt.outputImage!
            }
        }
        return retImage
    }
    
    func getFaces(_ img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        //let optsFace = [CIDetectorImageOrientation:self.videoManager.getImageOrientationFromUIOrientation(UIApplication.sharedApplication().statusBarOrientation)]
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation]
        
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
    //MARK: Convenience Methods for UI Flash and Camera Toggle
    @IBAction func flash(_ sender: AnyObject) {
        if(self.videoManager.toggleFlash()){
            self.flashSlider.value = 1.0
        }
        else{
            self.flashSlider.value = 0.0
        }
    }
    
    @IBAction func switchCamera(_ sender: AnyObject) {
        self.videoManager.toggleCameraPosition()
    }
    
    @IBAction func setFlashLevel(_ sender: UISlider) {
        if(sender.value>0.0){
            self.videoManager.turnOnFlashwithLevel(sender.value)
        }
        else if(sender.value==0.0){
            self.videoManager.turnOffFlash()
        }
    }

}
