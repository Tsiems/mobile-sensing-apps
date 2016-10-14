//
//  GraphViewController.swift
//  HeartBeet
//
//  Created by Erik Gabrielsen on 10/12/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import GLKit

class GraphViewController: GLKViewController {
    
    lazy var graphHelper:SMUGraphHelper = SMUGraphHelper(controller: self,
                                                         preferredFramesPerSecond: 10,
                                                         numGraphs: 1,
                                                         plotStyle: PlotStyleSeparated,
                                                         maxPointsPerGraph: 200)
    
    var bridge = OpenCVBridgeSub()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.graphHelper.setScreenBoundsBottomHalf()
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateBridge(notification:)), name: NSNotification.Name(rawValue: "bridge"), object: nil)
        // Do any additional setup after loading the view.
    }
    
    func update() {
        let data = self.bridge.getRed()
//        let buffer = self.bridge.getRedBuffer()
//        let data = UnsafeMutablePointer<Float>.allocate(capacity: MemoryLayout<Float>.size*200)
//        buffer?.fetchFreshData(data, withNumSamples: 200)
        self.graphHelper.setGraphData(data, withDataLength: 200, forGraphIndex: 0, withNormalization: 50, withZeroValue: 250)
//        data.deallocate(capacity:  MemoryLayout<Float>.size*200)
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        self.graphHelper.draw()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateBridge(notification: NSNotification) {
        let userInfo:Dictionary<String, AnyObject> = notification.userInfo as! Dictionary<String,AnyObject>
        let bridgeData = userInfo["bridge"]! as! OpenCVBridgeSub
        self.bridge = bridgeData
        update()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
