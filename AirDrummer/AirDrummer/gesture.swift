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
    let MLID : String
    let Name : String
    let Gif : UIImage
    init(id: String, name: String?) {
        self.MLID = id
        self.Name = name ?? ""
        self.Gif = UIImage(named: self.Name + ".gif")!
    }
}
