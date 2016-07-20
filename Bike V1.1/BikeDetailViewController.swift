//
//  BikeDetailViewController.swift
//  Bike V1.1
//
//  Created by David Cai on 7/3/16.
//  Copyright © 2016 David Cai. All rights reserved.
//

import UIKit
import Firebase

class BikeDetailViewController: UIViewController {
    
    let ref = FIRDatabase.database().reference()
    
    // MARK: Properties
    var thisBike: bikeClass?
    
    // Variable visuals
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var ridersLabel: UILabel!
    @IBOutlet weak var bikeImageView: UIImageView!
    
    // Static visuals
    @IBOutlet weak var staticSizeLabel: UILabel!
    @IBOutlet weak var staticStatusLabel: UILabel!
    @IBOutlet weak var staticRidersLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("User has selected: \(thisBike!.bikeUsername)")
        
        let bikeRef = ref.child("colleges/\(thisUser.college)/bikeList/\(thisBike!.bikeUsername)")
        print(thisUser.college)
        // Listener is used to live update the info (namely rider list) as the user manipulates the information from the detailview
        bikeRef.observeEventType(.Value, withBlock: { snapshot in
            // Creating bikeClass object from FB DB data
            print(snapshot.value!["name"] as! String)
            let bikeName = snapshot.value!["name"] as! String
            let size = snapshot.value!["size"] as! String
            let wheels = snapshot.value!["wheels"] as! String
            let bikeUsername = snapshot.key
            
            var riders = [String]()
            
            let riderList = snapshot.value!["riders"] as! NSDictionary
            for rider in riderList {
                if rider.key as! String != "init" {
                    riders.append(rider.key as! String)
                }
            }
            
            let bikeObject = bikeClass(bikeName: bikeName, wheels: wheels, size: size, riders: riders, status: nil, bikeUsername: bikeUsername)
            self.thisBike = bikeObject
            self.updateRiderList()
            
        })
        
        // Setting titles
        self.title = thisBike?.bikeName
        sizeLabel.text = thisBike?.size
        statusLabel.text = thisBike?.status
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: Actions
    
    @IBAction func doneButton(sender: UIBarButtonItem) {
        performSegueWithIdentifier("unwindFromBikeDetailViewToBikelist", sender: self)
    }
    
    @IBAction func setBikeButton(sender: UIBarButtonItem) {
        // Updating the bike's list of riders
        let bikeRef = ref.child("colleges/\(thisUser.college)/bikeList/\(thisBike!.bikeUsername)/riders")
        
        bikeRef.updateChildValues([thisUser.userName : true])
        
        // Removing user from other bikes
        let bikeListRef = ref.child("colleges/\(thisUser.college)/bikeList")
        
        bikeListRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            // Iterating through the bikes
            for child in snapshot.children {
                // To grab bike's username for removing riders
                let childSnap = child as! FIRDataSnapshot
                let bikeName = childSnap.key
                
                // if-statement to ensure you don't remove yourself from the bike you just added to
                if bikeName != self.thisBike!.bikeUsername {
                    // The following line will remove the user if it exists -- nothing will happen if the user does not exist
                    bikeListRef.child("/\(bikeName)/riders/\(thisUser.userName)").removeValue()
                }
            }
        })
        
        // Updating the user's data
        let userRef = ref.child("users/\(thisUser.userName)/bike")
        userRef.setValue(thisBike?.bikeUsername)
        
    }
    
    // MARK: Misc funcs
    func updateRiderList() {
        // Turning usernames into actual names
        // FB is needed to get the *actual* names of the riders b/c the user dict is not stored locally
        var riderList = ""
        for riderUsername in thisBike!.riders! {
            let riderRef = ref.child("users/\(riderUsername)")
            riderRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
                let actualName = snapshot.value!["name"] as! String
                riderList += "\(actualName), "
                self.ridersLabel.text = riderList
            })
        }
    }
    
}
