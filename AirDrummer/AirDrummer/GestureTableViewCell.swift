//
//  GestureTableViewCell.swift
//  AirDrummer
//
//  Created by Erik Gabrielsen on 12/9/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit

class GestureTableViewCell: UITableViewCell {
    @IBOutlet weak var instrumentLabel: UILabel!
    @IBOutlet weak var gestureView: AnimatableView!
    @IBOutlet weak var gestureImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
