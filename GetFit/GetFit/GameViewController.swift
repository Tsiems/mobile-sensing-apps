//
//  GameViewController.swift
//  GetFit
//
//  Created by Danh Nguyen on 9/27/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    var startingPucks: Int?
    var enemiesLeft: Int?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let scene = GameScene(size: view.bounds.size)
        let skView = view as! SKView // the view in storyboard must be an SKView
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        scene.enemiesLeft = self.enemiesLeft
        scene.startingPucks = self.startingPucks
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        NotificationCenter.default.addObserver(self, selector: #selector(GameViewController.removeView), name: NSNotification.Name(rawValue: "dismissView"), object: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    func removeView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeGame(_ sender: AnyObject) {
        removeView()
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
