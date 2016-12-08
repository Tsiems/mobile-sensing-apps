//
//  DrumKitTableViewCell.swift
//  AirDrummer
//
//  Created by Erik Gabrielsen on 12/8/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit

class DrumKitTableViewCell: UITableViewCell {
    @IBOutlet weak var kitLabel: UILabel!
    @IBOutlet weak var animatedView: AnimatableView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        
    }

}
