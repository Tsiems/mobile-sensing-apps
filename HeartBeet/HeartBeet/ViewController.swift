//
//  ViewController.swift
//  ImageLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import AVFoundation
import QuartzCore

extension String {
    func image(withWidth w: CGFloat) -> UIImage {
        let size = CGSize(width: w+10, height: w+10)
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
//        UIColor.white.set()
        let rect = CGRect(origin: CGPoint.zero, size: size)
//        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        (self as NSString).draw(in: rect, withAttributes: [NSFontAttributeName: UIFont.systemFont(ofSize: w)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}


class ViewController: UIViewController   {

    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    var eyeFilters : [CIFilter]! = nil
    var mouthFilters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    let pinchFilterIndex = 2
    var detector:CIDetector! = nil
    let bridge = OpenCVBridge()
    // let bridge = OpenCVBridgeSub()
    
    //MARK: Outlets in view
    @IBOutlet weak var flashSlider: UISlider!
    @IBOutlet weak var stageLabel: UILabel!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        self.setupFilters()
        self.setupEyeFilters()
        self.setupMouthFilters()
        
        
        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(AVCaptureDevicePosition.front)
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
    
    //MARK: Process image output
    func processImage(_ inputImage:CIImage) -> CIImage{
        
        // detect faces
        let f = getFaces(inputImage)
        
        
        // if no faces, just return original image
        if f.count == 0 { return inputImage }
        
        var retImage = inputImage
        
        // if you just want to process on separate queue use this code
        // this is a NON BLOCKING CALL, but any changes to the image in OpenCV cannot be displayed real time
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { () -> Void in
//            self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
//            self.bridge.processImage()
//        }
        
        // use this code if you are using OpenCV and want to overwrite the displayed image via OpenCv
        // this is a BLOCKING CALL
//        self.bridge.setTransforms(self.videoManager.transform)
//        self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
//        self.bridge.processImage()
//        retImage = self.bridge.getImage()
        
        //HINT: you can also send in the bounds of the face to ONLY process the face in OpenCV
        // or any bounds to only process a certain bounding region in OpenCV
        
        
        switch self.bridge.processType {
        case 2:
            retImage = applyFiltersToFaces(retImage, features: f)
            break
        case 1:
            for face in f {
                
                //determine which emoji to display based on facial expression (eyes closed/smile)
                var emoji = "😐"
                
                if face.hasSmile && face.leftEyeClosed && face.rightEyeClosed {
                    emoji = "😆"
                }
                else if face.leftEyeClosed && face.rightEyeClosed {
                    emoji = "😣"
                }
                else if face.hasSmile {
                    emoji = "😁"
                }
                
                
                
                //create the emoji image and rotate it to form correctly
                var emojiImage = CIImage(image: emoji.image(withWidth: face.bounds.size.width/2))!
                let rotateFilt = CIFilter(name: "CIStraightenFilter", withInputParameters: ["inputImage":emojiImage,"inputAngle":1.57])!
                emojiImage = rotateFilt.outputImage!
                
                //make a composite filter to overlay the emoji over the original image
                let compositeFilt = CIFilter(name:"CISourceAtopCompositing")!
                let faceLocTransform = CGAffineTransform(translationX: face.bounds.origin.x-20, y: face.bounds.origin.y-5);
                compositeFilt.setValue(emojiImage.applying(faceLocTransform),forKey: "inputImage")
                compositeFilt.setValue(retImage, forKey: "inputBackgroundImage")
                
                //set the image the composite
                retImage = compositeFilt.outputImage!
            }
            break
        default:
            self.bridge.setTransforms(self.videoManager.transform)
            
            for face in f {
                self.bridge.setImage(retImage,
                                     withBounds: face.bounds,
                                     andContext: self.videoManager.getCIContext())
                self.bridge.setFeatures(face)
                self.bridge.processImage()
                retImage = self.bridge.getImageComposite() // get back opencv processed part of the image (overlayed on original)
            }
            break
        }
        
        
        
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
    
    //MARK: Setup Eye filtering
    func setupEyeFilters(){
        eyeFilters = []
        
        
        let filterTwirl = CIFilter(name:"CITwirlDistortion")!
        filterTwirl.setValue(30, forKey: "inputRadius")
        filterTwirl.setValue(2.0, forKey: "inputAngle")
        
        eyeFilters.append(filterTwirl)
    }
    
    func setupMouthFilters(){
        mouthFilters = []
        
        let filterPinch = CIFilter(name:"CIBumpDistortion")!
        filterPinch.setValue(0.5, forKey: "inputScale")
        filterPinch.setValue(60, forKey: "inputRadius")
        mouthFilters.append(filterPinch)
        
    }
    
    
    
    //MARK: Apply filters and apply feature detectors
    func applyFiltersToFaces(_ inputImage:CIImage,features:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        var filterCenter = CGPoint()
        
        
        
        
//        let ciImageSize = retImage.extent.size
//        var transform = CGAffineTransform(scaleX: 1, y: -1)
//        transform = transform.translatedBy(x: 0, y: -ciImageSize.height)
        
        for f in features {
            
            
            if f.hasSmile {
                let filt = CIFilter(name:"CIBloom")!
                filt.setValue(0.7, forKey: "inputIntensity")
                filt.setValue(retImage, forKey: kCIInputImageKey)
                retImage = filt.outputImage!
            }
            
            // Apply the transform to convert the coordinates
//            var faceViewBounds = f.bounds.applying(transform)
//            
//            let faceView = UIView(frame:faceViewBounds)
//            
//            faceView.backgroundColor = UIColor.blue
//            self.view.addSubview(faceView)
//
//            let context = CIContext()
//            let cgImg = context.createCGImage(retImage, from: retImage.extent)
        
            
            
            // Calculate the actual position and size of the rectangle in the image view
//            let viewSize = self.view.bounds.size
//            let scale = min(viewSize.width / ciImageSize.width,
//                            viewSize.height / ciImageSize.height)
//            let offsetX = (viewSize.width - ciImageSize.width * scale) / 2
//            let offsetY = (viewSize.height - ciImageSize.height * scale) / 2
//            
//            faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
//            faceViewBounds.origin.x += offsetX
//            faceViewBounds.origin.y += offsetY
//            
//            let faceBox = UIView(frame: faceViewBounds)
//            
//            faceBox.layer.borderWidth = 3
//            faceBox.layer.borderColor = UIColor.red.cgColor
//            faceBox.backgroundColor = UIColor.clear
//            self.view.addSubview(faceBox)
//
//            retImage.
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
            
            
            //apply eye filters to left eye
            if f.hasLeftEyePosition {
                
                //circle left eye if it's closed
                if f.hasSmile {
                    // do nothing
                }
                else if f.leftEyeClosed {
                    let filterLens = CIFilter(name:"CITorusLensDistortion")!
                    filterLens.setValue(f.bounds.width/8, forKey: "inputRadius")
                    filterLens.setValue(0.5, forKey: "inputRefraction")
                    filterLens.setValue(f.bounds.width/16, forKey: "inputWidth")
                    filterLens.setValue(CIVector(cgPoint: f.leftEyePosition), forKey: "inputCenter")
                    filterLens.setValue(retImage, forKey: kCIInputImageKey)
                    retImage = filterLens.outputImage!
                }
                else {
                    for filt in eyeFilters {
                        let inputKeys = filt.inputKeys
                        
                        filt.setValue(retImage, forKey: kCIInputImageKey)
                        
                        
                        if inputKeys.contains("inputCenter") {
                            filt.setValue(CIVector(cgPoint: f.leftEyePosition), forKey: "inputCenter")
                        }
                        
                        // could also manipualte the radius of the filter based on face size!
                        if inputKeys.contains("inputRadius") {
                            if f.hasRightEyePosition {
                                filt.setValue(f.bounds.width/8, forKey: "inputRadius")
                            }
                        }
                        
                        retImage = filt.outputImage!
                    }
                }
                
            }
            
            //apply eye filters to right eye
            if f.hasRightEyePosition {
                
                if f.hasSmile {
                    // do nothing
                }
                //circle right eye if it's closed
                else if f.rightEyeClosed {
                    let filterLens = CIFilter(name:"CITorusLensDistortion")!
                    filterLens.setValue(f.bounds.width/8, forKey: "inputRadius")
                    filterLens.setValue(0.5, forKey: "inputRefraction")
                    filterLens.setValue(f.bounds.width/16, forKey: "inputWidth")
                    filterLens.setValue(CIVector(cgPoint: f.rightEyePosition), forKey: "inputCenter")
                    filterLens.setValue(retImage, forKey: kCIInputImageKey)
                    retImage = filterLens.outputImage!
                }
                else {
                    for filt in eyeFilters {
                        let inputKeys = filt.inputKeys
                        
                        filt.setValue(retImage, forKey: kCIInputImageKey)
                        
                        if inputKeys.contains("inputCenter") {
                            filt.setValue(CIVector(cgPoint: f.rightEyePosition), forKey: "inputCenter")
                        }
                        // could also manipualte the radius of the filter based on face size!
                        if inputKeys.contains("inputRadius") {
                            if f.hasLeftEyePosition {
                                filt.setValue(f.bounds.width/8, forKey: "inputRadius")
                            }
                        }
                        retImage = filt.outputImage!
                    }
                }
                
                
            }
            
            //apply mouth filters
            if f.hasMouthPosition {
                for filt in mouthFilters {
                    let inputKeys = filt.inputKeys
                    
                    filt.setValue(retImage, forKey: kCIInputImageKey)
                    
                    if inputKeys.contains("inputCenter") {
                        filt.setValue(CIVector(cgPoint: f.mouthPosition), forKey: "inputCenter")
                    }
                    // could also manipualte the radius of the filter based on face size!
                    if inputKeys.contains("inputRadius") {
                        if f.hasLeftEyePosition {
                            filt.setValue(f.bounds.width/4, forKey: "inputRadius")
                        }
                    }
                    retImage = filt.outputImage!
                }
            }
            
        }
        return retImage
    }
    
    func getFaces(_ img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        //let optsFace = [CIDetectorImageOrientation:self.videoManager.getImageOrientationFromUIOrientation(UIApplication.sharedApplication().statusBarOrientation)]
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation, CIDetectorSmile:true,CIDetectorEyeBlink:true] as [String : Any]
        
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
    
    
    @IBAction func swipeRecognized(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case UISwipeGestureRecognizerDirection.left:
            self.bridge.processType += 1
        case UISwipeGestureRecognizerDirection.right:
            self.bridge.processType -= 1
        default:
            break
            
        }
        
        stageLabel.text = "Stage: \(self.bridge.processType)"

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

