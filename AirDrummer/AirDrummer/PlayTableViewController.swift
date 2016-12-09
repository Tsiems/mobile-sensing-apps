//
//  PlayTableViewController.swift
//  AirDrummer
//
//  Created by Erik Gabrielsen on 12/7/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit
import CoreMotion
import AVFoundation




class PlayTableViewController: UITableViewController, URLSessionTaskDelegate, UIGestureRecognizerDelegate, AVAudioRecorderDelegate {
    
    var session = URLSession()
    let cmMotionManager = CMMotionManager()
    let backQueue = OperationQueue()
    var ringBuffer = RingBuffer()
    var orientationBuffer = RingBuffer()
    let magValue = 1.0
    var numDataPoints = 0
    var recording = false

    var indicatorView: ESTMusicIndicatorView!
    var startAnimating: Bool = false
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    let TIME_DELAY = 0.2
    
    
    
    var players = [
        "Hi-Hat":["filename":"hihat","index":0,"players":[AVAudioPlayer(),AVAudioPlayer(),AVAudioPlayer()]],
        "Snare":["filename":"snare","index":0,"players":[AVAudioPlayer(),AVAudioPlayer(),AVAudioPlayer()]],
        "Cymbal":["filename":"crash","index":0,"players":[AVAudioPlayer(),AVAudioPlayer(),AVAudioPlayer()]],
        "Toms":["filename":"tom_002b","index":0,"players":[AVAudioPlayer(),AVAudioPlayer(),AVAudioPlayer()]],
        "Bass":["filename":"bassdrum","index":0,"players":[AVAudioPlayer(),AVAudioPlayer(),AVAudioPlayer()]]
    ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        drumKits = loadDrumKits()
        selectedDrumKit = loadSelectedKit()
        
        //set the time to "now" for all instruments
        players["Hi-Hat"]!["time"] = Date()
        players["Snare"]!["time"] = Date()
        players["Cymbal"]!["time"] = Date()
        players["Toms"]!["time"] = Date()
        players["Bass"]!["time"] = Date()
        
        
        
        // Do any additional setup after loading the view.
        // setup URLSession
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        
        // set up sounds
        for key in self.players.keys {
            
            let dict = self.players[key]!
            
            let sound = NSURL(fileURLWithPath: Bundle.main.path(forResource: dict["filename"] as! String?, ofType: "wav")!)
            
            do {
                if var playersArray = dict["players"]! as? Array<AVAudioPlayer> {
                    
                    var i:Int = 0
                    while i < (playersArray.count as Int)  {
                        playersArray[i] = try AVAudioPlayer(contentsOf: sound as URL)
                        playersArray[i].prepareToPlay()
                        i += 1
                    }
                    
                    self.players[key]!["players"] = playersArray
                }
            }
            catch {
                //
            }
        }
        
        //set up recorder
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("allowed")
                    } else {
                        print("failed to record 1")
                    }
                }
            }
        }
        catch {
            print("failed to record 2")
        }
        
        self.session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        self.startCMMonitoring()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (startAnimating) {
            indicatorView.state = .ESTMusicIndicatorViewStatePlaying
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return drumKits[selectedDrumKit].gestures.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mainCell", for: indexPath) as! MainTableViewCell

        let gestures = drumKits[selectedDrumKit].gestures
        let gestureValues = Array(gestures.values)
        
        // Configure the cell...
        cell.instrumentLabel.text = gestureValues[indexPath.row].instrument
        cell.gestureLabel.text = gestureValues[indexPath.row].gesture_name

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 230
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: "playTitleCell") as! PlayTitleCell
        
        headerCell.recordButton.tag = section
        headerCell.recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        
        return headerCell
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
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
            self.getPredictionData(data: (self.ringBuffer.getDataAsVector()+self.orientationBuffer.getDataAsVector()) as NSArray )
            
        }
    }
    
    func postFeatureHandler(data:Data?, urlResponse:URLResponse?, error:Error?) -> Void{
        if(!(error != nil)){
            print(urlResponse!)
            if let responseData = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, Any> {
                print(responseData)
                
                if let prediction = responseData["prediction"] as? String {
                    
                    if let gesture = drumKits[selectedDrumKit].gestures[prediction] {
                        let instrument = gesture.instrument
                        
                        let date = self.players[instrument]!["time"] as! Date
                        let now = Date()
                        let seconds = now.timeIntervalSince(date)
                        print("Seconds: ",seconds)
                        
                        if seconds > TIME_DELAY {
                            self.players[instrument]!["time"] = now
                            self.players[instrument]!["index"] = ((self.players[instrument]!["index"] as! Int)+1)%3
                        }
                        
                        (self.players[instrument]!["players"] as! Array<AVAudioPlayer>)[self.players[instrument]!["index"] as! Int].play()
                    }
                    else {
                        print("Gesture not in use.")
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

    func toggleRecording(sender: AnimatableButton) {
        print("touched")
        if (recording) {
            finishRecording()
            // save recording
            sender.setTitle("Record",for: .normal)
            sender.backgroundColor = UIColor.black
            sender.setTitleColor(UIColor.init(red: 203/255, green: 162/255, blue: 111/255, alpha: 1.0), for: .normal)
            
            if let viewWithTag = sender.viewWithTag(100) {
                print("Tag 100")
                viewWithTag.removeFromSuperview()
                startAnimating = false
            }
            
            let refreshAlert = UIAlertController(title: "Recorded!", message: "Your jam session has been recorded!", preferredStyle: UIAlertControllerStyle.alert)
            
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action: UIAlertAction!) in
                print("Dismiss")
            }))
            
            refreshAlert.addAction(UIAlertAction(title: "View Recording", style: .default, handler: { (action: UIAlertAction!) in
                print("Do something here")
                self.performSegue(withIdentifier: "goToRecordings", sender: self)
            }))
            
            present(refreshAlert, animated: true, completion: nil)
            recording = false
        } else {
            // start recording
            sender.setTitle("Stop",for: .normal)
            sender.backgroundColor = UIColor.init(red: 203/255, green: 162/255, blue: 111/255, alpha: 1.0)
            sender.setTitleColor(UIColor.black, for: .normal)
            recording = true
            let screenSize: CGRect = UIScreen.main.bounds
            indicatorView = ESTMusicIndicatorView.init(frame: CGRect(origin: CGPoint(x: (screenSize.width - 100), y: 0), size: CGSize(width: 50, height: 44)))
            indicatorView.hidesWhenStopped = false
            indicatorView.tintColor = UIColor.black
            indicatorView.state = .ESTMusicIndicatorViewStatePlaying
            indicatorView.tag = 100
            startAnimating = true
            sender.addSubview(indicatorView)
            startRecording()
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    
    func startRecording() {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "MM-dd-yy h:mm a"
        
        let dateStamp = dateFormatter.string(from: Date()) + ".m4a"
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent(dateStamp)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
        }
        catch {
            finishRecording()
        }
    }
    
    func finishRecording() {
        audioRecorder.stop()
        audioRecorder = nil
        
    }
}
