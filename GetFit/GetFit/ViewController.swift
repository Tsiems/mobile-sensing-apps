//
//  ViewController.swift
//  GetFit
//
//  Created by Danh Nguyen on 9/27/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

//TODO: total steps resets on app close, you want to change that to call today's steps and yesterdays steps using NSCalendar and then passing in NSDate with relevant parameters instead of just using from now
//user goal should be in NSUserdefaults instead of a temp variable that gets thrown away on close

import UIKit
import CoreMotion

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var newGoalField: UITextField!
    @IBOutlet weak var stepCountLabel: UILabel!
    @IBOutlet weak var stepCountProgress: UIProgressView!
    
    //MARK: class variables
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    let motion = CMMotionManager()
    var totalSteps: Float = 0.0
    let motionQueue = OperationQueue()
    let numberToolbar: UIToolbar = UIToolbar()
    var timer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.totalSteps = 0.0
        self.startActivityMonitoring()
        self.startPedometerMonitoring()
        self.startMotionUpdates()
        
        if UserDefaults.standard.object(forKey: "stepGoal") == nil {
            UserDefaults.standard.set(100, forKey: "stepGoal")
            print("set goal 100")
            goalLabel.text = "Step Goal: \(100)"
        } else {
            let number = UserDefaults.standard.integer(forKey: "stepGoal")
            goalLabel.text = "Step Goal: \(number)"
        }
        
        self.newGoalField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        numberToolbar.barStyle = UIBarStyle.black
        numberToolbar.tintColor = UIColor.white
        numberToolbar.items=[
            UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ViewController.dismissKeyboard)),
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Apply", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ViewController.returnSetGoal))
        ]
        
        numberToolbar.sizeToFit()
        
        numberToolbar.sizeToFit()
        
        self.newGoalField.inputAccessoryView = numberToolbar
        
//        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
    }
    
//    func update() {
//        DispatchQueue.main.async(){
//            self.stepCountLabel.text = "\(self.totalSteps)"
//            let goal = UserDefaults.standard.integer(forKey: "stepGoal")
//            self.stepCountProgress.progress = self.totalSteps / Float(goal)
//        }
//
//    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func returnSetGoal() {
        setGoal(self)
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == self.newGoalField {
            setGoal(self)
            self.view.endEditing(true)
        }
        
        
        
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @IBAction func setGoal(_ sender: AnyObject) {
        let goal = self.newGoalField.text!
        let goalNumber = Int(goal)
        UserDefaults.standard.set(goalNumber!, forKey: "stepGoal")
        goalLabel.text = "Step Goal: \(goalNumber!)"
        self.stepCountProgress.progress = self.totalSteps / Float(goalNumber!)

    }
    
    // MARK: Raw Motion Functions
    func startMotionUpdates(){
        // some internal inconsistency here: we need to ask the device manager for device
        if self.motion.isDeviceMotionAvailable{
            self.motion.startDeviceMotionUpdates(to: motionQueue, withHandler: self.handleMotion)
        }
    }
    
    func handleMotion(motionData:CMDeviceMotion?, error:Error?){
        if let gravity = motionData?.gravity {
            let rotation = atan2(gravity.x, gravity.y) - M_PI
            //UI element update
            //self.isWalking.transform = CGAffineTransformMakeRotation(CGFloat(rotation))
        }
    }
    
    // MARK: Activity Functions
    func startActivityMonitoring(){
        // is activity is available
        if CMMotionActivityManager.isActivityAvailable(){
            // update from this queue
            self.activityManager.startActivityUpdates(to: motionQueue, withHandler: self.handleActivity)
        }
        
    }
    
    func handleActivity(activity:CMMotionActivity?)->Void{
        // unwrap the activity and disp
        if let unwrappedActivity = activity {
            //DispatchQueue.main.async(){} // for UI update, use main queue
            print("Walking: \(unwrappedActivity.walking)\n Still: \(unwrappedActivity.stationary)")
        }
    }
    
    // MARK: Pedometer Functions
    func startPedometerMonitoring(){
        //separate out the handler for better readability
        if CMPedometer.isStepCountingAvailable(){
            pedometer.startUpdates(from: NSDate() as Date, withHandler: self.handlePedometer)
        }
    }
    
    //ped handler
    func handlePedometer(pedData:CMPedometerData?, error:Error?){
        if let steps = pedData?.numberOfSteps {
            self.totalSteps = steps.floatValue
        }
        DispatchQueue.main.async(){
            self.stepCountLabel.text = "\(self.totalSteps)"
            let goal = UserDefaults.standard.integer(forKey: "stepGoal")
            self.stepCountProgress.progress = self.totalSteps / Float(goal)
        }

    }

}

