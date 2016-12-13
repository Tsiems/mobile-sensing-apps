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
        
        //let features = [[0.06278694, -0.2366883, 1.366925], [0.03600541, -0.3179298, 1.269413], [0.09346908, -0.2429357, 0.5130546], [0.09044877, -0.1429756, 0.07009634], [0.09666088, -0.08250668, -0.1175281], [0.04570067, -0.2705097, -0.3666651], [0.09021948, -0.2372268, -0.7529148], [0.09177287, -0.160827, -0.9128498], [0.07624996, -0.2718243, -1.467646], [0.07776216, -0.19363, -1.801883], [0.02358258, -0.1168732, -2.309562], [-0.0474959, -0.1996148, -2.64853], [-0.02131744, -0.2370162, -2.951012], [-0.04264713, -0.2355583, 2.995742], [-0.01185074, -0.2488868, 2.652731], [-0.007622234, -0.4029818, 2.104435], [0.03553493, -0.3959875, 1.855738], [-0.04875663, -0.2465354, 1.738328], [0.01132018, -0.3743068, 1.214708], [0.08690486, -0.314402, 0.9391025], [1.196976, -1.480041, 0.01896074], [1.413731, -0.6466523, -0.8463041], [1.454486, -1.517841, -0.4519777], [1.44749, -2.010091, -0.3051102], [1.414228, -2.460191, -0.46455], [1.470388, -2.470818, -0.9893695], [1.544078, -1.014387, -2.766625], [1.373003, -1.222528, 0.3628598], [1.412084, -0.2347084, -0.1196413], [1.421751, -0.03012505, 0.7328053], [1.455625, -0.1495479, 1.222505], [1.435508, 0.1382724, 1.880403], [1.337821, 0.6627162, 2.240508], [1.471242, 2.631086, 0.751507], [0.04737604, -2.846486, 1.008268], [0.0476237, -2.88052, 1.072101], [0.1361181, -2.963562, 1.42614], [0.2450206, -3.021701, 1.702802], [0.3983521, 2.940741, 2.359928], [0.3179671, 2.560787, 3.065631], [0.0148655, 2.574017, -2.492094], [-0.1181247, 2.822094, -2.010565], [-0.1136908, 2.890128, -1.380211], [-0.06709059, -3.022502, 1.380631], [-0.1555129, -3.086637, 0.8052576], [-0.1641478, 3.130234, 0.2425927], [-0.06201035, 3.019584, -0.5625544], [0.03632166, 2.935819, -0.7751741], [-0.1099294, 2.933264, -1.222883], [-0.148628, 3.027323, -0.7245238]]
        
        //let labels = ["Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3"]
        
        //let features = [[0.2180023, -0.1567728, 1.171951], [0.176761, -0.108693, 1.31564], [0.1911466, -0.1088195, 1.46487], [0.1904278, -0.09565694, 1.306505], [0.270494, -0.0872338, 1.184084], [0.219439, -0.0301172, 0.9506487], [0.2045598, 0.05185134, 0.576887], [0.2069998, -0.0150214, 0.3828483], [0.2716056, 0.03425968, 0.3088328], [0.05333914, -0.2069202, 0.1063529], [0.4366736, -0.08811253, -0.08347781], [0.9840428, -0.004973927, -1.30653], [0.7693877, 0.07505733, -1.184406], [0.3623561, 0.09810463, -0.7848198], [0.04777956, 0.03112624, -0.7106636], [0.1120308, -0.08476231, -0.6968496], [0.05183097, -1.060462, -0.5768309], [0.1115533, -1.061518, -0.5422296], [0.09279652, -0.3929849, -0.5959527], [0.2377141, 0.02314837, -0.8039002], [0.09924645, -0.1463231, -2.312861], [0.1833976, -0.3465244, -2.5521], [0.1563174, -0.6734857, -2.610632], [0.2149936, -1.078939, -2.676744], [0.1821154, -0.983142, -3.136846], [0.1222675, -0.3372453, 2.953875], [0.1324531, -0.1458427, 2.504306], [0.04661694, -0.1899033, 2.277971], [0.07402372, -0.1839346, 2.334397], [0.239809, 0.002196477, 2.984539], [0.2120293, -0.115962, -2.938725], [0.232039, -0.3167933, -2.683265], [0.1181872, -0.7290662, -2.564053], [0.1386901, -0.8916484, -2.486119], [0.2132689, -0.8619316, -2.465122], [0.2832305, -0.2467143, 0.811248], [0.3718844, -0.1015784, 0.9207304], [0.2867449, -0.2395701, 1.00794], [0.2413197, -0.4015156, 1.365846], [0.2634856, -0.3741275, 1.59482], [0.2418492, -0.3869335, 1.707699], [0.3759842, -0.5007143, 1.915951], [0.3067763, -0.8400892, 2.17276], [0.2735151, -1.013177, 2.265545], [0.3274037, -1.283846, 2.412238], [0.3064081, -0.7948371, 2.295811], [0.2355553, 0.003353663, 2.05817], [0.2611606, 0.7556566, 2.045983], [0.1378048, 0.5358375, 2.174996], [0.1682663, 1.050804, 2.191309], [0.1769129, 0.696036, 2.23829], [0.3623594, 0.2768674, 2.305444], [0.4927464, -0.3155373, 2.576673], [0.3101919, -0.8288119, 2.945245], [0.4671262, -0.9131023, 3.101742], [0.4664826, -0.9169347, 3.090941], [0.3671888, -1.038504, -3.047837], [0.3442126, -0.8001027, -3.128459], [0.391761, -0.2679718, 3.005184], [0.3844996, 0.05145558, 2.889282], [0.1263935, 0.2321598, 2.653991], [0.2767221, 0.4248635, 2.594363], [0.2467509, 0.8461102, 2.500058], [0.2057073, 0.8979077, 2.420526], [0.2035043, 0.9342247, 2.387111], [0.5355076, 0.1694559, 2.558026], [0.5219026, -0.3223729, 2.912183], [0.4164236, -0.7347497, 2.993456], [0.3954677, -0.9488371, 2.903238], [0.1736952, 0.02578108, 2.519983], [0.2187861, 0.9369097, 2.343997], [0.2780969, 1.206916, 2.286441], [0.3056741, 1.21975, 2.279835], [0.6118072, 0.07373572, 1.854216], [0.2523741, -0.2307611, 2.233587], [0.5053605, -0.3892333, 2.178633], [0.4498435, -0.6422468, 2.263638], [0.3447533, -0.4584369, 2.680055], [0.3601961, -0.4950206, 2.9014], [0.4280388, -0.366867, 3.113971], [0.2722299, -0.07571702, 3.140486], [0.2198928, 0.5029458, 2.926725], [0.1532287, 1.10842, 2.630166], [0.1783236, 1.478015, 2.392605], [0.3153022, 0.5713215, 2.290369], [0.4955812, -0.4776204, 2.324683], [0.3936308, -1.162898, 2.328904], [0.3314041, -0.9701439, 1.996696], [0.2174775, -0.5944138, 1.609513], [0.167215, -0.0897694, 1.328425], [0.2136361, 0.2920104, 1.065894], [0.2263909, 0.6817463, 0.8294083], [0.1450835, 0.577316, 0.6311632], [0.2265332, -0.2275218, 0.7761413], [0.3092526, -0.8312373, 1.242048], [0.3008982, -0.9614996, 1.389419], [0.2457166, -0.4904547, 1.056587], [-0.1810496, -0.1481751, 0.9825663], [-0.3508179, -0.06677016, 0.9320201], [0.195653, 0.05514465, 0.868975], [0.4649646, 0.2258335, 0.7988955], [0.5287941, 0.05860103, 0.8095314], [0.2993797, -0.2087512, 0.9279544], [0.1129252, -0.397856, 1.077965], [0.06766058, -0.379485, 1.046696], [0.2550108, -0.2369143, 0.9165133], [0.5646803, -0.07282967, 1.289776], [0.6075148, -0.03021272, 1.635037], [0.7107451, 0.001124277, 2.160003], [0.5550846, -0.02044925, 2.44897], [0.1405786, -0.04147121, 2.917591], [-0.02649038, -0.06278603, -3.030825], [-0.03801351, -0.0338681, -2.756664], [-0.2260542, -0.09347664, -2.267629], [0.2688331, -0.06741086, -2.125409], [0.5205778, -0.189466, -2.044164], [0.6064895, -0.3459744, -1.729135], [0.3129128, -0.2570294, -1.534176], [0.0793916, -0.1340542, -1.492624], [-0.2822619, -0.05533066, -1.400219], [-0.2347453, -0.04863452, -1.274682], [0.1326724, -0.07965753, -1.266589], [0.5570689, -0.5086162, -0.5387526], [0.6009676, -0.4876631, -0.3079784], [0.578459, -0.3339182, -0.3597778], [-0.1896397, -0.2208639, -0.6062268], [1.424229, 0.7793357, -2.237308], [1.380831, -0.1375825, -1.262602], [1.235114, -0.8330683, -0.762681], [1.342327, -0.7324365, -0.8981031], [1.34772, -0.9629019, -0.6900549], [1.317182, -1.333567, -0.2997129], [1.341227, -0.9961696, -0.6313], [1.27488, -0.4842352, -1.006618], [1.336185, -0.1679503, -1.116987], [1.373516, -0.4683969, -0.6973635], [1.273142, -0.989163, -0.07111131], [1.343325, -0.7781156, -0.01657229], [1.347224, -0.7360219, 0.1902828], [1.334787, -0.06604277, -0.2403941], [1.317471, -0.05973213, 0.007707917], [1.367598, -0.370319, 0.6320583], [1.236105, -0.4929256, 0.9550098], [1.290139, -0.4049132, 1.079133], [1.285468, -0.3636817, 1.231079], [1.230157, -0.3727136, 1.430179], [1.178327, -0.4487698, 1.597929], [1.263825, -0.2234522, 1.548428], [1.333459, -0.1789738, 1.829937], [1.280982, -0.3929704, 2.528857], [1.201921, -0.6425467, 2.973421], [1.253528, -0.840034, 3.026521], [1.274042, -1.088302, -3.043298], [1.393772, -0.4200994, 2.651042], [1.312617, 0.8588636, 1.369897], [1.36995, 1.017747, 1.260331], [1.209083, 1.154956, 1.072514], [1.391322, -0.5562925, 2.857068], [1.333516, -1.202165, -2.702382], [1.365773, -1.523571, -2.071681], [1.330325, 0.107602, -1.130259], [1.299039, -0.4831882, -0.8175765], [1.357144, -0.5190579, -1.102536], [1.364776, -0.4170493, -1.329155], [1.371527, -0.62276, -1.240264], [1.318701, -0.4651331, -1.506304], [1.303439, -0.6173925, -1.482872], [1.333535, -0.4338246, -1.744745], [1.340158, -0.2224684, -1.964189], [1.346754, -0.4692633, -1.779427], [1.232771, -0.7872824, -1.578944], [1.312238, -0.3297969, -2.021662], [1.276756, -0.3580296, -1.969407], [1.287319, -0.3911408, -1.941497], [1.140614, -0.6573673, -1.762551], [1.266285, -0.4782982, -2.07462], [1.307495, -0.2519172, -2.239797], [1.285565, -0.3615563, -2.138331], [1.239255, -0.5567754, -2.014049], [1.038757, -0.8595659, -1.881664], [1.279829, -0.5771485, -2.130578], [1.292972, -0.5920616, -2.160004], [1.319668, -0.5455688, -2.221414], [1.316289, -0.5688658, -2.314286], [1.172323, -0.6691375, -2.394455], [1.178532, -0.6192764, -2.506366], [1.155239, -0.487941, -2.722859], [1.167664, -0.4424759, -2.803974], [1.201746, -0.8122566, -2.674301], [1.239998, -0.8464405, -2.701764], [1.239519, -0.8061399, -2.787414], [1.274323, -0.5455959, -3.032871], [1.29168, 0.3160385, 2.675082], [1.270575, 0.8041475, 2.601074], [1.387051, -0.03672243, -2.423417], [1.235648, -0.6069608, -1.424737], [1.378197, 0.1613915, -2.174297], [1.207274, -0.6304685, -1.302896], [1.211073, -0.8024831, -1.125498], [1.351661, -0.5938132, -1.282557], [1.338246, -0.6765195, -1.108433], [1.265025, -0.9572604, -0.7888886], [1.236902, -0.9830761, -0.698005], [1.285082, -1.066729, -0.5082749], [1.458013, -0.7082449, -0.9077867], [1.384313, -0.3055063, -2.554407], [1.168517, -0.8602279, -2.44254], [1.336751, -0.3836555, -3.066187], [1.337143, -0.4915213, 3.00754], [1.149106, -0.7583339, 2.966691], [1.29452, -0.2194454, 2.488875], [1.280532, -0.3636766, 2.578692], [0.2123947, -2.214807, 1.479861], [0.153837, -2.652802, 1.569717], [0.3080111, -2.493307, 2.166842], [0.06897656, -2.53798, 2.366498], [0.1575701, -2.529043, 2.359626], [0.7120258, -2.078294, 2.150896], [0.6241165, -2.308336, 2.417455], [0.4211998, -2.474294, 2.497312], [0.298265, -2.431938, 2.633897], [0.4723361, -2.328846, 2.731259], [0.3619978, -2.474131, -3.045249], [0.44168, -2.524612, -2.8896], [0.3596695, -2.523254, -2.689378], [0.4828004, -2.606247, -2.53956], [0.1840808, -2.711746, -2.216609], [0.007039602, -2.558122, 2.92382], [0.2099595, -2.53181, 2.951385], [0.3029006, -2.461465, -3.133609], [0.1642218, -2.509924, -2.937954], [0.08458776, -2.558487, -2.677597], [-0.06573464, -2.605216, -2.472278], [-0.05514985, -2.652525, -2.175176], [0.04472907, -2.670033, -2.195011], [0.2494573, -2.602719, -2.477557], [0.1678149, -2.353216, -3.000242], [0.199729, -2.412556, 3.134608], [0.1143526, -2.098708, 3.126415], [0.1503794, -1.864709, 3.067107], [0.1900622, -2.050289, 3.091372], [0.2182031, -2.430544, 3.0614], [0.2616611, -2.51818, 2.89219], [0.1350453, -2.737734, 2.609024], [0.06279545, -2.605657, 2.077426], [0.1215278, -2.601082, 1.816481], [0.05349112, -2.291625, 1.386729], [0.1576184, -1.98746, 1.188607], [0.1946991, -1.987601, 1.103632], [0.09947007, -2.400382, 0.9585774], [0.2062694, -2.458892, 0.8739499], [0.02230686, -2.705911, 0.6364088], [0.1055849, -2.561972, 0.2325484], [0.174649, -2.275962, -0.08034486], [0.1794292, -2.228648, -0.2678969], [0.2160986, -2.005795, -0.4592536], [0.1788643, -1.835443, -0.6100066], [0.1711454, -1.943251, -0.6120951], [0.2089694, -2.260077, -0.5271891], [0.03564583, -2.654573, -0.5533081], [-0.002797194, -2.676618, -0.6890808], [-0.1768877, -2.957899, -0.7548652], [-0.2747318, -3.087232, -0.8490642], [-0.05350875, -2.619812, -0.9750898], [0.07063553, -2.061735, -0.9689764], [0.08081767, -2.294984, -1.331317], [-0.07960776, -2.574805, -1.490234], [-0.2067006, -2.727818, -1.746342], [-0.2420804, -2.775682, -1.989874], [-0.06754512, -2.416559, -2.030172], [-0.02540333, -2.121704, -1.971189], [0.001817222, -1.842967, -1.992436], [0.04820475, -1.803658, -2.111733], [0.06362845, -1.966755, -2.137194], [0.01027396, -2.497895, -2.093258], [0.04513527, -2.82391, -2.403517], [0.1471272, -2.807516, -2.504403], [0.2897168, -2.689149, -2.544164], [0.1786991, -2.683647, -2.505253], [-0.1154934, -2.786134, -2.453821], [-0.4356424, -2.862174, -2.457966], [-0.2515887, -2.768708, -2.339765], [0.1441988, -2.613992, -2.222507], [0.3139649, -2.531519, -2.153014], [0.2966705, -2.533213, -2.06495], [0.1245542, -2.605431, -2.085944], [0.006668367, -2.581359, -2.890006], [-0.1954012, -2.649205, -3.019153], [-0.2716399, -2.776011, 2.947453], [0.0825773, -2.634761, 2.964731], [0.1742105, -2.590305, 3.079367], [0.1494236, -2.590639, -3.039752], [0.0006760836, -2.391692, -1.624372], [-0.3416012, -2.600587, -1.568558], [-0.3010285, -2.648042, -1.511787], [-0.02399152, -2.535167, -1.453874], [0.1373004, -2.479024, -1.268489], [0.02469343, -2.411968, -1.145941], [-0.2214539, -2.476124, -0.9265125], [-0.4001426, -2.538699, -0.7537311], [-0.3598512, -2.549735, -0.6604097], [-0.1763906, -2.532007, -0.6189067], [-0.04109609, -2.544486, -0.5749671], [0.06897838, -2.53808, -0.5640195], [-0.04405864, -2.583035, -0.5269834], [-0.2505419, -2.571316, -0.5023667], [-0.3708645, -2.551425, -0.4095837], [0.222832, -2.445956, -0.08315278], [0.1409867, -2.50543, 0.1054839], [0.0616831, -2.576268, 0.3120256], [0.1065029, -2.392555, 0.6969376], [-0.01796102, -2.610147, 0.6403406], [0.01872867, -2.63736, 0.5842488], [0.2374543, -2.569765, 0.6142765], [0.2512876, -2.485377, 0.6387169], [0.07471906, -2.504705, 0.7376398], [-0.3337666, -2.494927, 0.8807636], [-0.40253, -2.534443, 0.9985413], [-0.2166801, -2.587524, 1.027147], [0.2333359, -2.574235, 1.043122], [0.2847227, -2.51482, 1.033737], [0.06954248, -2.518528, 1.14048], [-0.1233902, -2.508197, 1.181893], [-0.1741482, -2.526544, 1.202305], [0.3752745, -2.547825, 1.325735], [0.2863315, -2.595057, 1.526599], [0.3304395, -1.527716, 1.019372], [-0.08088886, -2.458621, 1.204557], [0.038664, -2.025443, 1.014567], [0.05666602, -2.105994, 0.9620535], [0.04069855, -2.466439, 0.9460698]]
        
        //let labels = ["Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3"]
        
