//
//  FeatureData.swift
//  AirDrummer
//
//  Created by Travis Siems on 12/12/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit

class FeatureData: Hashable {
    var data:[Double] = []
    init(data:[Double]) {
        self.data=data
    }
    
    // required var for the Hashable protocol
    var hashValue: Int {
        // DJB hash function
        return self.data.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1)
        }
    }
//    var hashValue: Int {
//        // DJB hash function
//        return Int(self.data[0]*100 + self.data[1]*10000 + self.data[2]*1000000)
//    }

}

func ==(lhs: FeatureData, rhs: FeatureData) -> Bool {
    if lhs.data.count != rhs.data.count {
        return false
    }
    var i = 0
    while i<lhs.data.count {
        if lhs.data[i] != rhs.data[i] {
            return false
        }
        i += 1
    }
    return true
}
