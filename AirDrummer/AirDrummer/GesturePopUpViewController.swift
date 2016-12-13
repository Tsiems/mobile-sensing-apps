//
//  GesturePopUpViewController.swift
//  AirDrummer
//
//  Created by Erik Gabrielsen on 12/12/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit

class GesturePopUpViewController: UIViewController {
    @IBOutlet weak var gestureView: UIImageView!
    var gifName = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.clear
        view.isOpaque = false

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let gifmanager = SwiftyGifManager(memoryLimit:20)
        
        let gif = UIImage(gifName: "\(gifName).gif")
        self.gestureView.setGifImage(gif, manager: gifmanager)
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func dismissView(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}
