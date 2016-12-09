//
//  RecordingsTableViewController.swift
//  AirDrummer
//
//  Created by Erik Gabrielsen on 12/6/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit
import AVFoundation

class RecordingsTableViewController: UITableViewController, AVAudioPlayerDelegate {
    var recordings:[String] = []
    var audioPlayer: AVAudioPlayer!
    var directoryContents: Array<URL>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        try! AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker )
        
        
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            // Get the directory contents urls (including subfolders urls)
            directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
            print(directoryContents)
            
            // if you want to filter the directory contents you can do like this:
            let m4aFiles = directoryContents.filter{ $0.pathExtension == "m4a" }
//            print("m4a urls:",m4aFiles)
            recordings = m4aFiles.map{ $0.deletingPathExtension().lastPathComponent }
//            print("m4a list:", recordings)
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
//        recordings = ["One", "Two", "Three"]
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
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
        return recordings.count
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let deselectedCell:RecordingTableViewCell = tableView.cellForRow(at: indexPath as IndexPath)! as! RecordingTableViewCell
        deselectedCell.recordingView.backgroundColor = UIColor.black
        deselectedCell.recordingTitle.textColor = UIColor.init(red: 203/255, green: 162/255, blue: 111/255, alpha: 1.0)
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recording", for: indexPath) as! RecordingTableViewCell
        
        cell.recordingTitle.text = recordings[indexPath.row]

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: "recordingHeader") as! RecordingHeaderCell
        
        
        return headerCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell:RecordingTableViewCell = tableView.cellForRow(at: indexPath as IndexPath)! as! RecordingTableViewCell
        selectedCell.recordingView.backgroundColor = UIColor.init(red: 203/255, green: 162/255, blue: 111/255, alpha: 1.0)
        selectedCell.recordingTitle.textColor = UIColor.black
        
        let recordingURL = directoryContents.filter{ $0.deletingPathExtension().lastPathComponent == recordings[indexPath.row] }[0]
        audioPlayer = try! AVAudioPlayer(contentsOf: recordingURL)
        audioPlayer.prepareToPlay()
        audioPlayer.play()
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
            let recordingURL = directoryContents.filter{ $0.deletingPathExtension().lastPathComponent == recordings[indexPath.row] }[0]
            recordings.remove(at: indexPath.row)
            try! FileManager.default.removeItem(at: recordingURL)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
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
