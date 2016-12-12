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
//    let nb = NaiveBayes()
    
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
            self.getPredictionData(data: (self.orientationBuffer.getDataAsVector()) as NSArray )
            
            
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
        
//        let features:Array<[Float]> = [[0.03490489, -0.02601342, 0.936972, 0.03642412, -0.07803861, 0.9818795, 0.03997524, -0.07198536, 0.9931345, 0.04759375, -0.09337893, 0.9863322], [0.03997524, -0.07198536, 0.9931345, 0.04759375, -0.09337893, 0.9863322, 0.05168232, -0.1202061, 0.9766228, 0.06687842, -0.1499301, 0.9679686], [0.05168232, -0.1202061, 0.9766228, 0.06687842, -0.1499301, 0.9679686, 0.08725108, -0.1722012, 0.9547643, 0.1323275, -0.1618759, 0.9415533], [0.1323275, -0.1618759, 0.9415533, 0.1801915, -0.137533, 0.9109179, 0.2016812, -0.0987663, 0.8864092, 0.1785055, -0.0923863, 0.8831193], [0.2016812, -0.0987663, 0.8864092, 0.1785055, -0.0923863, 0.8831193, 0.1162304, -0.07151154, 0.8828332, 0.03740722, -0.04609278, 0.900834], [0.03740722, -0.04609278, 0.900834, -0.02750763, -0.0307449, 0.914795, -0.04497556, -0.009868459, 0.9203147, -0.05176352, 0.03974267, 0.9092126], [-0.04497556, -0.009868459, 0.9203147, -0.05176352, 0.03974267, 0.9092126, -0.04614967, 0.08120406, 0.9040428, -0.02462588, 0.03006122, 0.9134732], [-0.04614967, 0.08120406, 0.9040428, -0.02462588, 0.03006122, 0.9134732, 0.00145622, -0.1403072, 0.9497705, -0.06566296, -0.2379801, 1.011005], [0.00145622, -0.1403072, 0.9497705, -0.06566296, -0.2379801, 1.011005, -0.1504242, -0.2623945, 1.01903, -0.1475496, -0.1683258, 0.9996877], [-0.1475496, -0.1683258, 0.9996877, -0.08506833, -0.04582014, 0.9417921, -0.03195437, 0.0536838, 0.8979021, -0.0007837485, 0.09281485, 0.8800598], [-0.03195437, 0.0536838, 0.8979021, -0.0007837485, 0.09281485, 0.8800598, 0.05232498, 0.1527983, 0.8540859, 0.118591, 0.2368214, 0.8228819], [0.118591, 0.2368214, 0.8228819, 0.1575245, 0.269864, 0.7861786, 0.2060353, 0.273262, 0.7678806, 0.2139674, 0.1937331, 0.7896686], [0.2139674, 0.1937331, 0.7896686, 0.1672266, 0.03278825, 0.8386958, 0.0397634, -0.1144805, 0.9048129, -0.07512607, -0.1721166, 0.9215812], [0.0397634, -0.1144805, 0.9048129, -0.07512607, -0.1721166, 0.9215812, -0.09963378, -0.1537137, 0.9009597, -0.04039745, -0.05245381, 0.8703479], [-0.09963378, -0.1537137, 0.9009597, -0.04039745, -0.05245381, 0.8703479, 0.05072707, 0.05666125, 0.7892796, 0.1341292, 0.1228406, 0.7560063], [0.05072707, 0.05666125, 0.7892796, 0.1341292, 0.1228406, 0.7560063, 0.1952967, 0.1457003, 0.7268167, 0.2167149, 0.150118, 0.7284787], [0.2167149, 0.150118, 0.7284787, 0.2455789, 0.08253132, 0.7539397, 0.2945117, -0.02942017, 0.8161086, 0.31839, -0.1741928, 0.8918997], [0.31839, -0.1741928, 0.8918997, 0.2973631, -0.1484444, 0.8676509, 0.2365443, -0.07817809, 0.8496078, 0.1356092, -0.08267408, 0.8607757], [0.2365443, -0.07817809, 0.8496078, 0.1356092, -0.08267408, 0.8607757, -0.01271012, -0.05852252, 0.8778653, -0.09281574, -0.09940822, 0.8964793], [-0.01271012, -0.05852252, 0.8778653, -0.09281574, -0.09940822, 0.8964793, -0.07936249, -0.1135278, 0.8947929, 0.02202168, -0.08192153, 0.8915156], [-0.07936249, -0.1135278, 0.8947929, 0.02202168, -0.08192153, 0.8915156, 0.08873461, -0.05284061, 0.8629435, 0.1577324, 0.0008263862, 0.8486955], [0.08873461, -0.05284061, 0.8629435, 0.1577324, 0.0008263862, 0.8486955, 0.2437304, -0.02582615, 0.8306401, 0.310959, -0.1242091, 0.8668311], [0.310959, -0.1242091, 0.8668311, 0.2717524, -0.2876101, 0.9399447, 0.1920993, -0.3277842, 0.9864203, 0.09634733, -0.3541257, 0.9976886], [0.1920993, -0.3277842, 0.9864203, 0.09634733, -0.3541257, 0.9976886, 0.03350259, -0.2621846, 0.9702802, 0.005587649, -0.1048509, 0.9299322], [0.03350259, -0.2621846, 0.9702802, 0.005587649, -0.1048509, 0.9299322, 0.001382903, 0.027808, 0.856259, 0.02779157, 0.0743531, 0.8194834], [0.001382903, 0.027808, 0.856259, 0.02779157, 0.0743531, 0.8194834, 0.07519068, 0.03082247, 0.8010988, 0.1883527, -0.1714403, 0.8402712], [0.1883527, -0.1714403, 0.8402712, 0.2137275, -0.3393418, 0.9129168, 0.1875633, -0.290094, 0.948906, 0.1199091, -0.1689031, 0.915107], [0.1875633, -0.290094, 0.948906, 0.1199091, -0.1689031, 0.915107, 0.04369934, 0.002905777, 0.8777335, 0.01170045, 0.05365247, 0.8596596], [0.04369934, 0.002905777, 0.8777335, 0.01170045, 0.05365247, 0.8596596, 0.1185603, 0.01728487, 0.8317779, 0.1920371, 0.02366249, 0.8093414], [0.1920371, 0.02366249, 0.8093414, 0.1984042, -0.08164605, 0.7806304, 0.3123168, -0.05535448, 0.7949556, 0.2570961, -0.0860526, 0.8353586], [0.3123168, -0.05535448, 0.7949556, 0.2570961, -0.0860526, 0.8353586, 0.2136924, -0.1618167, 0.8310072, 0.2847981, -0.09705438, 0.8596589], [0.1895677, -0.1835916, 0.8571445, 0.2105343, -0.1664024, 0.8581854, 0.2203189, -0.1444484, 0.8517625, 0.2362742, -0.1207823, 0.8692016], [0.1659771, -0.1584609, 0.8613371, 0.2091242, -0.1606228, 0.8761135, 0.2284371, -0.230697, 0.8478727, 0.2792198, -0.2113828, 0.8956211], [0.2284371, -0.230697, 0.8478727, 0.2792198, -0.2113828, 0.8956211, 0.1993951, -0.2358874, 0.8712122, 0.2099624, -0.1603742, 0.8812872], [0.1613952, -0.2109868, 0.9033627, 0.2205659, -0.2289839, 0.939038, 0.1214178, -0.2103857, 0.9190738, 0.1938987, -0.1400728, 0.963003], [0.1938987, -0.1400728, 0.963003, 0.1637951, -0.1466058, 0.9713948, 0.1269478, -0.02835253, 0.9421671, 0.1420545, -0.01883587, 0.9438983], [0.1269478, -0.02835253, 0.9421671, 0.1420545, -0.01883587, 0.9438983, 0.2109523, -0.02052651, 0.9217145, 0.3213707, -0.02550903, 0.9483926], [0.2109523, -0.02052651, 0.9217145, 0.3213707, -0.02550903, 0.9483926, 0.2380994, -0.03157976, 0.9098002, 0.2855628, -0.04864261, 0.940977], [0.2855628, -0.04864261, 0.940977, 0.2815395, -0.1662843, 0.97144, 0.2778784, -0.1446953, 0.9563474, 0.3167636, -0.2341536, 1.029019], [0.3167636, -0.2341536, 1.029019, 0.2046241, -0.2719316, 0.9640188, 0.2309771, -0.2925816, 1.025191, 0.09742683, -0.2947268, 0.9899139], [0.2309771, -0.2925816, 1.025191, 0.09742683, -0.2947268, 0.9899139, 0.07897309, -0.2205629, 1.018343, 0.0456655, -0.2286536, 0.9854971], [0.09874012, -0.04581514, 0.9165381, 0.06265079, -0.04295501, 0.9139122, 0.03324448, -0.1029921, 0.8695375, 0.08991292, -0.07086639, 0.9545874], [0.03324448, -0.1029921, 0.8695375, 0.08991292, -0.07086639, 0.9545874, 0.07706189, -0.2823509, 0.9233726, 0.1058391, -0.09337848, 0.9727094], [0.2372977, -0.09740286, 0.8745388, 0.4038482, -0.06761888, 0.8661624, 0.505526, -0.1981835, 0.8222454, 0.4551831, -0.06140424, 0.7208576], [0.6141759, -0.5396474, 0.8361949, 0.5955733, -0.5401025, 0.8072308, 0.5350846, -0.369855, 0.7404969, 0.533668, -0.3615011, 0.8239865], [0.533668, -0.3615011, 0.8239865, 0.3853391, -0.2999956, 0.9591987, 0.1837259, -0.1905421, 0.9620364, 0.1305064, -0.07984046, 1.01396], [0.1305064, -0.07984046, 1.01396, 0.04456002, 0.03193456, 1.013065, -0.0486225, 0.2073381, 0.9617689, 0.01209971, 0.3206332, 0.9479426], [0.01209971, 0.3206332, 0.9479426, -0.002573331, 0.2305981, 0.9183906, 0.02244692, 0.1167204, 0.9332753, -0.007538338, -0.02214394, 0.995865], [0.02244692, 0.1167204, 0.9332753, -0.007538338, -0.02214394, 0.995865, -0.1045215, -0.1762588, 0.9803786, -0.125795, -0.08596601, 1.046697], [-0.125795, -0.08596601, 1.046697, -0.1656992, -0.1593322, 1.023986, -0.1312373, -0.06530766, 1.012542, -0.04672161, 0.1112807, 1.027831], [-0.04672161, 0.1112807, 1.027831, -0.01970471, 0.0991593, 0.91181, 0.01326013, 0.2113783, 0.8320976, 0.09911342, 0.05492018, 0.8561867], [0.01326013, 0.2113783, 0.8320976, 0.09911342, 0.05492018, 0.8561867, 0.1249285, -0.2288959, 0.8741831, 0.03646852, -0.1716748, 0.9367242], [0.1249285, -0.2288959, 0.8741831, 0.03646852, -0.1716748, 0.9367242, 0.04337224, -0.1737626, 0.9531695, -0.007123628, -0.02158934, 0.9071459], [0.04337224, -0.1737626, 0.9531695, -0.007123628, -0.02158934, 0.9071459, -0.08603863, 0.05331585, 0.792442, -0.08144661, 0.1813405, 0.8104369], [-0.08144661, 0.1813405, 0.8104369, -0.11427, 0.1541598, 0.7945864, -0.08171158, 0.1576467, 0.8044347, -0.0415959, 0.1689152, 0.8549855], [-0.0801025, -0.1023649, 0.8408943, 0.01608113, 0.01759695, 0.8942584, 0.01345359, -0.06053815, 0.8844644, 0.01968019, 0.05480974, 0.8965728], [0.01345359, -0.06053815, 0.8844644, 0.01968019, 0.05480974, 0.8965728, 0.06199912, -0.1153103, 0.8904015, 0.02845438, 0.02601577, 0.9211891], [0.0160794, -0.08070955, 0.9523268, 0.01234255, -0.182752, 0.960937, -0.02008976, -0.09203443, 0.977886, 0.04316079, -0.1552694, 1.005415], [-0.02008976, -0.09203443, 0.977886, 0.04316079, -0.1552694, 1.005415, -0.0720915, -0.166611, 0.9430175, 0.002026146, -0.02481269, 1.004938], [0.002026146, -0.02481269, 1.004938, -0.02533331, -0.1199691, 0.9841411, -0.002525855, -0.09238261, 0.9793181, 0.01307713, -0.06478544, 1.004268], [-0.03289697, -0.05028869, 0.9269261, -0.004850898, 0.0587848, 0.9616247, -0.1094751, -0.0609388, 0.8614103, -0.05611035, 0.07994101, 0.9354243], [-0.001969042, -0.2086798, 0.9322836, -0.0001271877, -0.1011419, 0.9464372, -0.02353992, -0.1528157, 0.9358137, 0.006586022, -0.03623727, 0.962521], [-0.02353992, -0.1528157, 0.9358137, 0.006586022, -0.03623727, 0.962521, 0.03587772, -0.1828001, 0.9507294, -0.01752517, 0.04074693, 0.9501067], [0.03587772, -0.1828001, 0.9507294, -0.01752517, 0.04074693, 0.9501067, 0.03824108, -0.06550941, 0.9737213, 0.003324715, 0.01357734, 0.9368054], [0.0165489, -0.02374356, 0.9026847, 0.03247719, -0.01496577, 0.9333134, 0.02122325, -0.006647215, 0.9320582, 0.03099351, 0.06409114, 0.9542004], [0.03952828, 0.008623173, 0.9575198, 0.007327548, -0.007704403, 0.9419629, -0.004856932, 0.006260022, 0.909372, 0.05143529, 0.01226796, 0.961012], [-0.004856932, 0.006260022, 0.909372, 0.05143529, 0.01226796, 0.961012, -0.01606369, -0.09083374, 0.8779409, 0.07012273, -0.02100419, 0.9652845], [1.488518, 1.469262, -2.933953, 1.512877, 1.324447, -2.788561, 1.525931, 1.328875, -2.805493, 1.54, 1.636647, -3.129952], [1.525931, 1.328875, -2.805493, 1.54, 1.636647, -3.129952, 1.560225, 0.9202652, -2.408286, 1.563105, -1.686402, 0.1862347], [1.560225, 0.9202652, -2.408286, 1.563105, -1.686402, 0.1862347, 1.547813, -1.850322, 0.3635947, 1.568805, -2.576573, 1.082555], [1.547813, -1.850322, 0.3635947, 1.568805, -2.576573, 1.082555, 1.514197, -1.434628, -0.06043029, 1.547196, -1.375641, -0.1131684], [1.430486, -1.395295, -0.1102122, 1.49961, -1.423932, -0.06715205, 1.515933, -1.598998, 0.09533313, 1.457651, -1.423684, -0.09917801], [1.50391, -1.412346, -0.08344305, 1.506164, -1.512902, -0.007200796, 1.544475, -1.985065, 0.4552807, 1.521792, -1.615682, 0.07504939], [1.47182, -1.416841, -0.07027319, 1.46939, -1.362235, -0.1130131, 1.466766, -1.433938, -0.04481251, 1.462014, -1.611919, 0.09212567], [1.302043, -1.423273, -0.1147607, 1.244476, -1.426537, -0.1145804, 1.24831, -1.428873, -0.1102097, 1.253434, -1.470272, -0.08743592], [1.253434, -1.470272, -0.08743592, 1.27767, -1.483629, -0.07120483, 1.255316, -1.476283, -0.06308713, 1.263025, -1.505611, -0.04065622], [1.263025, -1.505611, -0.04065622, 1.258412, -1.513542, -0.03020406, 1.233903, -1.514083, -0.008470831, 1.251506, -1.528542, 0.01594836], [1.253435, -1.509046, 0.0240697, 1.203205, -1.422402, -0.0487023, 1.152494, -1.509011, -0.01269798, 1.128505, -1.550051, 0.009355218], [1.170999, -1.590038, 0.07408567, 1.236832, -1.552741, 0.05900023, 1.33627, -1.414247, -0.0442929, 1.386505, -1.161452, -0.2940864], [1.33627, -1.414247, -0.0442929, 1.386505, -1.161452, -0.2940864, 1.401057, -1.032323, -0.4049669, 1.430243, -0.9749264, -0.4748304], [1.401057, -1.032323, -0.4049669, 1.430243, -0.9749264, -0.4748304, 1.461645, -0.8087147, -0.6203101, 1.535603, -0.7504417, -0.7032107], [1.461645, -0.8087147, -0.6203101, 1.535603, -0.7504417, -0.7032107, 1.447801, -1.257715, -0.2348925, 1.332984, -1.45976, -0.08097547], [1.447801, -1.257715, -0.2348925, 1.332984, -1.45976, -0.08097547, 1.300042, -1.578787, 0.007366617, 1.322592, -1.644409, 0.06088956], [1.41246, -1.641293, 0.1196092, 1.546387, -0.9316309, -0.5019138, 1.467421, 0.9529219, -2.334956, 1.396485, 1.096655, -2.44768], [1.467421, 0.9529219, -2.334956, 1.396485, 1.096655, -2.44768, 1.363294, 1.221785, -2.569664, 1.413878, 1.134652, -2.527084], [1.363294, 1.221785, -2.569664, 1.413878, 1.134652, -2.527084, 1.513586, 0.04156775, -1.526658, 1.40209, -1.255738, -0.3020952], [1.513586, 0.04156775, -1.526658, 1.40209, -1.255738, -0.3020952, 1.339478, -1.303024, -0.2670571, 1.291932, -1.293128, -0.2886766], [1.339478, -1.303024, -0.2670571, 1.291932, -1.293128, -0.2886766, 1.282608, -1.29578, -0.2779785, 1.322879, -1.192445, -0.3436383], [1.322879, -1.192445, -0.3436383, 1.430736, -0.7897332, -0.6834624, 1.458193, 0.5925977, -2.016693, 1.397939, 1.056603, -2.509317], [1.458193, 0.5925977, -2.016693, 1.397939, 1.056603, -2.509317, 1.459003, 0.6296003, -2.128372, 1.45512, -0.6106564, -0.9298064], [1.459003, 0.6296003, -2.128372, 1.45512, -0.6106564, -0.9298064, 1.371358, -1.236638, -0.3433315, 1.275739, -1.42664, -0.1801918], [1.371358, -1.236638, -0.3433315, 1.275739, -1.42664, -0.1801918, 1.198195, -1.487912, -0.1196735, 1.181227, -1.539642, -0.08263228], [1.198195, -1.487912, -0.1196735, 1.181227, -1.539642, -0.08263228, 1.300255, -1.494177, -0.07222488, 1.381977, -1.480883, -0.1045458], [1.381977, -1.480883, -0.1045458, 1.337193, -1.445194, -0.1390516, 1.318527, -1.475973, -0.1221045, 1.364205, -1.508011, -0.09110475], [1.337193, -1.445194, -0.1390516, 1.318527, -1.475973, -0.1221045, 1.364205, -1.508011, -0.09110475, 1.282496, -1.532455, -0.08915587], [1.318527, -1.475973, -0.1221045, 1.364205, -1.508011, -0.09110475, 1.282496, -1.532455, -0.08915587, 1.280496, -1.569139, -0.05121255], [1.340313, -1.604322, -0.008302844, 1.311363, -1.676807, 0.05249946, 1.259567, -1.644006, 0.02192759, 1.248526, -1.592251, -0.01609079], [1.259567, -1.644006, 0.02192759, 1.248526, -1.592251, -0.01609079, 1.28254, -1.628676, 0.02879507, 1.273722, -1.627269, 0.02392804], [1.28254, -1.628676, 0.02879507, 1.273722, -1.627269, 0.02392804, 1.260543, -1.649243, 0.05192316, 1.269218, -1.669243, 0.07485617], [1.273722, -1.627269, 0.02392804, 1.260543, -1.649243, 0.05192316, 1.269218, -1.669243, 0.07485617, 1.255216, -1.704504, 0.1123402], [1.255216, -1.704504, 0.1123402, 1.217471, -1.6719, 0.08340301, 1.177598, -1.683596, 0.09400444, 1.162517, -1.648307, 0.06678426], [1.177598, -1.683596, 0.09400444, 1.162517, -1.648307, 0.06678426, 1.197601, -1.618739, 0.05705078, 1.28934, -1.491158, -0.006622715], [1.28934, -1.491158, -0.006622715, 1.399842, -1.231034, -0.2204518, 1.353684, -1.014951, -0.4150476, 1.350206, -1.179095, -0.2735271], [1.278779, -1.490545, -0.03996292, 1.262709, -1.457532, -0.07299767, 1.293352, -1.519799, -0.01623498, 1.300832, -1.626229, 0.07412794], [1.262709, -1.457532, -0.07299767, 1.293352, -1.519799, -0.01623498, 1.300832, -1.626229, 0.07412794, 1.236956, -1.646676, 0.09312593], [1.300832, -1.626229, 0.07412794, 1.236956, -1.646676, 0.09312593, 1.159526, -1.60515, 0.04874274, 1.096391, -1.618545, 0.05941205], [1.159526, -1.60515, 0.04874274, 1.096391, -1.618545, 0.05941205, 1.044407, -1.574315, 0.03242511, 1.019892, -1.549151, 0.01651267], [1.042467, -1.47562, 0.004832837, 1.219859, -1.23471, -0.1517848, 1.293616, -0.9807363, -0.4082687, 1.374918, -0.8518897, -0.5482774], [1.042467, -1.47562, 0.004832837, 1.219859, -1.23471, -0.1517848, 1.293616, -0.9807363, -0.4082687, 1.374918, -0.8518897, -0.5482774], [1.374918, -0.8518897, -0.5482774, 1.462954, -0.8759034, -0.5456929, 1.512828, -0.4924155, -0.9474792, 1.499436, 0.006630764, -1.449961], [1.462954, -0.8759034, -0.5456929, 1.512828, -0.4924155, -0.9474792, 1.499436, 0.006630764, -1.449961, 1.487694, 0.08795983, -1.543259], [1.487694, 0.08795983, -1.543259, 1.493069, 0.6254106, -2.087981, 1.468339, 1.200308, -2.667939, 1.456457, 1.296415, -2.76867], [1.468339, 1.200308, -2.667939, 1.456457, 1.296415, -2.76867, 1.466176, 1.274582, -2.763253, 1.515884, 0.716197, -2.23927], [1.515884, 0.716197, -2.23927, 1.522826, -0.5172952, -1.027212, 1.499823, -0.9301625, -0.6238726, 1.474714, -1.108898, -0.45191], [0.3186122, -2.809371, 1.296036, 0.2925071, -2.880412, 1.267782, 0.2947847, -2.869231, 1.264582, 0.2790537, -2.918102, 1.303376], [0.263537, -2.93392, 1.28849, 0.2722124, -2.888994, 1.263382, 0.2762308, -2.890248, 1.263033, 0.2740484, -2.89447, 1.296242], [0.2762308, -2.890248, 1.263033, 0.2740484, -2.89447, 1.296242, 0.2630607, -2.906599, 1.292413, 0.2712601, -2.89453, 1.267756], [0.2740484, -2.89447, 1.296242, 0.2630607, -2.906599, 1.292413, 0.2712601, -2.89453, 1.267756, 0.2871403, -2.870283, 1.272783], [0.2712601, -2.89453, 1.267756, 0.2871403, -2.870283, 1.272783, 0.2785869, -2.874952, 1.307502, 0.2580431, -2.912141, 1.305583], [0.2785869, -2.874952, 1.307502, 0.2580431, -2.912141, 1.305583, 0.2663462, -2.904553, 1.263595, 0.2710942, -2.89515, 1.256121], [0.2710942, -2.89515, 1.256121, 0.2566759, -2.906662, 1.267953, 0.2444646, -2.904768, 1.275365, 0.2234683, -2.929535, 1.255522], [0.2223353, -2.770083, 1.234316, 0.2173883, -2.779373, 1.234887, 0.2127374, -2.792565, 1.23667, 0.208737, -2.796498, 1.239342], [0.1915274, -2.791501, 1.274158, 0.1714925, -2.811369, 1.276523, 0.1676232, -2.820688, 1.275704, 0.1622775, -2.840905, 1.275018], [0.1622775, -2.840905, 1.275018, 0.1602373, -2.839464, 1.286578, 0.1416125, -2.889252, 1.31819, 0.1401328, -2.947361, 1.370064], [0.1416125, -2.889252, 1.31819, 0.1401328, -2.947361, 1.370064, 0.1479003, -2.981107, 1.411146, 0.1538407, -3.012258, 1.430427], [0.1479003, -2.981107, 1.411146, 0.1538407, -3.012258, 1.430427, 0.1479284, -3.048114, 1.447097, 0.15582, -3.067981, 1.455825], [0.1479284, -3.048114, 1.447097, 0.15582, -3.067981, 1.455825, 0.1723894, -3.069762, 1.467292, 0.1947404, -3.067514, 1.46253], [0.1723894, -3.069762, 1.467292, 0.1947404, -3.067514, 1.46253, 0.2010255, -3.059068, 1.4457, 0.1978887, -3.020156, 1.368624], [0.1689608, -3.012186, 1.286466, 0.1537415, -3.033319, 1.28671, 0.1671176, -3.090382, 1.348036, 0.1970493, 3.135678, 1.428888], [0.1671176, -3.090382, 1.348036, 0.1970493, 3.135678, 1.428888, 0.2203351, 3.08635, 1.489889, 0.232871, 3.065502, 1.526223], [0.2203351, 3.08635, 1.489889, 0.232871, 3.065502, 1.526223, 0.2312594, 3.073223, 1.527159, 0.2142329, 3.058477, 1.527238], [0.2312594, 3.073223, 1.527159, 0.2142329, 3.058477, 1.527238, 0.2040966, 3.060897, 1.529981, 0.1713786, 3.021312, 1.533406], [0.1713786, 3.021312, 1.533406, 0.1662205, 3.021286, 1.54674, 0.1768818, 2.998168, 1.572921, 0.2206265, 2.968233, 1.617354], [0.1768818, 2.998168, 1.572921, 0.2206265, 2.968233, 1.617354, 0.2437272, 2.951516, 1.633806, 0.2414824, 2.965185, 1.605188], [0.2414824, 2.965185, 1.605188, 0.2503064, 3.030637, 1.523931, 0.2378081, 3.069963, 1.452839, 0.2158105, 3.078749, 1.435796], [0.2378081, 3.069963, 1.452839, 0.2158105, 3.078749, 1.435796, 0.1861393, 3.070216, 1.426956, 0.159392, 3.066766, 1.42551], [0.1861393, 3.070216, 1.426956, 0.159392, 3.066766, 1.42551, 0.1530075, 3.039738, 1.464892, 0.1603784, 3.00072, 1.529685], [0.1603784, 3.00072, 1.529685, 0.1603635, 3.001386, 1.556872, 0.1301134, 3.059021, 1.466078, 0.07098253, 3.093333, 1.398787], [0.1603635, 3.001386, 1.556872, 0.1301134, 3.059021, 1.466078, 0.07098253, 3.093333, 1.398787, 0.04660328, 3.114371, 1.388937], [0.04660328, 3.114371, 1.388937, 0.04968082, 3.102592, 1.422727, 0.08155712, 3.075715, 1.488887, 0.1405606, 3.033106, 1.569891], [0.08155712, 3.075715, 1.488887, 0.1405606, 3.033106, 1.569891, 0.1958548, 2.997297, 1.633859, 0.2971582, 3.070568, 1.563551], [0.1958548, 2.997297, 1.633859, 0.2971582, 3.070568, 1.563551, 0.3368448, -3.140448, 1.451328, 0.3169863, -3.12112, 1.416545], [0.3368448, -3.140448, 1.451328, 0.3169863, -3.12112, 1.416545, 0.259363, -3.133767, 1.424444, 0.1806651, 3.128962, 1.441593], [0.259363, -3.133767, 1.424444, 0.1806651, 3.128962, 1.441593, 0.1075666, 3.127229, 1.456671, 0.05699409, -3.132314, 1.478104], [-0.01185023, -3.124311, 1.510527, -0.02793827, -3.121839, 1.501407, -0.03927062, -3.124414, 1.515286, -0.02269715, -3.136146, 1.528253], [-0.03927062, -3.124414, 1.515286, -0.02269715, -3.136146, 1.528253, -0.009928252, -3.122023, 1.521112, 0.01342963, -3.125897, 1.509145], [-0.02269715, -3.136146, 1.528253, -0.009928252, -3.122023, 1.521112, 0.01342963, -3.125897, 1.509145, 0.05778008, -3.09488, 1.491313], [0.05778008, -3.09488, 1.491313, 0.09590188, -3.053313, 1.458241, 0.08835308, -3.04218, 1.458345, 0.04071793, -3.062594, 1.483678], [0.08835308, -3.04218, 1.458345, 0.04071793, -3.062594, 1.483678, -0.04624747, -3.092827, 1.544311, -0.08704463, -3.111834, 1.606595], [-0.04624747, -3.092827, 1.544311, -0.08704463, -3.111834, 1.606595, -0.09389891, -3.128638, 1.631254, -0.04966302, -3.126866, 1.570723], [-0.09389891, -3.128638, 1.631254, -0.04966302, -3.126866, 1.570723, 0.01477662, -3.10869, 1.435885, 0.06260623, -3.075915, 1.346102], [-0.04966302, -3.126866, 1.570723, 0.01477662, -3.10869, 1.435885, 0.06260623, -3.075915, 1.346102, 0.08364984, -3.030773, 1.294379], [0.06260623, -3.075915, 1.346102, 0.08364984, -3.030773, 1.294379, 0.09494934, -2.99743, 1.287727, 0.09214012, -3.005861, 1.283925], [0.09214012, -3.005861, 1.283925, 0.1201922, -2.94979, 1.249755, 0.1664673, -2.859625, 1.190048, 0.1862254, -2.866488, 1.185125]]
//        let labels = ["Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3"]

        let labels = ["Gesture 1", "Gesture 2", "Gesture 3"]
        let features = [[0.03490489,-0.02601342, 0.936972],[0.2710942, -2.89515, 1.256121],[-0.09389891, -3.128638, 1.631254]]
        var labeledFeatures:[String:[FeatureData]] = [:]
