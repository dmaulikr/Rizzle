//
//  RizzleDisplayViewController.swift
//  rizzle
//
//  Created by Matthew Mauro on 2016-12-19.
//  Copyright © 2016 Erin Luu. All rights reserved.
//

import UIKit
import Parse

class RizzleDisplayViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var rizzleTableView: UITableView!
    var solvableRizzles = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let currentUser = PFUser.current() else{
            print("No current user")
            return
        }
        let query = PFQuery(className: "Rizzle")
        query.whereKey("_User", notEqualTo: currentUser.username!)
        query.findObjectsInBackground { (objects:[PFObject]?, error:Error?) in
            if error == nil {
                // find is successful
                // fill solvableRizzle Array with 5 rizzles, not completed by current user
                print("Successfully retrieved \(objects!.count) objects.")
                
                guard let objects = objects else {
                    print("No objects found")
                    return
                }
                let usedIndexes = NSMutableArray()
                for _ in 1...5 {
                    let rand = Int(arc4random_uniform(UInt32(objects.count)))
                    
                    if usedIndexes.contains(rand) == false {
                        usedIndexes.add(rand)
                        self.solvableRizzles.add(objects[rand])
                        self.rizzleTableView.reloadData()
                    }
                }
            } else {
                // Log details of the failure
                print("Error: \(error!)")
            }
        }
    }
    
    // Select cell, segue to SolveRizzle, with current rizzle in cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rizzleStoryboard: UIStoryboard = UIStoryboard(name: "Rizzle", bundle: nil)
        let solveRizzleView: SolveRizzleViewController = rizzleStoryboard.instantiateViewController(withIdentifier: "solveRizzle") as! SolveRizzleViewController
        solveRizzleView.currentRizzle = (solvableRizzles[indexPath.row] as! Rizzle)
        self.present(solveRizzleView, animated: true, completion: nil)
    }
    
    //MARK: - TableView DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rizzleCell", for: indexPath) as! RizzleCell
        let rizzle = self.solvableRizzles[indexPath.row] as! Rizzle
        cell.currentRizzle = rizzle
        cell.textLabel?.text = rizzle.title
        cell.detailTextLabel?.text = rizzle.description
        
        return cell
    }
}
