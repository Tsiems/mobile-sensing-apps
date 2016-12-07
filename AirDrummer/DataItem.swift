//
//  DataItem.swift
//  AirDrummer
//
//  Created by Erik Gabrielsen on 11/25/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//
import UIKit

class DataItem : Equatable {
    var indexes : String = ""
    var colour : UIColor = UIColor.clear
    init(indexes : String, colour : UIColor) {
        self.indexes = indexes
        self.colour = colour
    }
}

func ==(lhs: DataItem, rhs: DataItem) -> Bool {
    return lhs.indexes == rhs.indexes && lhs.colour == rhs.colour
}
