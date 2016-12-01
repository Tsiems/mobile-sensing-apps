//
//  SelectInstrumentsViewController.swift
//  AirDrummer
//
//  Created by Erik Gabrielsen on 11/21/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit



class SelectInstrumentsViewController: UIViewController, KDDragAndDropCollectionViewDataSource {
    
    @IBOutlet weak var titleView: AnimatableView!
    
    @IBOutlet weak var firstCollectionViewController: UICollectionView!
    
    @IBOutlet weak var secondCollectionViewController: UICollectionView!
    
    var data : [[DataItem]] = [[DataItem]]()
    
    var dragAndDropManager : KDDragAndDropManager?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        let width = Double(screenSize.width)
        
        titleView.maskType = MaskType.wave(direction: MaskType.WaveDirection.up, width: width, offset: 0)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        UITabBar.appearance().shadowImage = UIImage.colorForNavBar(color: UIColor.white)
        UITabBar.appearance().backgroundImage = UIImage.colorForNavBar(color: UIColor.white)
        
        let drums: [String] = [
            "Hi-Hat",
            "Symbal",
            "Base",
            "Snare",
            "Toms"
        ]
        
        data.append([])
        var items = [DataItem]()
        for i in 0...drums.count-1 {
            items.append(DataItem(indexes: drums[i], colour: UIColor.black))
        }
        data.append(items)
        
        
        firstCollectionViewController.tag = 0
        secondCollectionViewController.tag = 1
        
        self.dragAndDropManager = KDDragAndDropManager(canvas: self.view, collectionViews: [firstCollectionViewController, secondCollectionViewController])
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.navigationBar.topItem?.title = "Play"
        self.navigationController?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "?", style: .plain, target: self, action: #selector(addTapped))

        

    }
    
    func addTapped() {
        
    }

    
    
    // MARK : UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[collectionView.tag].count
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath as IndexPath) as! ItemCollectionViewCell
        
        let dataItem = data[collectionView.tag][indexPath.item]
        
        cell.label.text = "\(dataItem.indexes)"
        
        cell.backgroundColor = dataItem.colour
        
        cell.isHidden = false
        
        if let kdCollectionView = collectionView as? KDDragAndDropCollectionView {
            
            if let draggingPathOfCellBeingDragged = kdCollectionView.draggingPathOfCellBeingDragged {
                
                if draggingPathOfCellBeingDragged.item == indexPath.item {
                    
                    cell.isHidden = true
                    
                }
            }
        }
        
        return cell
    }
    
    // MARK : KDDragAndDropCollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, dataItemForIndexPath indexPath: NSIndexPath) -> AnyObject {
        return data[collectionView.tag][indexPath.item]
    }
    func collectionView(collectionView: UICollectionView, insertDataItem dataItem : AnyObject, atIndexPath indexPath: NSIndexPath) -> Void {
        
        if let di = dataItem as? DataItem {
            data[collectionView.tag].insert(di, at: indexPath.item)
        }
        
        
    }
    func collectionView(collectionView: UICollectionView, deleteDataItemAtIndexPath indexPath : NSIndexPath) -> Void {
        data[collectionView.tag].remove(at: indexPath.item)
    }
    
    func collectionView(collectionView: UICollectionView, moveDataItemFromIndexPath from: NSIndexPath, toIndexPath to : NSIndexPath) -> Void {
        
        let fromDataItem: DataItem = data[collectionView.tag][from.item]
        data[collectionView.tag].remove(at: from.item)
        data[collectionView.tag].insert(fromDataItem, at: to.item)
        
    }
    
    func collectionView(collectionView: UICollectionView, indexPathForDataItem dataItem: AnyObject) -> NSIndexPath? {
        
        if let candidate : DataItem = dataItem as? DataItem {
            
            for item : DataItem in data[collectionView.tag] {
                if candidate  == item {
                    
                    let position = data[collectionView.tag].index(of: item)! // ! if we are inside the condition we are guaranteed a position
                    let indexPath = NSIndexPath(item: position, section: 0)
                    return indexPath
                }
            }
        }
        
        return nil
        
    }
    @IBAction func `continue`(_ sender: Any) {
        if data[0].count > 3 {
            let alert = UIAlertController(title: "Uh Oh!",
                                          message:"You have too many instruments! Please only pick at most 3 drums",
                preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else if data[0].count == 0 {
            let alert = UIAlertController(title: "Missing a Drum!",
                                          message:"Please add a drum instrument by dragging it into your drum set!",
                                          preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.performSegue(withIdentifier: "playSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "playSegue" {
            
            print("Play!")
            
        }
    }
    
}
