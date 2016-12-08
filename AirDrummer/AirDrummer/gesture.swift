//
//  gesture.swift
//  AirDrummer
//
//  Created by chinkpad on 12/8/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import Foundation
import UIKit

class Gesture{
    let id : String
    let gesture_name : String
    let gif_name : String
    let instrument : String
    let gif : UIImage
    init(id: String, gesture_name:String,gif_name: String,instrument: String) {
        self.id = id
        self.gesture_name = gesture_name
        self.gif_name = gif_name 
        self.instrument = instrument
        //self.gif = UIImage(named: self.gif_name + ".gif")!
        self.gif = UIImage.gifImageWithName(name: self.gif_name)!
    }
}
