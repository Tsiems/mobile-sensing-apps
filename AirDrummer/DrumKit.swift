
//
//  DrumKit.swift
//  AirDrummer
//
//  Created by Travis Siems on 12/8/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit


class DrumKit: NSObject,NSCoding {
    let name: String
    let gestures: Dictionary<String, Gesture>
    
    init(name:String,gestures:Dictionary<String, Gesture>) {
        self.name = name
        self.gestures = gestures
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: "kitName") as! String
        let gestures = aDecoder.decodeObject(forKey: "gesture_name") as! Dictionary<String, Gesture>

        self.init(name:name,gestures:gestures)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "kitName")
        aCoder.encode(gestures, forKey: "gestures")
    }

}


//global constant for default gestures in case no saved data is found
let defaultGestures = ["['Gesture 1']":Gesture(id: "['Gesture 1']",gesture_name: "Low Hit", gif_name: "popcorn",instrument: "Snare"),
                       "['Gesture 2']":Gesture(id: "['Gesture 2']",gesture_name: "High Hit",gif_name:"popcorn",instrument: "Hi-Hat"),
                       "['Gesture 3']":Gesture(id: "['Gesture 3']",gesture_name: "Flipped Hit",gif_name:"popcorn",instrument: "Toms")]

//global variables for selecting and managing drum kits
var selectedDrumKit = 0
var drumKits = [DrumKit(name:"Default Kit",gestures:["['Gesture 1']":Gesture(id: "['Gesture 1']",gesture_name: "Low Hit", gif_name: "popcorn",instrument: "Snare")])]


func saveDrumKits(data: [DrumKit],index:Int) {
    let drumKitData = NSKeyedArchiver.archivedData(withRootObject: data)
    UserDefaults.standard.set(drumKitData, forKey: "drumKits")
    UserDefaults.standard.set(index, forKey: "selectedDrumKitIndex")
}

func loadDrumKits() -> ([DrumKit],Int) {
    
    if let drumkits = UserDefaults.standard.object(forKey: "drumKits") as? Data {
        
        if let drumkits = NSKeyedUnarchiver.unarchiveObject(with: drumkits) as? [DrumKit] {
            
            if let index = UserDefaults.standard.object(forKey: "selectedDrumKitIndex") as? Int {
                return (drumkits,index)
            }
            else {
                return ([DrumKit(name: "Default Kit", gestures: defaultGestures)],0) //use default kit
            }
        } else {
            return ([DrumKit(name: "Default Kit", gestures: defaultGestures)],0) //use default kit
        }
        
    } else {
        return ([DrumKit(name: "Default Kit", gestures: defaultGestures)],0) //use default kit
    }
}



import UIKit
import QuartzCore

class SegueFromLeft: UIStoryboardSegue {
    
    override func perform() {
        let src: UIViewController = self.source
        let dst: UIViewController = self.destination
        let transition: CATransition = CATransition()
        let timeFunc : CAMediaTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.duration = 0.25
        transition.timingFunction = timeFunc
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromLeft
        src.navigationController!.view.layer.add(transition, forKey: kCATransition)
        src.navigationController!.pushViewController(dst, animated: false)
    }
    
}
