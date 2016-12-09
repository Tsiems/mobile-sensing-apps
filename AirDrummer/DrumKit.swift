
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
