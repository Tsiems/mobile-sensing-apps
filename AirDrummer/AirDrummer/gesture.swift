//
//  gesture.swift
//  AirDrummer
//
//  Created by chinkpad on 12/8/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import Foundation
import UIKit

class Gesture: NSObject, NSCoding{

    let id : String
    let gesture_name : String
    let gif_name : String
    let instrument : String
//    let gif : UIImage
    init(id: String, gesture_name:String,gif_name: String,instrument: String) {
        self.id = id
        self.gesture_name = gesture_name
        self.gif_name = gif_name 
        self.instrument = instrument

        //self.gif = UIImage(named: self.gif_name + ".gif")!
//        self.gif = UIImage.gifImageWithName(name: self.gif_name)!
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let gid = aDecoder.decodeObject(forKey: "gid") as! String
        let gesture_name = aDecoder.decodeObject(forKey: "gesture_name") as! String
        let gif_name = aDecoder.decodeObject(forKey: "gif_name") as! String
        let instrument = aDecoder.decodeObject(forKey: "instrument") as! String
        self.init(id: gid, gesture_name:gesture_name, gif_name:gif_name,instrument:instrument)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "gid")
        aCoder.encode(gesture_name, forKey: "gesture_name")
        aCoder.encode(gif_name, forKey: "gif_name")
        aCoder.encode(instrument, forKey: "instrument")
    }
}
