//
//  DrumKitSelectTableViewController.swift
//  AirDrummer
//
//  Created by Erik Gabrielsen on 12/7/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit

class DrumKitSelectTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        drumKits = loadDrumKits()
        selectedDrumKit = loadSelectedKit()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        drumKits = loadDrumKits()
        selectedDrumKit = loadSelectedKit()
        
        self.tableView.reloadData()
        self.tableView.selectRow(at: IndexPath(row: selectedDrumKit,section: 0), animated: false, scrollPosition: UITableViewScrollPosition.middle)
        
        let selectedCell:DrumKitTableViewCell = tableView.cellForRow(at: IndexPath(row: selectedDrumKit,section: 0)) as! DrumKitTableViewCell
        selectedCell.animatedView.backgroundColor = UIColor.init(red: 203/255, green: 162/255, blue: 111/255, alpha: 1.0)
        selectedCell.contentView.backgroundColor = UIColor.white
        selectedCell.kitLabel.textColor = UIColor.black
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
        return drumKits.count
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell:DrumKitTableViewCell = tableView.cellForRow(at: indexPath as IndexPath)! as! DrumKitTableViewCell
        selectedCell.animatedView.backgroundColor = UIColor.init(red: 203/255, green: 162/255, blue: 111/255, alpha: 1.0)
        selectedCell.contentView.backgroundColor = UIColor.white
        selectedCell.kitLabel.textColor = UIColor.black
        
        selectedDrumKit = indexPath.row
        saveSelectedKit(index: selectedDrumKit)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cellToDeSelect:DrumKitTableViewCell = tableView.cellForRow(at: indexPath as IndexPath)! as! DrumKitTableViewCell
        cellToDeSelect.kitLabel.textColor = UIColor.init(red: 203/255, green: 162/255, blue: 111/255, alpha: 1.0)
//        cellToDeSelect.contentView.backgroundColor = UIColor.black
        cellToDeSelect.animatedView.backgroundColor = UIColor.black
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "drumKitCell", for: indexPath) as! DrumKitTableViewCell

        let gestures = drumKits[indexPath.row].gestures
        let gestureValues = Array(gestures.values)
        // Configure the cell...
        cell.kitLabel.text = drumKits[indexPath.row].name
        if gestureValues.count >= 1 {
            let image: UIImage = UIImage(named:"\(gestureValues[0].instrument)")!
            cell.imageView1.image = image
        }
        if gestureValues.count >= 2 {
            let image: UIImage = UIImage(named:"\(gestureValues[1].instrument)")!
            cell.imageView2.image = image
        }
        if gestureValues.count >= 3 {
            let image: UIImage = UIImage(named:"\(gestureValues[2].instrument)")!
            cell.imageView3.image = image
        }
        
        if gestureValues.count == 1 {
            cell.imageView2.isHidden = true
            cell.imageView3.isHidden = true
        } else if gestureValues.count == 2 {
            cell.imageView3.isHidden = true
        }
        
        
        if indexPath.row == selectedDrumKit {
            cell.animatedView.backgroundColor = UIColor.init(red: 203/255, green: 162/255, blue: 111/255, alpha: 1.0)
            cell.contentView.backgroundColor = UIColor.white
            cell.kitLabel.textColor = UIColor.black
        }
        else {
            cell.kitLabel.textColor = UIColor.init(red: 203/255, green: 162/255, blue: 111/255, alpha: 1.0)
            cell.animatedView.backgroundColor = UIColor.black
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

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            if drumKits.count == 1 {
                let alert = UIAlertController(title: "Sorry!",
                                              message:"You must have at least 1 drumKit",
                                              preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)

            } else {
                drumKits.remove(at: indexPath.row)
                saveDrumKits(data: drumKits)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self.tableView.selectRow(at: IndexPath(row: 0,section: 0), animated: false, scrollPosition: UITableViewScrollPosition.middle)
                
                let selectedCell:DrumKitTableViewCell = tableView.cellForRow(at: IndexPath(row: 0,section: 0)) as! DrumKitTableViewCell
                selectedCell.animatedView.backgroundColor = UIColor.init(red: 203/255, green: 162/255, blue: 111/255, alpha: 1.0)
                selectedCell.contentView.backgroundColor = UIColor.white
                selectedCell.kitLabel.textColor = UIColor.black
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
