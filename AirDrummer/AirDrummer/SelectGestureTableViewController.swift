//
//  SelectGestureTableViewController.swift
//  AirDrummer
//
//  Created by Erik Gabrielsen on 12/7/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit


class SelectGestureTableViewController: UITableViewController, SelectGestureDelegate {
    var items:[String] = ["Instrument 1", "Instrument 2", "Instrument 3"]
    var selectedRow:Int = 0
    var gestures:[Gesture] = [
        Gesture(id: "Gesture 1",gesture_name: "Face Up", gif_name: "popcorn",instrument: "Snare"),
        Gesture(id: "Gesture 2",gesture_name: "Up High",gif_name:"popcorn",instrument: "Hi-Hat"),
        Gesture(id: "Gesture 3",gesture_name: "Face Down",gif_name:"popcorn",instrument: "Toms")
    ]
    
    var kitName:String = "Instrument 1"

    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    
    func saveGestures(gestures:[Gesture]) {
        self.gestures = gestures
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
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gestureCell", for: indexPath) as! GestureTableViewCell
        
        cell.instrumentLabel.text = items[indexPath.row]
        
        var instrumentHasGesture = false
        var index = 0
        var gestureName = ""
        for gesture in gestures {
            if gesture.instrument == items[indexPath.row] && gesture.inUse {
                instrumentHasGesture = true
                gestureName = gesture.gesture_name
                break
            }
            index += 1
        }
        if instrumentHasGesture {
            //change image here (at index)
            let gifmanager = SwiftyGifManager(memoryLimit:20)
            let gif = UIImage(gifName: "\(gestureName).gif")
            cell.gestureImage.setGifImage(gif, manager: gifmanager)
            cell.gestureView.backgroundColor = UIColor.darkGray
        }
        else {
            cell.gestureView.backgroundColor = UIColor.init(red: 203/255, green: 162/255, blue: 111/255, alpha: 1.0)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell:GestureTableViewCell = tableView.cellForRow(at: indexPath as IndexPath)! as! GestureTableViewCell
        selectedCell.gestureView.backgroundColor = UIColor.init(red: 203/255, green: 162/255, blue: 111/255, alpha: 1.0)
        
        selectedRow = indexPath.row
        self.performSegue(withIdentifier: "showGestures", sender: self)
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
        if segue.identifier == "showGestures" {
            if let destinationNav = segue.destination as? UINavigationController {
                if let target = destinationNav.topViewController as? MatchGesturesTableViewController {
                    target.gestures = self.gestures
                    target.instrument = self.items[self.selectedRow]
                    target.delegate = self
                    target.titleName = "Choose Gesture For " + self.items[self.selectedRow]
                }
            }
            
        }
    }
    
    
    @IBAction func dismissView(_ sender: Any) {
        
        //convert gestures into gestureDict
        var gestureDict:[String:Gesture] = [:]
        for gesture in gestures {
            if gesture.inUse == true {
                gestureDict[gesture.id] = gesture
            }
            
        }
        
        //save new drum kit
        let newDrumKit:DrumKit = DrumKit(name: kitName, gestures: gestureDict)
        drumKits.append(newDrumKit)
        saveDrumKits(data: drumKits)
        saveSelectedKit(index: (drumKits.count-1))
        self.dismiss(animated: true, completion: nil)
    }

}