//        let features = [[0.07623456, -0.09142848, 0.8370885], [-0.03671428, -0.1370577, 0.8256841], [-0.008572277, -0.2023097, 0.7308348], [-0.06074278, -0.1603644, 0.6436754], [0.005912619, -0.06277346, 0.5560733], [-0.1548783, -0.1785277, 0.5042226], [-0.2169189, -0.1866105, 0.6382416], [-0.02781715, -0.1585404, 0.6449025], [0.03047385, -0.0545162, 0.5876888], [0.006212509, 0.2249936, 0.5243666], [-0.08938604, 0.2463478, 0.4968036], [0.001712763, 0.3222975, 0.4291964], [0.02462205, 0.4093269, 0.3312264], [0.08304981, 0.4339753, 0.3076316], [0.008926753, 0.2842512, 0.2977722], [-0.05178554, -0.005177378, 0.3801471], [-0.05979854, -0.3659642, 0.3832939], [0.2268138, -0.3953694, 0.4526007], [0.3906165, -0.2950549, 0.4934287], [0.3635199, -0.2730883, 0.6182702], [0.4936476, -0.312425, 0.6623415], [0.4037229, -0.3050974, 0.6997358], [0.4212868, -0.457756, 0.7487338], [0.5215003, -0.5199884, 0.8401114], [0.2188626, -0.2560777, 0.74534], [-0.02011549, -0.2145775, 0.7002766], [0.003256923, -0.3375048, 0.9040401], [-0.159904, -0.2166326, 0.7278507], [-0.1109648, -0.251231, 0.6775195], [-0.02589717, -0.5909548, 0.7602817], [0.05849962, -0.6684055, 0.8146624], [0.1004228, -0.8154515, 0.9493015], [0.1831519, -0.9658872, 1.002735], [0.2342618, -1.040913, 1.067916], [0.2079097, -1.275202, 1.099563], [0.2647403, -1.294754, 1.131748], [0.2212611, -1.054632, 1.074847], [0.2124729, -1.086313, 1.07691], [0.2893248, -1.117205, 1.137355], [0.2770698, -1.006174, 1.108811], [0.2048955, -0.9974127, 1.048572], [0.2672971, -0.7389896, 1.019358], [0.2154534, -0.5719461, 0.9747657], [0.2067753, -0.3563031, 0.920146], [0.2459765, -0.1947954, 0.8721945], [0.2254517, 0.0190057, 0.8206437], [0.09534408, 0.0814129, 0.8705863], [0.06263223, 0.01464604, 0.8276483], [-0.0131179, -0.1262009, 0.7560133], [-0.1468404, -0.1428719, 0.7510964], [-0.1252517, -0.1041169, 0.709195], [-0.1030142, -0.1377312, 0.6628914], [0.1831351, -0.1368041, 0.6884535], [0.3538288, -0.2589524, 0.7512267], [0.555347, -0.3274411, 0.7640405], [0.5781507, -0.2112636, 0.7591479], [0.1772677, 0.1176568, 0.6719987], [0.2360861, 0.2403607, 0.6548785], [0.06202585, 0.1889857, 0.6295203], [-0.08685116, 0.1019201, 0.5398511], [0.01803384, 0.2424219, 0.5135102], [-0.04574984, 0.1653787, 0.5229093], [0.05170703, 0.2731402, 0.3868382], [0.1040106, 0.1586925, 0.1806683], [0.2439181, 0.1546243, -0.2074416], [0.2843181, 0.1891825, -0.2982281], [0.2833245, 0.1790643, -0.4799182], [0.1361741, 0.2744956, -0.8057615], [0.09659253, 0.4670245, -0.9900867], [0.1772909, 0.5676795, -0.9586573], [0.1900465, 0.4378221, -0.9110627], [0.2168731, 0.6261923, -0.9740285], [0.2910635, 0.6925192, -1.032135], [0.2455302, 0.7485778, -1.134716], [0.3258115, 0.8423131, -1.177787], [0.2441436, 0.7223421, -1.181592], [0.3135259, 0.734437, -1.184125], [0.3003706, 0.6947261, -1.177781], [0.2929805, 0.2071003, -0.947146], [0.330002, -0.1054717, -0.6351911], [0.4174799, -0.194021, -0.4457516], [0.3652936, -0.6064602, -0.09069234], [0.3530783, -0.7368917, 0.1757508], [0.3420258, -0.8277583, 0.3386972], [0.3520598, -0.9112042, 0.4721712], [0.3609657, -1.014119, 0.5641745], [0.3441527, -1.040696, 0.6144307], [0.3523917, -0.9414535, 0.5446278], [1.552435, -2.688983, 1.29106], [1.507288, 2.533526, 2.376859], [1.532489, 2.150874, 2.71833], [1.491656, 1.85791, 3.019354], [1.532826, 1.379305, -2.804216], [1.544973, 2.80238, 2.083644], [1.507806, -1.327251, -0.1074621], [1.466973, -1.305065, -0.08561919], [1.509029, -1.299809, -0.04199469], [1.362013, -1.709949, 0.271849], [1.319523, -1.685959, 0.3237725], [1.331294, -1.450954, 0.08379665], [1.255821, -0.987784, -0.3094297], [1.233831, -0.6765496, -0.631419], [1.318182, -0.226355, -1.053117], [1.289158, 0.4779307, -1.801334], [1.216865, 0.7056742, -2.034464], [1.168847, 0.7437629, -2.046281], [1.092768, 0.5702171, -1.852265], [1.128312, 0.4682621, -1.867227], [1.196682, 0.4741488, -1.938719], [1.434313, 0.2284608, -1.808351], [1.490227, 0.0002145562, -1.506853], [1.289911, -1.065931, -0.1802347], [1.267191, -1.584002, 0.3184102], [1.305681, -1.755416, 0.38521], [1.200076, -1.761713, 0.3546928], [1.201304, -1.797526, 0.4282842], [1.111322, -1.588959, 0.1621116], [1.152623, -1.553321, 0.1743638], [1.324622, -1.491495, 0.1663349], [1.412753, -1.075747, -0.2437082], [1.515625, -0.2464927, -1.107535], [1.507275, 0.4603407, -1.856019], [1.348048, 1.431302, -2.836679], [1.278206, 1.308681, -2.744828], [1.260016, 1.370439, -2.805848], [1.35907, 1.460374, -2.902015], [1.502922, 1.539103, -2.968876], [1.507966, 1.350552, -2.745272], [1.507505, -0.7222749, -0.6310623], [1.383966, -1.369127, -0.03535152], [1.371965, -1.614726, 0.2699806], [1.363736, -1.786428, 0.464062], [1.293644, -1.717985, 0.3772061], [1.280714, -1.484135, 0.103126], [1.350522, -1.439196, 0.1180042], [1.358019, -1.691838, 0.455989], [1.323592, -1.734617, 0.4301051], [1.346571, -1.784873, 0.4610014], [1.344202, -1.548185, 0.260922], [1.304019, -1.637503, 0.277356], [1.324667, -1.954558, 0.5700305], [1.377758, -1.721341, 0.3202019], [1.328884, -1.658319, 0.2103029], [1.255685, -1.629431, 0.1733823], [1.348422, -1.585773, 0.1820568], [1.276808, -1.570047, 0.1536604], [1.23443, -1.796485, 0.387383], [1.27356, -2.11789, 0.753186], [1.335985, -2.231686, 0.9077314], [1.466488, -1.874598, 0.6098789], [1.326354, 0.04709648, -1.281524], [1.2217, 0.02834048, -1.306568], [1.220833, 0.1739273, -1.449859], [1.182962, 0.240985, -1.553458], [1.213677, 0.1801554, -1.542139], [1.348554, -0.299809, -1.177155], [1.381293, -0.2157679, -1.244067], [1.367412, -1.145042, -0.3454487], [1.394611, -1.408677, -0.04394846], [1.34751, -1.633884, 0.1816872], [1.320091, -1.897308, 0.4698795], [1.301354, -2.01773, 0.5889452], [1.25481, -1.92556, 0.4607499], [1.190894, -2.468272, 0.9887891], [1.201845, -2.387206, 0.9451928], [1.248511, -2.043432, 0.6179992], [1.271511, -1.765495, 0.4010129], [1.230259, -1.571876, 0.1494669], [1.266223, -1.523164, 0.09028117], [1.261221, -1.42536, -0.04818008], [1.322283, -1.248367, -0.236162], [1.29331, -1.229523, -0.2889634], [1.376921, -0.9597911, -0.5494982], [1.329866, -0.8732997, -0.6458983], [1.401377, -0.7038326, -0.793833], [1.332872, -0.8171921, -0.7071427], [1.426529, -0.7820011, -0.7262543], [1.445964, -0.8686507, -0.6394589], [1.492239, 1.331338, -2.78251], [1.41261, 1.81336, 3.03962], [1.514045, 1.761079, 3.063371], [1.479649, -1.566766, 0.08329315], [1.395188, -1.607479, 0.1537686], [1.305604, -1.467281, -0.008407104], [1.103999, -1.506369, -0.02324396], [1.164367, -1.507464, 0.05012238], [1.245775, -1.329191, -0.09472877], [0.1193607, -2.992537, 1.335885], [0.1211148, -2.976967, 1.327367], [0.1325272, -2.977529, 1.315917], [0.1236998, -3.033845, 1.316151], [0.1185103, -2.900578, 1.301467], [0.07808589, -2.851436, 1.302084], [0.1071453, -2.724089, 1.326825], [0.2003294, -2.648999, 1.439133], [0.1157769, -2.553358, 1.451334], [0.1551472, -2.465084, 1.480438], [0.09195508, -2.19868, 1.345232], [0.1510869, -2.198983, 1.399124], [0.2165874, -2.089622, 1.426836], [0.1563178, -2.097933, 1.364308], [0.1851629, -2.08218, 1.41428], [0.1448729, -2.088326, 1.377511], [0.1067936, -2.334193, 1.347597], [0.1370616, -2.451901, 1.391092], [0.03476119, -2.697438, 1.411798], [0.1983965, -2.707847, 1.467909], [0.2554781, -2.917719, 1.505502], [0.3517866, -3.068487, 1.625394], [0.4289914, -3.126487, 1.775398], [0.4328792, 3.027493, 1.84551], [0.3995184, 2.938195, 1.871586], [0.4731829, -2.639539, 1.051865], [0.1074103, -2.790658, 1.039636], [0.1520162, -2.771972, 1.046159], [0.06749169, -2.774588, 0.8543327], [0.1844805, -2.731626, 1.024804], [0.2300201, -2.710727, 1.138822], [0.2417987, -2.657384, 1.160136], [0.4605621, -2.505229, 1.041385], [0.2988235, -2.787147, 1.175064], [0.2406559, -2.785991, 1.123531], [0.2698308, -2.791657, 1.200014], [0.3277039, -2.836412, 1.211479], [0.2756876, -2.819627, 1.17957], [0.3318685, -2.83679, 1.222321], [0.3283114, -2.858252, 1.165263], [0.2334042, -2.862031, 1.15324], [0.2939691, -2.905223, 1.195816], [0.3325206, -2.66037, 1.117025], [0.07753175, -2.854296, 1.149455], [0.1796536, -2.830365, 1.118573], [0.207258, -2.835964, 1.208588], [0.2308059, -2.890262, 1.211297], [0.2102425, -2.943238, 1.226278], [0.1107029, -2.855436, 1.166483], [0.2628958, -2.719457, 1.187474], [0.3644065, -2.55918, 1.257038], [0.3716452, -2.386698, 1.190059], [0.4698519, -2.303364, 1.24118], [0.5999787, -2.078341, 1.295785], [0.2853234, -2.289115, 1.215734], [0.342672, -2.492287, 1.290208], [0.2180003, -2.545735, 1.289492], [0.2969378, -2.562056, 1.36152], [0.4760913, -2.669191, 1.402922], [0.3343454, -2.57793, 1.317218], [0.3866703, -2.695244, 1.342156], [0.4493841, -2.518308, 1.269742], [0.3617775, -2.231967, 1.254015], [0.358457, -2.079282, 1.226935], [0.2241532, -2.393311, 1.245325], [0.2974013, -2.251447, 1.2823], [0.2113847, -2.288242, 1.260299], [0.2111893, -2.56494, 1.319843], [0.1973431, -2.742671, 1.363025], [0.2054261, -2.944948, 1.362945], [0.1724277, -3.050183, 1.336075], [0.2602797, -3.135367, 1.431759], [0.2413431, 3.067194, 1.466573], [0.1948195, -2.68196, 1.341222], [0.1994804, -2.601487, 1.290144], [0.2614028, -2.714915, 1.244641], [0.4673732, -2.851743, 1.328192], [0.2966072, -2.712517, 1.08387], [0.4166176, -2.722982, 1.055903], [0.2424641, -2.736651, 0.9031804], [0.225262, -2.733483, 0.9651702], [0.5282338, -2.457375, 1.111768], [0.4099293, -2.68244, 1.089039], [0.3815941, -2.858352, 1.09105]]
//        let labels = ["Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3"]
        
