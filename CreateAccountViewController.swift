//
//  ViewController.swift
//  Bike V1
//
//  Created by David Cai on 6/27/16.
//  Copyright © 2016 David Cai. All rights reserved.
//

import UIKit
import Firebase

var thisUser: userClass!

class CreateAccountViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let ref = FIRDatabase.database().reference()
    
    // MARK: Properties
    @IBOutlet weak var createFirstName: UITextField!
    @IBOutlet weak var createLastName: UITextField!
    @IBOutlet weak var createCollege: UIPickerView!
    @IBOutlet weak var createEmail: UITextField!
    @IBOutlet weak var createPassword: UITextField!
    @IBOutlet weak var createButton: UIButton!
    
    let listOfColleges = [" ", "Don't Pick this one", "wrc", "Not this one", "ew jones"]
    var userCollege: String!
    
    override func viewDidLoad() {
        // Delegation
        createFirstName.delegate = self
        createLastName.delegate = self
        createCollege.delegate = self
        createCollege.dataSource = self
        createEmail.delegate = self
        createPassword.delegate = self
        createButton.enabled = false
        
        let dismiss: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CreateAccountViewController.DismissKeyboard))
        view.addGestureRecognizer(dismiss)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UITextfield Delegate
    func isNameValid() -> Bool {
        // true if not empty, false if empty
        return !((createFirstName.text?.isEmpty)! && (createLastName.text?.isEmpty)!)
    }
    
    func isEmailValid() -> Bool {
        // checks for emptiness, then if @ and . are in the email string
        if !(createEmail.text?.isEmpty)! {
            let at = createEmail.text!.rangeOfString("@")
            let dot = createEmail.text!.rangeOfString(".")
            if at != nil && dot != nil {
                return true
            }
            else {
                return false
            }
        }
        else {
            return false
        }
    }
    
    func isPasswordValid() -> Bool {
        // true if not empty and longer than 6 chars, false if empty or less than 6 chars
        return !(createPassword.text?.isEmpty)! && (createPassword.text?.characters.count > 6)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        // Once user finishes enter data, if data is valid, then we'll let them create the account
        createFirstName.text = createFirstName.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        createLastName.text = createLastName.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        createEmail.text = createEmail.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        createButton.enabled = isNameValid() && isEmailValid() && isPasswordValid()
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Moves user along through the textFields
        
        createButton.enabled = isNameValid() && isEmailValid() && isPasswordValid()
        if textField == createFirstName {
            createFirstName.resignFirstResponder()
            createLastName.becomeFirstResponder()
        }
        else if textField == createLastName {
            
            createLastName.resignFirstResponder()
            createEmail.becomeFirstResponder()
        }
        
        else if textField == createEmail {
            
            createEmail.resignFirstResponder()
            createPassword.becomeFirstResponder()
        }
        else {
            createPassword.resignFirstResponder()
            
        }
        
        // b/c it returns a Bool. Not sure why this is here tbh
        return true
    }
    
    
    // MARK: Picker Delegate and datasource
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return listOfColleges.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return listOfColleges[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.userCollege = listOfColleges[row]
    }
    
    
    // MARK: Actions
    @IBAction func createAccount(sender: UIButton) {
        // It is important to note that anything that interacts with FB DB should probs use callbacks
        // b/c it takes (relatively) forever to connected and retrieve data, at which point
        // other funcs will have run and failed.
        
        // Resign, in case they are still FR
        createFirstName.resignFirstResponder()
        createLastName.resignFirstResponder()
        createCollege.resignFirstResponder()
        createEmail.resignFirstResponder()
        createPassword.resignFirstResponder()
        
        let createUserName = userCollege + createFirstName.text! + createLastName.text!
        
        // Create new userClass object
        thisUser = userClass(firstName: createFirstName.text!, lastName: createLastName.text!, userName: createUserName, college: self.userCollege, email: createEmail.text!, password: createPassword.text!, bike: "None", oneSignalUserId: nil)
        saveUser()
        loadUser()
        
        
        // Create account on Firebase
        FIRAuth.auth()?.createUserWithEmail(createEmail.text!, password: createPassword.text!) { (user, error) in
            // Callback for creating account
            if let error = error {
                print(error.localizedDescription)
                return
            }
            else {
                // Note that user now has account
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "launchedBefore")
                
                // Sign user in, then pull bikeList array from FB DB
                FIRAuth.auth()?.signInWithEmail(thisUser.email, password: thisUser.password) { (user, error) in
                    // Callback for signing in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    else {
                        print("User signed in")
                        self.pullBikeListData() { (bikes) in
                            // Callback for pullBikeListData, so everything's loaded when we go to the homepage
                            print("bike list pulled")
                            self.pullWorkoutsData() { (workouts) in
                                // Callback for pullWorkoutsData, so everything's loaded when we go to the homepage
                                print("workouts pulled")
                                self.createdDBEntries(thisUser) { (foo) in
                                    print("DB Entries created")
                                    self.performSegueWithIdentifier("unwindFromCreateAccountToHomepage", sender: self)
                                }
                            }
                        }
                    }
                }
            }
        
        }

    }

    func DismissKeyboard(){
        view.endEditing(true)
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        ref.removeAllObservers()
        let homepage = segue.destinationViewController as! HomepageViewController
        homepage.words.text = thisUser.firstName +  " " + thisUser.lastName
        homepage.collegeLabel.text = thisUser.college
        loadUser()

    }
    
    
    // MARK: NSCoding
    func saveUser() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(thisUser, toFile: userClass.ArchiveURL!.path!)
        if isSuccessfulSave {
            print("User saved")
            print("save user create account")
        }
        else {
            print("Failed to save user")
        }
    }
    
    func saveBikeList(bikeListName: [bikeClass]){
       let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(bikeListName, toFile: bikeClass.ArchiveURL!.path!)
        if isSuccessfulSave {
            print("BikeList Saved")
        }
        else {
            print("Failed to save BikeList")
        }
    }
    
    func saveWorkoutList(workoutListName: [workoutClass]){
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(workoutListName, toFile: workoutClass.ArchiveURL!.path!)
        if isSuccessfulSave {
            print("WorkoutList Saved")
        }
        else {
            print("Failed to save WorkoutList")
        }
    }
    
    func loadBikeList() -> [bikeClass]? {
        return NSKeyedUnarchiver.unarchiveObjectWithFile(bikeClass.ArchiveURL!.path!) as? [bikeClass]
    }
    
    func loadWorkoutList() -> [workoutClass]? {
        return NSKeyedUnarchiver.unarchiveObjectWithFile(workoutClass.ArchiveURL!.path!) as? [workoutClass]
    }
    
    func loadUser(){
        print("Create accounts load user called")
        let loadedUser = (NSKeyedUnarchiver.unarchiveObjectWithFile(userClass.ArchiveURL!.path!) as? userClass)!
        thisUser = loadedUser
    }
    
    //MARK: Preperations for other views
    
    func createdDBEntries(user: userClass, completion: (foo: String) -> Void) {
        // 
        // Following code is to grab the OneSignal UserId to pass to the 
        // FB DB Creating block. 
        
        var oneSignalUserId: String!
        
        OneSignal.IdsAvailable({ (userId, pushToken) in
            oneSignalUserId = userId
            
            // Also sets the .oneSignalUserId property of userClass
            thisUser.oneSignalUserId = userId
            self.saveUser()
        })
        
        
        // Creating and setting the user in the DB in the /users/[username] and /colleges/[college]/users/[username]
        
        // Firebase Init
        var ref = FIRDatabaseReference.init()
        ref = FIRDatabase.database().reference()
        
        // username is the Dict. key for the user entries
        let username = user.userName
        
        // First DB entry, /users/[username]
        // Top-level User list
        let userRef = ref.child("users/\(username)")
        
        // Dict. representation of values in /users/[username] entry
        let userRefPayload = ["college": user.college, "email": user.email, "name": user.fullName, "bike":"None", "completedwo": ["init": true], "oneSignalUserId": oneSignalUserId]
        //  Uploads to FB DB | Setting the value of users/[username]
        userRef.setValue(userRefPayload) { (error: NSError?, database: FIRDatabaseReference) in
            if (error != nil) {
                print(error?.description)
            }
            else {
                print("users/username values set")
            }
        }
        
        // Second DB entry, /colleges/[college]/users/username/
        let collegeUserRef = ref.child("colleges/\(thisUser.college)/users/\(username)")
        
        collegeUserRef.setValue(oneSignalUserId) { (error: NSError?, database: FIRDatabaseReference) in
            if (error != nil) {
                print(error?.description)
            }
            else {
                print("college/[college]/users/[username] value set")
            }
        }
        
        completion(foo: "FOO")

    }
    
    func pullBikeListData(completion: (listOfBikes: [bikeClass]) -> Void) {
        // This takes everything from bikeList in FB, makes them into bikeClass objects, and appends said objects to bikeList array
        
        // Firebase Init
        var ref = FIRDatabaseReference.init()
        ref = FIRDatabase.database().reference()
        let bikeListRef = ref.child("colleges/\(thisUser.college)/bikeList/")
        
        var tempBikeList = [bikeClass]()
        
        // Iterate through all children of bikeList (see prev. decleration of path)
        bikeListRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            for child in snapshot.children {
                // Create bikeClass object from FB data
                let bikeShortName = child.value["shortName"] as! String
                let bikeFullName = child.value["fullName"] as! String
                let size = child.value["size"] as! String
                let status = child.value["status"] as! String
                let childsnap = child as! FIRDataSnapshot
                let bikeUsername = childsnap.key
    
                var riders = [String:String]()
                let riderDict = child.value["riders"] as! NSDictionary
                for rider in riderDict {
                    if rider.key as! String != "init" {
                        riders[rider.key as! String] = rider.value as! String
                    }
                }
                
                let bikeObject = bikeClass(bikeShortName: bikeShortName, bikeFullName: bikeFullName, size: size, riders: riders, status: status, bikeUsername: bikeUsername)
                tempBikeList.append(bikeObject)
                
                print(tempBikeList)
                // Save as you go, otherwise it'll just save an empty list b/c asycnchrony.
                self.saveBikeList(tempBikeList)
            }
            
            }, withCancelBlock: { error in
                print(error.description)
        })
    
        completion(listOfBikes: tempBikeList)
    }
    
    func pullWorkoutsData(completion: (listOfWorkouts: [workoutClass]) -> Void) {
        
        // Firebase Init
        print("beginning workout pull")
        var ref = FIRDatabaseReference.init()
        ref = FIRDatabase.database().reference()
        let workoutRef = ref.child("colleges/\(thisUser.college)/workouts")
        
        var tempWorkoutList = [workoutClass]()
        
        // Iterate through all children of workoutList (see prev. decleration of path)
        workoutRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            for child in snapshot.children {
                // Create workoutClass object from FB data
                let type = child.value["type"] as! String
                let unit = child.value["unit"] as! String
                let duration = child.value["duration"] as! [Int]
                let reps = child.value["reps"] as! [Int]
                let rest = child.value["rest"] as! [Int]
                let week = child.value["week"] as! [String]
                let notes = child.value["notes"] as! String
                
                let childSnap = child as! FIRDataSnapshot
                let workoutUsername = childSnap.key as! String
                
                var usersHaveCompleted = [String:String]()
                
                let usersHaveCompletedDict = child.value!["usersHaveCompleted"] as! NSDictionary
                for user in usersHaveCompletedDict {
                    if user.key as! String != "init" {
                        usersHaveCompleted[user.key as! String] = user.value as? String
                    }
                }
                
                let workoutObject = workoutClass(type: type, duration: duration, reps: reps, rest: rest,unit: unit, usersHaveCompleted: usersHaveCompleted, week: week, workoutUsername: workoutUsername, notes: notes)
                tempWorkoutList.append(workoutObject)
                
                // Save as you go, otherwise it'll just save an empty list b/c asycnchrony.
                self.saveWorkoutList(tempWorkoutList)
                
                print("workout list \(tempWorkoutList)")
            }
            
            }, withCancelBlock: { error in
                print(error.description)
        })
        

        completion(listOfWorkouts: tempWorkoutList)
        
    }

}