//        for (f,l) in zip(features,labels) {
//            if labeledFeatures[l] != nil {
//                labeledFeatures[l]?.append(FeatureData(data: f))
//            }
//            else {
//                labeledFeatures[l] = [FeatureData(data: f)]
//            }
//        }
        
        
        var eventSpace = EventSpace<String, FeatureData >()
        
        for (f,l) in zip(features,labels) {
            eventSpace.observe(category: l, features: [FeatureData(data: f)])
        }
//        for key in labeledFeatures {
//            eventSpace.observe(category: key, features: labeledFeatures[key])
//        }
        
        var classifier = BayesianClassifier(eventSpace: eventSpace)
//
//        XCTAssertEqual(classifier.classify(["claw", "tail"])!, "Cat", "Should categorize as Cat, due to claw")
//        XCTAssertEqual(classifier.classify(["bark", "tail"])!, "Dog", "Should categorize as Dog, due to bark")
//        XCTAssertEqual(classifier.classify(["tail"])!, "Cat", "Should categorize as Cat, due to base rate")
//        XCTAssertEqual(classifier.classify(["paw", "tail"])!, "Dog", "Should categorize as Dog, due to prevalence of paw")
//        
        
        
        // Positive tokens and the frequencies ["token A": Frequency of token A, ...]
