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
    
    //used for machine learning
    let svm = SVMModel(problemType: .c_SVM_Classification, kernelSettings: KernelParameters(type: .radialBasisFunction, degree: 0, gamma: 0.5, coef0: 0.0))
    
    
    var ringBuffer = RingBuffer()
    var orientationBuffer = RingBuffer()
    let magValue = 1.5
    var numDataPoints = 0
    var recording = false

    var indicatorView: ESTMusicIndicatorView!
    var startAnimating: Bool = false
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    let TIME_DELAY = 0.25
    
    
    
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
        
        
        
        doMachineLearning()
        
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
            try recordingSession.overrideOutputAudioPort(.speaker )
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
        
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
        self.startCMMonitoring()
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
//            self.getPredictionData(data: (self.ringBuffer.getDataAsVector()+self.orientationBuffer.getDataAsVector()) as NSArray )
//            self.getPredictionData(data: (self.orientationBuffer.getDataAsVector()) as NSArray )
            self.predictUsingModel(data: (self.orientationBuffer.getDataAsVector()) as! [Double])
            
            
            
        }
    }
    
    func predictUsingModel(data:[Double]) {
        
        let pred = svm.classifyOne(data)
        var prediction = ""
        print("PREDICTION: ", pred)
        switch pred {
        case 1:
            prediction = "Gesture 1"
        case 2:
            prediction = "Gesture 2"
        case 3:
            prediction = "Gesture 3"
        default:
            print("wrong label!")
        }
        if let gesture = drumKits[selectedDrumKit].gestures[prediction] {
            let instrument = gesture.instrument
            
            let date = self.players[instrument]!["time"] as! Date
            let now = Date()
            let seconds = now.timeIntervalSince(date)
            //                        print("Seconds: ",seconds)
            
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
    
    func postFeatureHandler(data:Data?, urlResponse:URLResponse?, error:Error?) -> Void{
        if(!(error != nil)){
//            print(urlResponse!)
            if let responseData = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, Any> {
//                print(responseData)
                
                if let prediction = responseData["prediction"] as? String {
                    
                    if let gesture = drumKits[selectedDrumKit].gestures[prediction] {
                        let instrument = gesture.instrument
                        
                        let date = self.players[instrument]!["time"] as! Date
                        let now = Date()
                        let seconds = now.timeIntervalSince(date)
//                        print("Seconds: ",seconds)
                        
                        if seconds > TIME_DELAY {
                            self.players[instrument]!["time"] = now
                            self.players[instrument]!["index"] = ((self.players[instrument]!["index"] as! Int)+1)%3
                        }
                        
                        (self.players[instrument]!["players"] as! Array<AVAudioPlayer>)[self.players[instrument]!["index"] as! Int].play()
                    }
                    else {
                        print("Gesture not in use.", prediction)
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
//        print(self.numDataPoints)
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
    
    
    
    func doMachineLearning() {
        
        let features = [[-0.01913749, -0.004542652, 1.801186], [-0.02500217, 0.03825141, 1.635734], [-0.02361225, 0.03468514, 1.527347], [0.002309412, 0.002232602, 1.414023], [0.112905, -0.0447836, 1.35955], [0.04277645, 0.1323807, 1.295876], [0.02680377, -0.08638758, 1.286338], [0.05507561, 0.002052903, 1.273452], [0.1131732, -0.04024906, 1.100561], [0.1261612, -0.01793618, 0.6745923], [0.1642934, 0.05173478, 0.6612703], [0.1026895, 0.05019448, 0.3173817], [0.1875514, 0.04220009, 0.002429998], [0.1737864, 0.03605373, -0.03994646], [0.1478182, 0.1065, -0.1255385], [0.1629991, 0.1212949, -0.3141961], [0.0501021, 0.04918524, -0.8944736], [-0.04168113, 0.06972466, -1.08385], [0.07637779, 0.1570637, -1.221475], [-0.01123786, 0.1818731, -1.258583], [-0.02141155, 0.08289415, -1.22045], [-0.1110847, 0.1086161, -1.248227], [0.08294316, 0.1564323, -1.35889], [-0.07558998, 0.1014204, -1.365235], [-0.1250144, 0.1191523, -1.317674], [-0.1043554, 0.07276042, -1.286101], [-0.05449719, -0.008632566, -1.2775], [-0.06524257, 0.03356069, -1.251656], [-0.03237176, 0.159355, -1.282413], [-0.05125149, 0.2096906, -1.358337], [-0.02222669, 0.117007, -1.480838], [-0.07229302, 0.0575294, -1.807523], [-0.0545662, 0.03537144, -1.858357], [-0.0518338, 0.01837898, -1.958103], [0.004746939, 0.01691969, -2.016589], [-0.05826303, 0.05164926, -1.978915], [-0.01173052, 0.07984936, -1.982504], [-0.05337336, 0.1002681, -1.995906], [-0.02246805, 0.005962385, -2.110649], [-0.02661568, 0.08181538, -2.454084], [-0.026304, 0.05123802, -2.477381], [-0.06358012, 0.006710155, -2.452351], [-0.0817245, -0.001458405, -2.471781], [0.1072825, -0.1319473, 1.159638], [0.0688327, -0.1912439, 1.214885], [0.05483164, -0.1753952, 1.285537], [0.02080428, -0.1292652, 1.360358], [-0.04219821, -0.1607454, 1.654235], [-0.03103355, -0.09551981, 1.738979], [-0.09045994, -0.1241587, 1.760632], [-0.09048311, -0.1066826, 1.776396], [0.0001523175, -0.07279407, 1.570107], [0.01896081, -0.06686127, 1.283051], [0.01743655, -0.08623113, 1.058514], [0.06157574, -0.06071595, 0.8924533], [0.08766345, -0.0723437, 0.4970864], [0.05005608, -0.0436529, 0.5141919], [0.01641902, -0.00853518, 0.5279265], [-0.003400865, 0.01840343, 0.4183101],
         [1.499924, 0.07557607, -1.258702], [1.513752, 1.020253, -2.233016], [1.423258, 0.4522016, -1.684831], [1.443218, 0.8564031, -2.10036], [1.454382, 0.755445, -2.029442], [1.428822, 0.4845724, -1.686946], [1.377481, 0.7691545, -1.67297], [1.372193, 0.8087404, -1.665514], [1.428291, 0.9466934, -1.927847], [1.447019, 0.6854452, -1.784165], [1.44585, 0.5183444, -1.730644], [1.441855, -0.8558058, -0.5500311], [1.431527, -1.291888, -0.1198441], [1.477578, -1.376428, -0.02328826], [1.445064, -0.8336782, -0.5281649], [1.458077, -0.4551925, -0.8858659], [1.349324, -0.4754429, -0.8112588], [1.406006, -0.2940322, -0.5979444], [1.335732, -0.2572086, -0.6982524], [1.329434, -0.05922464, -0.8859679], [1.291057, -0.0761863, -0.8910754], [1.302563, -0.1032925, -0.8978766], [1.418274, -0.2706668, -0.8548265], [1.479272, -2.813722, 1.541382], [1.521693, -1.958241, 0.7066945], [1.378415, -0.4277367, -0.7885871], [1.372061, -0.37155, -0.8408827], [1.322294, -0.3453147, -0.8645086], [1.276084, -0.2998024, -0.8817554], [1.227504, -0.2344419, -0.8907384], [1.263197, -0.1717716, -0.9199029], [1.31961, -0.3888142, -0.751314], [1.331444, -0.5161867, -0.6495116], [1.363799, -0.7445176, -0.4228399], [1.426981, -0.8839309, -0.2821871], [1.455637, 0.8538849, -1.964236], [1.323994, 1.313691, -2.407657], [1.274404, 0.9228685, -1.936076], [1.180738, 0.8621812, -1.842909], [1.115785, 0.8867474, -1.884293], [1.068501, 0.5793965, -1.594808], [1.206642, 0.1999528, -1.364402], [1.401057, -0.185922, -1.066637], [1.48712, -0.06871641, -1.176017], [1.525033, -0.6944684, -0.5414528], [1.512904, -0.8897838, -0.3557838], [1.494381, -1.088335, -0.1605828], [1.425768, -1.55398, 0.3111], [1.30854, -1.598715, 0.4140239], [1.262468, -1.601341, 0.4287618], [1.184247, -1.664919, 0.5094405], [1.137281, -1.727682, 0.612422], [1.128868, -1.617623, 0.5833808], [1.274186, -1.356071, 0.4116955], [1.263067, -0.3307278, -0.6385168], [1.192936, -0.533071, -0.4736494], [1.197157, -0.7760327, -0.3096284], [1.22237, -0.5911251, -0.4896661], [1.374626, -1.859855, 0.7518946], [1.295427, -2.421848, 1.3354], [1.218612, -2.670789, 1.592657], [1.267561, -2.558735, 1.480181], [1.337318, -2.444521, 1.396806], [1.451625, -1.488142, 0.4383874], [1.396211, -0.4901891, -0.5638099], [1.256806, -0.2105258, -0.8434041], [1.256986, -0.1357194, -0.9157775], [1.206555, -0.4361041, -0.6805929],
         [0.0969031, -2.919269, 1.845681], [0.09002627, -2.937735, 1.845372], [0.07547586, -2.956705, 1.844155], [0.08065736, -2.953332, 1.8285], [0.07946742, -2.944396, 1.780835], [0.116558, -2.92571, 1.722204], [0.1801932, -2.874534, 1.633786], [0.2173551, -2.87004, 1.575511], [0.1812332, -2.911981, 1.505892], [0.1522002, -2.893263, 1.561611], [0.1567392, -2.892725, 1.558363], [0.1623855, -2.884635, 1.554965], [0.2036525, -2.87291, 1.5458], [0.1699587, -2.87615, 1.483952], [0.1841671, -2.885482, 1.37672], [0.1045052, -2.937571, 1.331261], [0.07504071, -2.97035, 1.345221], [0.1002213, -2.982671, 1.338646], [0.08788913, -3.004072, 1.327629], [0.07559428, -3.002481, 1.329425], [0.08299296, -2.972791, 1.323977], [0.06990235, -2.974372, 1.286289], [0.07103293, -2.946914, 1.312107], [-0.007018561, -3.017284, 1.556725], [-0.05292758, -3.029725, 1.440775], [-0.08454311, -3.066444, 1.345493], [-0.1239125, 3.11465, 1.31965], [-0.1437692, 3.126657, 1.279659], [-0.1083261, -3.132264, 1.279118], [-0.139303, 3.14047, 1.280832], [-0.1323372, 3.141261, 1.266777], [-0.1176568, -3.134493, 1.277082], [-0.1016392, -3.127334, 1.264573], [-0.1151836, -3.131924, 1.284671], [-0.1189944, 3.121165, 1.252093], [-0.1286197, 3.123641, 1.265188], [-0.1249605, 3.133209, 1.265159], [-0.1197343, 3.137793, 1.259094], [-0.1051518, -3.122644, 1.273345]]
        let labels = ["Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1",
            "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2",
            "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3"]



//        let labels = ["Gesture 1", "Gesture 2", "Gesture 3"]
//        let features = [[0.03490489,-0.02601342, 0.936972],[0.2710942, -2.89515, 1.256121],[-0.09389891, -3.128638, 1.631254]]

        //relabel labels
        var intLabels:[Int] = []
        for l in labels {
            switch l {
            case "Gesture 1":
                intLabels.append(1)
            case "Gesture 2":
                intLabels.append(2)
            case "Gesture 3":
                intLabels.append(3)
            default:
                print("wrong label!")
            }
        }
        let data = DataSet(dataType: .classification, inputDimension: 3, outputDimension: 1)
        for (f,l) in zip(features,intLabels) {
            try! data.addDataPoint(input: f, dataClass:l)
        }
        
        
        svm.Cost = 30.0
        svm.train(data)
        
        
        let posTest = [-0.09, -3.1, 1.6]
        print("Classify:",svm.classifyOne(posTest) )
        
        
    }
    
    
    
    
    
    
}
