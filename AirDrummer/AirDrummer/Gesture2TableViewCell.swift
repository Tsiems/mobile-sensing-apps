//
//  Gesture2TableViewCell.swift
//  AirDrummer
//
//  Created by Erik Gabrielsen on 12/9/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit


class Gesture2TableViewCell: UITableViewCell {
    @IBOutlet weak var gestureLabel: UILabel!
    @IBOutlet weak var inUse: UILabel!
    @IBOutlet weak var gestureImage: UIImageView!
    @IBOutlet weak var gestureView: AnimatableView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
