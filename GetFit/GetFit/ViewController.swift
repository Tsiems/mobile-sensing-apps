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
    @IBOutlet weak var stepCountYesterdayLabel: UILabel!
    @IBOutlet weak var stepCountTodayLabel: UILabel!
    @IBOutlet weak var stepCountProgress: UIProgressView!
    
    //MARK: class variables
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    let motion = CMMotionManager()
    let motionQueue = OperationQueue()
    let numberToolbar: UIToolbar = UIToolbar()
    lazy var liveSteps: Float = {return 0.0}()
    lazy var yesterdaySteps: Float = {return 0.0}()
    lazy var todaySteps: Float = {return 0.0}()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateTodaySteps()
        self.updateYesterdaySteps()
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
    }
    
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
        self.stepCountProgress.progress = self.liveSteps / Float(goalNumber!)

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
            self.liveSteps = steps.floatValue
        }
        DispatchQueue.main.async(){
            self.stepCountTodayLabel.text = "\(self.liveSteps + self.todaySteps)"
            let goal = UserDefaults.standard.integer(forKey: "stepGoal")
            self.stepCountProgress.progress = (self.liveSteps + self.todaySteps) / Float(goal)
        }

    }
    
    func updateYesterdaySteps(){
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date()))
        let today = calendar.startOfDay(for: Date())
        self.pedometer.queryPedometerData(from: yesterday!, to: today, withHandler: self.handleYesterdayPedometer)
    }
    
    func handleYesterdayPedometer(pedData:CMPedometerData?, error:Error?){
        if let steps = pedData?.numberOfSteps {
            self.yesterdaySteps = steps.floatValue
            print("Yesterday's Steps: \(yesterdaySteps)")
        }
        DispatchQueue.main.async(){
            self.stepCountYesterdayLabel.text = "\(self.yesterdaySteps)"
        }
    }
    
    func updateTodaySteps(){
        let calendar = Calendar.current
        let todayBeginning = calendar.startOfDay(for: Date())
        self.pedometer.queryPedometerData(from: todayBeginning, to: Date(), withHandler: self.handleTodayPedometer)
    }
    
    func handleTodayPedometer(pedData:CMPedometerData?, error:Error?){
        if let steps = pedData?.numberOfSteps {
            self.todaySteps = steps.floatValue
            print("Today's Steps: \(todaySteps)")
        }
        DispatchQueue.main.async(){
            self.stepCountTodayLabel.text = "\(self.todaySteps)"
        }
    }

}

