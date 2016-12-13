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
    let svm = SVMModel(problemType: .c_SVM_Classification, kernelSettings: KernelParameters(type: .radialBasisFunction, degree: 0, gamma: 0.5, coef0: 0.0))
    
    
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
    
    let TIME_DELAY = 0.35
    
    
    
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
        return 230
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: "playTitleCell") as! PlayTitleCell
        
        headerCell.recordButton.tag = section
        headerCell.recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        
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
            print("Gesture not in use.")
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
        
        let features = [[0.07623456, -0.09142848, 0.8370885], [-0.03671428, -0.1370577, 0.8256841], [-0.008572277, -0.2023097, 0.7308348], [-0.06074278, -0.1603644, 0.6436754], [0.005912619, -0.06277346, 0.5560733], [-0.1548783, -0.1785277, 0.5042226], [-0.2169189, -0.1866105, 0.6382416], [-0.02781715, -0.1585404, 0.6449025], [0.03047385, -0.0545162, 0.5876888], [0.006212509, 0.2249936, 0.5243666], [-0.08938604, 0.2463478, 0.4968036], [0.001712763, 0.3222975, 0.4291964], [0.02462205, 0.4093269, 0.3312264], [0.08304981, 0.4339753, 0.3076316], [0.008926753, 0.2842512, 0.2977722], [-0.05178554, -0.005177378, 0.3801471], [-0.05979854, -0.3659642, 0.3832939], [0.2268138, -0.3953694, 0.4526007], [0.3906165, -0.2950549, 0.4934287], [0.3635199, -0.2730883, 0.6182702], [0.4936476, -0.312425, 0.6623415], [0.4037229, -0.3050974, 0.6997358], [0.4212868, -0.457756, 0.7487338], [0.5215003, -0.5199884, 0.8401114], [0.2188626, -0.2560777, 0.74534], [-0.02011549, -0.2145775, 0.7002766], [0.003256923, -0.3375048, 0.9040401], [-0.159904, -0.2166326, 0.7278507], [-0.1109648, -0.251231, 0.6775195], [-0.02589717, -0.5909548, 0.7602817], [0.05849962, -0.6684055, 0.8146624], [0.1004228, -0.8154515, 0.9493015], [0.1831519, -0.9658872, 1.002735], [0.2342618, -1.040913, 1.067916], [0.2079097, -1.275202, 1.099563], [0.2647403, -1.294754, 1.131748], [0.2212611, -1.054632, 1.074847], [0.2124729, -1.086313, 1.07691], [0.2893248, -1.117205, 1.137355], [0.2770698, -1.006174, 1.108811], [0.2048955, -0.9974127, 1.048572], [0.2672971, -0.7389896, 1.019358], [0.2154534, -0.5719461, 0.9747657], [0.2067753, -0.3563031, 0.920146], [0.2459765, -0.1947954, 0.8721945], [0.2254517, 0.0190057, 0.8206437], [0.09534408, 0.0814129, 0.8705863], [0.06263223, 0.01464604, 0.8276483], [-0.0131179, -0.1262009, 0.7560133], [-0.1468404, -0.1428719, 0.7510964], [-0.1252517, -0.1041169, 0.709195], [-0.1030142, -0.1377312, 0.6628914], [0.1831351, -0.1368041, 0.6884535], [0.3538288, -0.2589524, 0.7512267], [0.555347, -0.3274411, 0.7640405], [0.5781507, -0.2112636, 0.7591479], [0.1772677, 0.1176568, 0.6719987], [0.2360861, 0.2403607, 0.6548785], [0.06202585, 0.1889857, 0.6295203], [-0.08685116, 0.1019201, 0.5398511], [0.01803384, 0.2424219, 0.5135102], [-0.04574984, 0.1653787, 0.5229093], [0.05170703, 0.2731402, 0.3868382], [0.1040106, 0.1586925, 0.1806683], [0.2439181, 0.1546243, -0.2074416], [0.2843181, 0.1891825, -0.2982281], [0.2833245, 0.1790643, -0.4799182], [0.1361741, 0.2744956, -0.8057615], [0.09659253, 0.4670245, -0.9900867], [0.1772909, 0.5676795, -0.9586573], [0.1900465, 0.4378221, -0.9110627], [0.2168731, 0.6261923, -0.9740285], [0.2910635, 0.6925192, -1.032135], [0.2455302, 0.7485778, -1.134716], [0.3258115, 0.8423131, -1.177787], [0.2441436, 0.7223421, -1.181592], [0.3135259, 0.734437, -1.184125], [0.3003706, 0.6947261, -1.177781], [0.2929805, 0.2071003, -0.947146], [0.330002, -0.1054717, -0.6351911], [0.4174799, -0.194021, -0.4457516], [0.3652936, -0.6064602, -0.09069234], [0.3530783, -0.7368917, 0.1757508], [0.3420258, -0.8277583, 0.3386972], [0.3520598, -0.9112042, 0.4721712], [0.3609657, -1.014119, 0.5641745], [0.3441527, -1.040696, 0.6144307], [0.3523917, -0.9414535, 0.5446278], [1.552435, -2.688983, 1.29106], [1.507288, 2.533526, 2.376859], [1.532489, 2.150874, 2.71833], [1.491656, 1.85791, 3.019354], [1.532826, 1.379305, -2.804216], [1.544973, 2.80238, 2.083644], [1.507806, -1.327251, -0.1074621], [1.466973, -1.305065, -0.08561919], [1.509029, -1.299809, -0.04199469], [1.362013, -1.709949, 0.271849], [1.319523, -1.685959, 0.3237725], [1.331294, -1.450954, 0.08379665], [1.255821, -0.987784, -0.3094297], [1.233831, -0.6765496, -0.631419], [1.318182, -0.226355, -1.053117], [1.289158, 0.4779307, -1.801334], [1.216865, 0.7056742, -2.034464], [1.168847, 0.7437629, -2.046281], [1.092768, 0.5702171, -1.852265], [1.128312, 0.4682621, -1.867227], [1.196682, 0.4741488, -1.938719], [1.434313, 0.2284608, -1.808351], [1.490227, 0.0002145562, -1.506853], [1.289911, -1.065931, -0.1802347], [1.267191, -1.584002, 0.3184102], [1.305681, -1.755416, 0.38521], [1.200076, -1.761713, 0.3546928], [1.201304, -1.797526, 0.4282842], [1.111322, -1.588959, 0.1621116], [1.152623, -1.553321, 0.1743638], [1.324622, -1.491495, 0.1663349], [1.412753, -1.075747, -0.2437082], [1.515625, -0.2464927, -1.107535], [1.507275, 0.4603407, -1.856019], [1.348048, 1.431302, -2.836679], [1.278206, 1.308681, -2.744828], [1.260016, 1.370439, -2.805848], [1.35907, 1.460374, -2.902015], [1.502922, 1.539103, -2.968876], [1.507966, 1.350552, -2.745272], [1.507505, -0.7222749, -0.6310623], [1.383966, -1.369127, -0.03535152], [1.371965, -1.614726, 0.2699806], [1.363736, -1.786428, 0.464062], [1.293644, -1.717985, 0.3772061], [1.280714, -1.484135, 0.103126], [1.350522, -1.439196, 0.1180042], [1.358019, -1.691838, 0.455989], [1.323592, -1.734617, 0.4301051], [1.346571, -1.784873, 0.4610014], [1.344202, -1.548185, 0.260922], [1.304019, -1.637503, 0.277356], [1.324667, -1.954558, 0.5700305], [1.377758, -1.721341, 0.3202019], [1.328884, -1.658319, 0.2103029], [1.255685, -1.629431, 0.1733823], [1.348422, -1.585773, 0.1820568], [1.276808, -1.570047, 0.1536604], [1.23443, -1.796485, 0.387383], [1.27356, -2.11789, 0.753186], [1.335985, -2.231686, 0.9077314], [1.466488, -1.874598, 0.6098789], [1.326354, 0.04709648, -1.281524], [1.2217, 0.02834048, -1.306568], [1.220833, 0.1739273, -1.449859], [1.182962, 0.240985, -1.553458], [1.213677, 0.1801554, -1.542139], [1.348554, -0.299809, -1.177155], [1.381293, -0.2157679, -1.244067], [1.367412, -1.145042, -0.3454487], [1.394611, -1.408677, -0.04394846], [1.34751, -1.633884, 0.1816872], [1.320091, -1.897308, 0.4698795], [1.301354, -2.01773, 0.5889452], [1.25481, -1.92556, 0.4607499], [1.190894, -2.468272, 0.9887891], [1.201845, -2.387206, 0.9451928], [1.248511, -2.043432, 0.6179992], [1.271511, -1.765495, 0.4010129], [1.230259, -1.571876, 0.1494669], [1.266223, -1.523164, 0.09028117], [1.261221, -1.42536, -0.04818008], [1.322283, -1.248367, -0.236162], [1.29331, -1.229523, -0.2889634], [1.376921, -0.9597911, -0.5494982], [1.329866, -0.8732997, -0.6458983], [1.401377, -0.7038326, -0.793833], [1.332872, -0.8171921, -0.7071427], [1.426529, -0.7820011, -0.7262543], [1.445964, -0.8686507, -0.6394589], [1.492239, 1.331338, -2.78251], [1.41261, 1.81336, 3.03962], [1.514045, 1.761079, 3.063371], [1.479649, -1.566766, 0.08329315], [1.395188, -1.607479, 0.1537686], [1.305604, -1.467281, -0.008407104], [1.103999, -1.506369, -0.02324396], [1.164367, -1.507464, 0.05012238], [1.245775, -1.329191, -0.09472877], [0.1193607, -2.992537, 1.335885], [0.1211148, -2.976967, 1.327367], [0.1325272, -2.977529, 1.315917], [0.1236998, -3.033845, 1.316151], [0.1185103, -2.900578, 1.301467], [0.07808589, -2.851436, 1.302084], [0.1071453, -2.724089, 1.326825], [0.2003294, -2.648999, 1.439133], [0.1157769, -2.553358, 1.451334], [0.1551472, -2.465084, 1.480438], [0.09195508, -2.19868, 1.345232], [0.1510869, -2.198983, 1.399124], [0.2165874, -2.089622, 1.426836], [0.1563178, -2.097933, 1.364308], [0.1851629, -2.08218, 1.41428], [0.1448729, -2.088326, 1.377511], [0.1067936, -2.334193, 1.347597], [0.1370616, -2.451901, 1.391092], [0.03476119, -2.697438, 1.411798], [0.1983965, -2.707847, 1.467909], [0.2554781, -2.917719, 1.505502], [0.3517866, -3.068487, 1.625394], [0.4289914, -3.126487, 1.775398], [0.4328792, 3.027493, 1.84551], [0.3995184, 2.938195, 1.871586], [0.4731829, -2.639539, 1.051865], [0.1074103, -2.790658, 1.039636], [0.1520162, -2.771972, 1.046159], [0.06749169, -2.774588, 0.8543327], [0.1844805, -2.731626, 1.024804], [0.2300201, -2.710727, 1.138822], [0.2417987, -2.657384, 1.160136], [0.4605621, -2.505229, 1.041385], [0.2988235, -2.787147, 1.175064], [0.2406559, -2.785991, 1.123531], [0.2698308, -2.791657, 1.200014], [0.3277039, -2.836412, 1.211479], [0.2756876, -2.819627, 1.17957], [0.3318685, -2.83679, 1.222321], [0.3283114, -2.858252, 1.165263], [0.2334042, -2.862031, 1.15324], [0.2939691, -2.905223, 1.195816], [0.3325206, -2.66037, 1.117025], [0.07753175, -2.854296, 1.149455], [0.1796536, -2.830365, 1.118573], [0.207258, -2.835964, 1.208588], [0.2308059, -2.890262, 1.211297], [0.2102425, -2.943238, 1.226278], [0.1107029, -2.855436, 1.166483], [0.2628958, -2.719457, 1.187474], [0.3644065, -2.55918, 1.257038], [0.3716452, -2.386698, 1.190059], [0.4698519, -2.303364, 1.24118], [0.5999787, -2.078341, 1.295785], [0.2853234, -2.289115, 1.215734], [0.342672, -2.492287, 1.290208], [0.2180003, -2.545735, 1.289492], [0.2969378, -2.562056, 1.36152], [0.4760913, -2.669191, 1.402922], [0.3343454, -2.57793, 1.317218], [0.3866703, -2.695244, 1.342156], [0.4493841, -2.518308, 1.269742], [0.3617775, -2.231967, 1.254015], [0.358457, -2.079282, 1.226935], [0.2241532, -2.393311, 1.245325], [0.2974013, -2.251447, 1.2823], [0.2113847, -2.288242, 1.260299], [0.2111893, -2.56494, 1.319843], [0.1973431, -2.742671, 1.363025], [0.2054261, -2.944948, 1.362945], [0.1724277, -3.050183, 1.336075], [0.2602797, -3.135367, 1.431759], [0.2413431, 3.067194, 1.466573], [0.1948195, -2.68196, 1.341222], [0.1994804, -2.601487, 1.290144], [0.2614028, -2.714915, 1.244641], [0.4673732, -2.851743, 1.328192], [0.2966072, -2.712517, 1.08387], [0.4166176, -2.722982, 1.055903], [0.2424641, -2.736651, 0.9031804], [0.225262, -2.733483, 0.9651702], [0.5282338, -2.457375, 1.111768], [0.4099293, -2.68244, 1.089039], [0.3815941, -2.858352, 1.09105]]
        let labels = ["Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 1", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 2", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3", "Gesture 3"]
        
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
        
        
        let posTest = [-0.09, -3.1, 1.6]
        print("Classify:",svm.classifyOne(posTest) )
        
        
    }
    
    
    
    
    
    
}