//        let pos = ["computer": 3, "programming": 2, "python": 1, "swift": 2]
//        // Negative tokens ["token X": Frequency of token X, ...]
//        let neg = ["game": 2, "computer": 2, "video": 1, "programming": 1]
//        // Positive tokens for testing
        let posTest = [-0.09, -3.1, 1.6]
        // Train model
        // ["Label A": ["token A": Frequency of token A, ...]]
//        nb.fit(labeledFeatures)
        // Predicts log probabilities for each label
//        let logProbs = nb.predict(posTest)
//        print(logProbs) //=> ["positive": -8.9186205290602363, "negative": -10.227308671603783]
        // Use method chaining
//        nb.fit(["positive": pos, "negative": neg]).predict(posTest)
//        
//        do {
//            // Save session
//            try! nb.save("nb.session")
//        } catch {
//            print("Saving session failed.")
//        }
//        
//        do {
//            // Restore session
//            let nb2 = try NaiveBayes("nb.session")
//        }
//        catch {
//            print("Loading session failed.")
//        }
        
        let data = DataSet(dataType: .classification, inputDimension: 2, outputDimension: 1)
        try! data.addDataPoint(input: [0.2, 0.9], dataClass:0)
        try! data.addDataPoint(input: [0.8, 0.3], dataClass:0)
        try! data.addDataPoint(input: [0.5, 0.6], dataClass:0)
        try! data.addDataPoint(input: [0.2, 0.7], dataClass:1)
        try! data.addDataPoint(input: [0.2, 0.3], dataClass:1)
        try! data.addDataPoint(input: [0.4, 0.5], dataClass:1)
        try! data.addDataPoint(input: [0.5, 0.4], dataClass:2)
        try! data.addDataPoint(input: [0.3, 0.2], dataClass:2)
        try! data.addDataPoint(input: [0.7, 0.2], dataClass:2)
    }
    
    
    
    
    
    
}