//        let features = [[-0.01913749, -0.004542652, 1.801186], [-0.02500217, 0.03825141, 1.635734], [-0.02361225, 0.03468514, 1.527347], [0.002309412, 0.002232602, 1.414023], [0.112905, -0.0447836, 1.35955], [0.04277645, 0.1323807, 1.295876], [0.02680377, -0.08638758, 1.286338], [0.05507561, 0.002052903, 1.273452], [0.1131732, -0.04024906, 1.100561], [0.1261612, -0.01793618, 0.6745923], [0.1642934, 0.05173478, 0.6612703], [0.1026895, 0.05019448, 0.3173817], [0.1875514, 0.04220009, 0.002429998], [0.1737864, 0.03605373, -0.03994646], [0.1478182, 0.1065, -0.1255385], [0.1629991, 0.1212949, -0.3141961], [0.0501021, 0.04918524, -0.8944736], [-0.04168113, 0.06972466, -1.08385], [0.07637779, 0.1570637, -1.221475], [-0.01123786, 0.1818731, -1.258583], [-0.02141155, 0.08289415, -1.22045], [-0.1110847, 0.1086161, -1.248227], [0.08294316, 0.1564323, -1.35889], [-0.07558998, 0.1014204, -1.365235], [-0.1250144, 0.1191523, -1.317674], [-0.1043554, 0.07276042, -1.286101], [-0.05449719, -0.008632566, -1.2775], [-0.06524257, 0.03356069, -1.251656], [-0.03237176, 0.159355, -1.282413], [-0.05125149, 0.2096906, -1.358337], [-0.02222669, 0.117007, -1.480838], [-0.07229302, 0.0575294, -1.807523], [-0.0545662, 0.03537144, -1.858357], [-0.0518338, 0.01837898, -1.958103], [0.004746939, 0.01691969, -2.016589], [-0.05826303, 0.05164926, -1.978915], [-0.01173052, 0.07984936, -1.982504], [-0.05337336, 0.1002681, -1.995906], [-0.02246805, 0.005962385, -2.110649], [-0.02661568, 0.08181538, -2.454084], [-0.026304, 0.05123802, -2.477381], [-0.06358012, 0.006710155, -2.452351], [-0.0817245, -0.001458405, -2.471781], [0.1072825, -0.1319473, 1.159638], [0.0688327, -0.1912439, 1.214885], [0.05483164, -0.1753952, 1.285537], [0.02080428, -0.1292652, 1.360358], [-0.04219821, -0.1607454, 1.654235], [-0.03103355, -0.09551981, 1.738979], [-0.09045994, -0.1241587, 1.760632], [-0.09048311, -0.1066826, 1.776396], [0.0001523175, -0.07279407, 1.570107], [0.01896081, -0.06686127, 1.283051], [0.01743655, -0.08623113, 1.058514], [0.06157574, -0.06071595, 0.8924533], [0.08766345, -0.0723437, 0.4970864], [0.05005608, -0.0436529, 0.5141919], [0.01641902, -0.00853518, 0.5279265], [-0.003400865, 0.01840343, 0.4183101],
//         [1.499924, 0.07557607, -1.258702], [1.513752, 1.020253, -2.233016], [1.423258, 0.4522016, -1.684831], [1.443218, 0.8564031, -2.10036], [1.454382, 0.755445, -2.029442], [1.428822, 0.4845724, -1.686946], [1.377481, 0.7691545, -1.67297], [1.372193, 0.8087404, -1.665514], [1.428291, 0.9466934, -1.927847], [1.447019, 0.6854452, -1.784165], [1.44585, 0.5183444, -1.730644], [1.441855, -0.8558058, -0.5500311], [1.431527, -1.291888, -0.1198441], [1.477578, -1.376428, -0.02328826], [1.445064, -0.8336782, -0.5281649], [1.458077, -0.4551925, -0.8858659], [1.349324, -0.4754429, -0.8112588], [1.406006, -0.2940322, -0.5979444], [1.335732, -0.2572086, -0.6982524], [1.329434, -0.05922464, -0.8859679], [1.291057, -0.0761863, -0.8910754], [1.302563, -0.1032925, -0.8978766], [1.418274, -0.2706668, -0.8548265], [1.479272, -2.813722, 1.541382], [1.521693, -1.958241, 0.7066945], [1.378415, -0.4277367, -0.7885871], [1.372061, -0.37155, -0.8408827], [1.322294, -0.3453147, -0.8645086], [1.276084, -0.2998024, -0.8817554], [1.227504, -0.2344419, -0.8907384], [1.263197, -0.1717716, -0.9199029], [1.31961, -0.3888142, -0.751314], [1.331444, -0.5161867, -0.6495116], [1.363799, -0.7445176, -0.4228399], [1.426981, -0.8839309, -0.2821871], [1.455637, 0.8538849, -1.964236], [1.323994, 1.313691, -2.407657], [1.274404, 0.9228685, -1.936076], [1.180738, 0.8621812, -1.842909], [1.115785, 0.8867474, -1.884293], [1.068501, 0.5793965, -1.594808], [1.206642, 0.1999528, -1.364402], [1.401057, -0.185922, -1.066637], [1.48712, -0.06871641, -1.176017], [1.525033, -0.6944684, -0.5414528], [1.512904, -0.8897838, -0.3557838], [1.494381, -1.088335, -0.1605828], [1.425768, -1.55398, 0.3111], [1.30854, -1.598715, 0.4140239], [1.262468, -1.601341, 0.4287618], [1.184247, -1.664919, 0.5094405], [1.137281, -1.727682, 0.612422], [1.128868, -1.617623, 0.5833808], [1.274186, -1.356071, 0.4116955], [1.263067, -0.3307278, -0.6385168], [1.192936, -0.533071, -0.4736494], [1.197157, -0.7760327, -0.3096284], [1.22237, -0.5911251, -0.4896661], [1.374626, -1.859855, 0.7518946], [1.295427, -2.421848, 1.3354], [1.218612, -2.670789, 1.592657], [1.267561, -2.558735, 1.480181], [1.337318, -2.444521, 1.396806], [1.451625, -1.488142, 0.4383874], [1.396211, -0.4901891, -0.5638099], [1.256806, -0.2105258, -0.8434041], [1.256986, -0.1357194, -0.9157775], [1.206555, -0.4361041, -0.6805929],
//         [0.0969031, -2.919269, 1.845681], [0.09002627, -2.937735, 1.845372], [0.07547586, -2.956705, 1.844155], [0.08065736, -2.953332, 1.8285], [0.07946742, -2.944396, 1.780835], [0.116558, -2.92571, 1.722204], [0.1801932, -2.874534, 1.633786], [0.2173551, -2.87004, 1.575511], [0.1812332, -2.911981, 1.505892], [0.1522002, -2.893263, 1.561611], [0.1567392, -2.892725, 1.558363], [0.1623855, -2.884635, 1.554965], [0.2036525, -2.87291, 1.5458], [0.1699587, -2.87615, 1.483952], [0.1841671, -2.885482, 1.37672], [0.1045052, -2.937571, 1.331261], [0.07504071, -2.97035, 1.345221], [0.1002213, -2.982671, 1.338646], [0.08788913, -3.004072, 1.327629], [0.07559428, -3.002481, 1.329425], [0.08299296, -2.972791, 1.323977], [0.06990235, -2.974372, 1.286289], [0.07103293, -2.946914, 1.312107], [-0.007018561, -3.017284, 1.556725], [-0.05292758, -3.029725, 1.440775], [-0.08454311, -3.066444, 1.345493], [-0.1239125, 3.11465, 1.31965], [-0.1437692, 3.126657, 1.279659], [-0.1083261, -3.132264, 1.279118], [-0.139303, 3.14047, 1.280832], [-0.1323372, 3.141261, 1.266777], [-0.1176568, -3.134493, 1.277082], [-0.1016392, -3.127334, 1.264573], [-0.1151836, -3.131924, 1.284671], [-0.1189944, 3.121165, 1.252093], [-0.1286197, 3.123641, 1.265188], [-0.1249605, 3.133209, 1.265159], [-0.1197343, 3.137793, 1.259094], [-0.1051518, -3.122644, 1.273345]]
//        let labels = ["Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1",
//            "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2",
//            "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3"]


        //TEST FEATURES AND LABELS
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
    }
    
    
    
    
    
    
}
