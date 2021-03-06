//
//  BikeTableViewController.swift
//  
//
//  Created by David Cai on 6/29/16.
//
//

import UIKit
import Firebase


class BikeTableViewController: UITableViewController {
    
    let ref = FIRDatabase.database().reference()
    
    //MARK: Properties
    var bikeList = [bikeClass]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewdidload")
        
        // Loading the saved list of bikes, to avoid FB calls
        //bikeList = loadBikeList()!
        
        // Watcher thing that auto refreshes when FB DB changes
        // As of right now, it replaces the whole bike list
        // to cover all cases (append, delete, change)
        
        // FB init.
        let bikeListRef = ref.child("colleges/\(thisUser.college)/bikeList")
        
        bikeListRef.observeEventType(.Value, withBlock: { snapshot in
            // This temp decleration must be inside the .observeEventType so that it resets with every refresh. Otherwise, you'll just append the old list
            var tempBikeList = [bikeClass]()
            for child in snapshot.children {
                // Creating bikeClass object from FB DB data
                
                let bikeShortName = child.value["shortName"] as! String
                let bikeFullName = child.value["fullName"] as! String
                let size = child.value["size"] as! String
                let status = child.value["status"] as! String
                var riders = [String:String]()
                
                let riderDict = child.value["riders"] as! NSDictionary
                for rider in riderDict {
                    if rider.key as! String != "init" {
                        riders[rider.key as! String] = rider.value as! String
                    }
                }
                
                // To get key of bike entry, turn the "child" element into an FIRDataSnapshot object, which can then have .key called on it
                let childsnap = child as! FIRDataSnapshot
                let bikeUsername = childsnap.key
                
                let bikeObject = bikeClass(bikeShortName: bikeShortName, bikeFullName: bikeFullName, size: size, riders: riders, status: status, bikeUsername: bikeUsername)
                //print(bikeObject.bikeUsername)
                
                tempBikeList.append(bikeObject)
                self.saveBikeList(tempBikeList)
                self.bikeList = self.loadBikeList()!
                self.tableView.reloadData()
            }
        })

        
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

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bikeList.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Take info from bikeList array and puts them into cells
        let cellIdentifier = "BikeTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! BikeTableViewCell
        
        let bike = bikeList[indexPath.row]

        cell.bikeNameDisplay.text = bike.bikeShortName
        cell.statusLabel.text = bike.status


        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation
    
    @IBAction func unwindToBikelist(segue: UIStoryboardSegue) {}
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "fromBikelistToBikeDetailView" {
            
            // Grab which bike initiated the segue
            let selectedBikeCell = sender as! BikeTableViewCell
            let indexPath = tableView.indexPathForCell(selectedBikeCell)!
            let selectedBike = bikeList[indexPath.row]
            
            // Send that bike info over to the BikeDetailView
            let bikeDetailView = segue.destinationViewController as! BikeDetailViewController
            bikeDetailView.thisBike = selectedBike
        }
        else {
            ref.removeAllObservers()
        }
    }

    // MARK: NSCoding
    
    func saveBikeList(bikeListName: [bikeClass]){
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(bikeListName, toFile: bikeClass.ArchiveURL!.path!)
        if isSuccessfulSave {
            print("BikeList Saved")
        }
        else {
            print("Failed to save BikeList")
        }
    }
    
    func loadBikeList() -> [bikeClass]? {
        return NSKeyedUnarchiver.unarchiveObjectWithFile(bikeClass.ArchiveURL!.path!) as? [bikeClass]
    }
    
}
