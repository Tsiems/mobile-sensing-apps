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
    var currentGifName = ""
    var currentInstrumentName = ""
    
    //used for machine learning
    let svm = SVMModel(problemType: .c_SVM_Classification, kernelSettings: KernelParameters(type: .radialBasisFunction, degree: 0, gamma: 0.5, coef0: 0.1))
    
    
    var ringBuffer = RingBuffer()
    var orientationBuffer:[Double] = []
    let magValue = 1.5
    let maxMagValue = 6.0
    
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
        
        //set so screen does not lock while drumming
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        self.title = "Play " + drumKits[selectedDrumKit].name
        
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let gestures = drumKits[selectedDrumKit].gestures
        let gestureValues = Array(gestures.values)
        self.currentGifName = gestureValues[indexPath.row].gesture_name
        self.currentInstrumentName = gestureValues[indexPath.row].instrument
        self.performSegue(withIdentifier: "showGesture", sender: self)
    }

    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 250
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: "playTitleCell") as! PlayTitleCell
        
        headerCell.recordButton.tag = section
        headerCell.recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        headerCell.drumKitTitle.text = drumKits[selectedDrumKit].name
        
        return headerCell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showGesture" {
            
            let target = segue.destination as! GesturePopUpViewController
            target.gifName = self.currentGifName
            target.instrument = self.currentInstrumentName
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.cmMotionManager.stopDeviceMotionUpdates()
    }
    
    
    func handleMotion(motion:CMDeviceMotion?, error:Error?)->Void{
        self.ringBuffer.addNewData(Float((motion?.userAcceleration.x)!), withY: Float((motion?.userAcceleration.y)!), withZ: Float((motion?.userAcceleration.z)!))
        
//        self.orientationBuffer.addNewData(Float((motion?.attitude.pitch)!), withY: Float((motion?.attitude.roll)!), withZ: Float((motion?.attitude.yaw)!))
        self.orientationBuffer = [(motion?.attitude.pitch)!, (motion?.attitude.roll)!, (motion?.attitude.yaw)!]
        
        let mag = fabs((motion?.userAcceleration.x)!)+fabs((motion?.userAcceleration.y)!)+fabs((motion?.userAcceleration.z)!)
        
        if(mag > self.magValue) {
            print(mag)
            self.backQueue.addOperation({() -> Void in self.motionEventOccurred(mag:mag)})
        }
    }
    
    func startCMMonitoring(){
        if self.cmMotionManager.isDeviceMotionAvailable {
            // update from this queue
            self.cmMotionManager.deviceMotionUpdateInterval = UPDATE_INTERVAL
            self.cmMotionManager.startDeviceMotionUpdates(to: backQueue, withHandler:self.handleMotion)
        }
    }
    
    func motionEventOccurred(mag:Double) {
        let data = self.ringBuffer.getDataAsVector() as NSArray
        if data[0] as! Double == 0.0 {
            print("not full full")
        } else {
//            self.getPredictionData(data: (self.orientationBuffer.getDataAsVector()) as NSArray ) // OLD PREDICTION
            print(data)
            var i = 0
            var cummulativeMag = 0.0
            while i < data.count {
                cummulativeMag += fabs(data[i] as! Double)+fabs(data[i+1] as! Double)+fabs(data[i+2] as! Double)
                i += 3
            }
            cummulativeMag /= (Double(data.count/3))

            self.predictUsingModel(data: self.orientationBuffer,mag:cummulativeMag)
            
        }
    }
    
    func predictUsingModel(data:[Double],mag:Double) {
        let accelerationData = self.ringBuffer.getDataAsVector() as NSArray
        let pred = svm.classifyOne(data)
        
        var prediction = ""
        print("PREDICTION: ", pred)
        switch pred {
        case 1:
            prediction = "Gesture 1"
            if accelerationData[11] as! Double > -0.5 {
                prediction = "WRONG 1"
            }
//            else if accelerationData[11] as! Double > accelerationData[9] as! Double{
//                prediction = "Gesture 2"
//            }
        case 2:
            prediction = "Gesture 2"
            if accelerationData[9] as! Double > -1.0 && (fabs(accelerationData[10] as! Double) > fabs(accelerationData[9] as! Double) || fabs(accelerationData[11] as! Double) > fabs(accelerationData[9] as! Double)) {
                prediction = "WRONG 2"
            }
        case 3:
            prediction = "Gesture 3"
            if 0.3 > accelerationData[11] as! Double {
                prediction = "WRONG 3"
            }
        default:
            print("wrong label!")
        }
        if let gesture = drumKits[selectedDrumKit].gestures[prediction] {
            let instrument = gesture.instrument
            
            let date = self.players[instrument]!["time"] as! Date
            let now = Date()
            let seconds = now.timeIntervalSince(date)
            
            if seconds > TIME_DELAY {
                self.players[instrument]!["time"] = now
                self.players[instrument]!["index"] = ((self.players[instrument]!["index"] as! Int)+1)%3
            }
            
            let player = (self.players[instrument]!["players"] as! Array<AVAudioPlayer>)[self.players[instrument]!["index"] as! Int]
            
            
            
            var adjustedMag = mag
            if mag >= self.maxMagValue {
                adjustedMag = self.maxMagValue-0.1
            }
            
            //adjust for volume
            player.volume = log2(Float(adjustedMag) / Float(self.maxMagValue))/log2(10)+1
            
            player.play()
        }
        else {
            print("Gesture not in use.", prediction)
        }

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
        
        let features = [[0.1927402, -1.339814, 0.981847], [0.18788, -1.185445, 0.9608067], [0.1884118, -0.9225742, 0.9288566], [0.1769582, -0.7990825, 0.9208634], [0.1597085, -0.5818297, 0.904695], [0.138394, -0.3453415, 0.8832368], [0.1540525, -0.03293601, 0.8299391], [0.1380265, 0.1225157, 0.7824301], [0.1212493, 0.1880005, 0.7073172], [0.07856233, 0.2888171, 0.5198279], [0.06129582, 0.1483526, 0.3766977], [0.04004546, -0.1281626, 0.2542105], [0.04248419, -0.3668215, 0.1509939], [0.09671733, -0.8740592, 0.04116748], [0.1102066, -1.062368, -0.03823522], [0.1215336, -1.190509, -0.1297533], [0.1531063, -1.441042, -0.3309127], [0.105246, -1.141169, -0.4963723], [0.07315483, -0.7749969, -0.6794466], [0.07189995, -0.5787749, -1.005536], [0.006723443, -0.2499431, -1.236057], [-0.01357356, -0.06456665, -1.499733], [-0.01651181, -0.03249007, -1.860241], [0.01665248, -0.110363, -2.070905], [0.0722711, -0.2779844, -2.239714], [0.1224859, -0.3913474, -2.468451], [0.1918129, -0.6718974, -2.578656], [0.2026244, -0.8139902, -2.617898], [0.1911971, -1.06207, -2.570316], [0.1483843, -1.38927, -2.580324], [0.1353973, -1.40995, -2.665221], [0.09504738, -1.045501, -2.829573], [0.05672505, -0.699186, -2.997013], [-0.1125112, -0.3683408, 3.033122], [-0.2301443, -0.2385775, 2.846699], [-0.3277235, -0.3042794, 2.68387], [-0.39914, -0.5151742, 2.517151], [-0.1983801, -0.6985071, 2.468911], [0.09949835, -0.6687629, 2.407811], [0.2808053, -0.7113474, 2.371014], [0.1237236, -0.990518, 2.396025], [-0.1076306, -1.20572, 2.364202], [-0.1587171, -1.34859, 2.11041], [-0.156957, -1.453754, 1.906205], [0.1914793, -1.262137, 1.172782], [-0.02272421, -0.9065078, 1.127827], [-0.2000724, -0.6073343, 1.027924], [-0.2806979, -0.4418713, 0.9359039], [-0.08922306, -0.3099584, 0.8183712], [0.5419424, -0.4140735, 0.5314031], [0.5345545, -0.4220795, 0.3650727], [0.03558247, -0.1694661, 0.1496811], [-0.1060268, -0.1621651, -0.02209347], [0.4207807, -0.6730987, -0.1320524], [0.4611191, -1.028128, -0.1162849], [0.2240665, -1.432058, -0.2311109], [0.02728697, -1.131254, -0.4722672], [-0.116647, -0.634939, -0.9111575], [-0.01413543, -0.4439882, -1.296562], [0.5542433, -0.4734539, -1.490078], [0.7616539, -0.5410151, -1.653819], [1.404978, -1.178373, -0.6149796], [1.381895, -1.300232, -0.4455243], [1.372498, -1.301717, -0.2677779], [1.125372, -1.189484, 0.01762925], [1.198763, -1.20801, 0.255857], [1.46119, -0.5166294, -0.1644316], [1.36501, 1.224392, -1.677488], [1.439365, 1.279247, -1.572474], [1.550372, -1.373339, 1.283154], [1.467212, 2.106068, -1.681404], [1.407459, 1.778214, -1.135498], [1.309862, 1.403925, -0.300022], [1.197842, 1.47639, -0.1419999], [1.077028, 1.499111, -0.03299962], [1.095586, 1.450426, 0.11944], [1.138691, 1.624224, 0.08563247], [1.050297, 1.653198, 0.2234399], [1.080667, 1.7848, 0.4248549], [1.192828, 1.587763, 0.9675721], [1.306671, 1.693463, 1.10665], [1.085035, 1.626109, 1.530218], [1.11876, 1.552732, 2.07926], [1.211005, 1.4219, 2.562093], [1.071569, 1.286677, -2.749404], [1.080395, 1.403968, -3.118405], [1.058726, 1.380938, 2.939113], [0.9392068, 1.184426, 2.643138], [0.9376488, 1.187226, 2.321812], [0.9363671, 1.161864, 2.059076], [0.8776446, 1.123757, 1.909874], [0.1810643, -1.909219, 1.341364], [0.1682665, -1.992195, 1.35691], [0.168599, -2.377717, 1.495739], [0.140637, -2.681167, 1.605482], [0.04932081, -2.928097, 1.699347], [-0.02859037, 3.106978, 1.751549], [-0.01782523, 3.00619, 1.761297], [-0.0818858, 2.977801, 1.714764], [-0.08767375, 3.019909, 1.580652], [0.04804909, -2.52772, 1.264163], [0.01270829, -2.203327, 0.9711349], [0.02455354, -2.478341, 0.9453428], [0.01406946, -3.01323, 0.5700706], [-0.01876578, 3.056983, 0.3189988], [-0.04508765, 2.941452, 0.2116951], [-0.0053991, 2.884994, 0.2104963], [0.1354906, -2.988266, 0.0633329], [0.1908389, -2.460403, -0.2157429], [0.1573762, -2.724146, -0.1744662], [0.1253558, 3.061389, -0.2231422], [0.09462123, 2.922869, -0.4151103], [0.0818233, 2.877344, -0.592719], [-0.02584108, 2.888501, -0.8503299], [0.02733511, -3.032893, -0.9704501], [0.009602111, -2.84195, -1.133175], [0.1270769, -2.68847, -1.226824], [0.2151543, -2.698557, -1.332647], [0.1100627, 3.122592, -1.259956], [-0.009076158, 2.894295, -1.406677], [-0.07716483, 3.048921, -1.76989], [-0.1478451, -2.922085, -1.955391], [-0.279035, -2.756634, -2.079859], [-0.007135186, -2.307527, -2.145653], [0.0302104, -2.924815, -2.015891], [0.00541537, 3.127649, -2.101214], [0.002364528, 3.059313, -2.219052], [0.003372238, -2.127389, 0.9693691], [0.00410833, -2.136684, 0.9498239], [0.05710578, -2.682447, 1.288984], [0.1142594, 2.963413, 1.668246], [0.1631033, -2.93154, 1.625615], [0.1078025, -2.286122, 1.600311], [0.08180065, -2.03161, 1.816123], [0.1331122, -2.165155, 1.954497], [0.2110729, -2.893556, 2.493919], [0.1906222, 3.119341, 2.774938], [0.1780859, 2.962929, 2.964387], [0.1667672, 3.045388, 3.007974], [0.2209198, -2.381813, 2.891637], [0.1971088, -2.291154, 2.960315], [0.109746, -2.882393, -2.986551], [0.08910755, 3.064147, -2.792862], [0.08457949, 2.870851, -2.545081], [0.1535108, -3.121764, -2.430076], [0.2036753, -2.722708, -2.390161], [0.2755493, -2.746492, -2.284417], [0.1326298, 2.824984, -2.040125], [0.07773166, 2.69804, -2.002038], [0.04669991, 2.668584, -1.976953], [0.1193729, -3.049845, -2.055267], [0.111872, -2.555286, -1.986207], [0.06913193, -2.651505, -1.81503], [0.009420991, -3.140521, -1.470016], [0.00395479, 3.04768, -1.445653], [-0.02539535, 2.912136, -2.720463], [-0.1145805, 2.783067, -1.942888], [-0.1375385, 2.790631, -1.761428], [-0.1223519, 2.751905, -1.66185], [-0.02378772, 2.665194, -1.416652], [-0.07243676, 2.683587, -1.655757], [-0.1250206, 2.586203, -2.017153], [-0.05649001, 2.355631, -2.570474], [-0.001115984, 2.376464, -2.979451], [0.1386702, 2.447958, 2.616911], [0.1916338, 2.497378, 1.820473], [0.190697, 2.484938, 1.197834], [0.1838902, 2.56518, 0.7437924], [0.1092188, 2.725, -0.344139], [0.02433744, 2.526279, -0.8657679], [-0.042839, 2.500779, -1.213091], [-0.1445416, 2.403799, -1.616014], [-0.1009751, 2.334628, -2.104885]]
        
        let labels = ["Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3"]

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
    }
    
    
    
    
    
    
}
