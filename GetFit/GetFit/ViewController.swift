//
//  ViewController.swift
//  GetFit
//
//  Created by Danh Nguyen on 9/27/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var newGoalField: UITextField!
    @IBOutlet weak var stepCountYesterdayLabel: UILabel!
    @IBOutlet weak var stepCountTodayLabel: UILabel!
    @IBOutlet weak var stepCountProgress: UIProgressView!
    @IBOutlet weak var activityStatusLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var congratsView: UIView!
    
    //MARK: class variables
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    let motion = CMMotionManager()
    let motionQueue = OperationQueue()
    let numberToolbar: UIToolbar = UIToolbar()
    lazy var yesterdaySteps: Float = {return 0.0}()
    lazy var todaySteps: Float = {return 0.0}()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.congratsView.isHidden = true
        
        self.updateYesterdaySteps()
        self.startActivityMonitoring()
        self.startPedometerMonitoring()
        
        if UserDefaults.standard.object(forKey: "stepGoal") == nil {
            UserDefaults.standard.set(100, forKey: "stepGoal")
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
        let goalNumber = (Int(goal))
        if (goalNumber != nil){
            UserDefaults.standard.set(goalNumber!, forKey: "stepGoal")
            goalLabel.text = "Step Goal: \(goalNumber!)"
            self.newGoalField.placeholder = "New Goal"
            self.stepCountProgress.progress = (self.todaySteps) / Float(goalNumber!)
            if(Float(goalNumber!) > self.todaySteps) {
                self.congratsView.isHidden = true
            } else {
                self.congratsView.isHidden = false
            }
        }
        else{
            self.newGoalField.text = nil
            self.newGoalField.placeholder = "Please input a valid goal"
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
            var activityString = "Status: "
            switch true{
            case unwrappedActivity.walking:
                activityString.append("Walking")
            case unwrappedActivity.running:
                activityString.append("Running")
            case unwrappedActivity.cycling:
                activityString.append("Cycling")
            case (unwrappedActivity.stationary && !(unwrappedActivity.automotive)):
                activityString.append("Stationary")
            case unwrappedActivity.automotive:
                activityString.append("Driving")
            default:
                activityString.append("Unknown")
            }
            DispatchQueue.main.async(){
                self.activityStatusLabel.text = activityString
            }
        }
    }
    
    // MARK: Pedometer Functions
    func startPedometerMonitoring(){
        //separate out the handler for better readability
        if CMPedometer.isStepCountingAvailable(){
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            pedometer.startUpdates(from: today, withHandler: self.handlePedometer)
        }
    }
    
    //ped handler
    func handlePedometer(pedData:CMPedometerData?, error:Error?){
        if let steps = pedData?.numberOfSteps {
            self.todaySteps = steps.floatValue
            DispatchQueue.main.async(){
                self.stepCountTodayLabel.text = "\(self.todaySteps)"
                let goal = UserDefaults.standard.integer(forKey: "stepGoal")
                self.stepCountProgress.progress = (self.todaySteps) / Float(goal)
                print("\(self.todaySteps) - \(Float(goal))")
                if ((self.todaySteps) >= Float(goal)) {
                    self.congratsView.isHidden = false
                }
                
            }

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
        }
        DispatchQueue.main.async(){
            self.stepCountYesterdayLabel.text = "\(self.yesterdaySteps)"
        }
    }

    @IBAction func playGame(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "playGame", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "playGame") {
            let gameController = segue.destination as! GameViewController
            // enemies = steps/1000
            if(self.todaySteps > 2000) {
                gameController.startingPucks = Int(self.todaySteps/1000)
                gameController.enemiesLeft = Int(self.todaySteps/1000)
            }
            // default enemies is 2
            else {
                gameController.startingPucks = 2
                gameController.enemiesLeft = 2
            }
        }
    }
}

