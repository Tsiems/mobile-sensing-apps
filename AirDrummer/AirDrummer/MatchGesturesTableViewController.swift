//
//  MatchGesturesTableViewController.swift
//  AirDrummer
//
//  Created by Erik Gabrielsen on 12/9/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit


protocol SelectGestureDelegate {
    func saveGestures(gestures: [Gesture])
}

class MatchGesturesTableViewController: UITableViewController {

    var gestures:[Gesture] = Array(defaultGestures.values)
    var instrument:String = ""
    var delegate : SelectGestureDelegate?

    var selected = -1


    @IBOutlet weak var saveButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return gestures.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell:Gesture2TableViewCell = tableView.cellForRow(at: indexPath as IndexPath)! as! Gesture2TableViewCell
        
        self.selected = indexPath.row
        // save this as the object gesture and return

        if (gestures[indexPath.row].inUse) {
            selectedCell.inUse.isHidden = true
        }
        selectedCell.gestureView.backgroundColor = UIColor.init(red: 203/255, green: 162/255, blue: 111/255, alpha: 1.0)
        
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.cellForRow(at: indexPath as IndexPath) != nil {
            let deselectedCell:Gesture2TableViewCell = tableView.cellForRow(at: indexPath as IndexPath)! as! Gesture2TableViewCell
            
            if (gestures[indexPath.row].inUse) {
                deselectedCell.inUse.isHidden = false
            }
            
            deselectedCell.gestureView.backgroundColor = UIColor.black
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gesture2Cell", for: indexPath) as! Gesture2TableViewCell
        
        cell.layer.shouldRasterize = true;
        cell.layer.rasterizationScale = UIScreen.main.scale
        // Configure the cell...
        cell.gestureLabel.text = gestures[indexPath.row].gesture_name
        
        let gifmanager = SwiftyGifManager(memoryLimit:20)
        if gestures[indexPath.row].gesture_name == "Low Hit" {
            let gif = UIImage(gifName: "popcorn.gif")
            let imageview = UIImageView(gifImage: gif, manager: gifmanager)
            cell.gestureImage.setGifImage(gif, manager: gifmanager)
        } else {
            let gif = UIImage(gifName: "\(gestures[indexPath.row].gesture_name).gif")
            let imageview = UIImageView(gifImage: gif, manager: gifmanager)
            cell.gestureImage.setGifImage(gif, manager: gifmanager)
        }
        
        
        
       
        
        
        if (!gestures[indexPath.row].inUse) {
            cell.inUse.isHidden = true
        }
        
        if (selected != indexPath.row) {
            cell.gestureView.backgroundColor = UIColor.black
        } else {
            cell.gestureView.backgroundColor = UIColor.init(red: 203/255, green: 162/255, blue: 111/255, alpha: 1.0)
        }

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        print(segue.identifier ?? "No identifier :(")
    }
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func save(_ sender: Any) {
        if let del = delegate {
            gestures[selected].instrument = self.instrument
            gestures[selected].inUse = true
            
            print(gestures[selected].gesture_name,gestures[selected].instrument,gestures[selected].inUse)
            del.saveGestures(gestures: self.gestures)
        }
        self.dismiss(animated: true, completion: nil)
    }
}
