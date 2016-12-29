//
//  RizzleManager.swift
//  rizzle
//
//  Created by Erin Luu on 2016-12-22.
//  Copyright © 2016 Erin Luu. All rights reserved.
//

import UIKit
import Parse

protocol RizzleSolverDelegate {
    func setCurrentRizzle(rizzle: Rizzle)
    func updateLoadStatus(update: String)
}

class RizzleManager: NSObject {
    //MARK: Shared Instance
    
    static let sharedInstance : RizzleManager = {
        let instance = RizzleManager()
        return instance
    }()
    
    var delegate: RizzleSolverDelegate?
    var currentUser: PFUser!
    var currentRizzlePFObject: PFObject?
    var currentRizzle: Rizzle?
    var currentTracker: PFObject?
    var solvedRizzleIDs: Array<String>?
    
    var letterBankLimit = 0
    
    private override init() {
        super.init()
        guard let user = PFUser.current() else{
            print("No current user")
            return
        }
        self.currentUser = user
    }
    
    //MARK: New Rizzle
    func generateNewRizzle() {
        let rizzleQueue = DispatchQueue(label: "rizzleQueue", qos: .userInitiated)
        //Get solved Rizzles
        rizzleQueue.async {
            self.delegate?.updateLoadStatus(update: "Loading Rizzles")
            self.findSolvedRizzleIDs()
        }
        //Get Unsolved Rizzles
        rizzleQueue.async {
            if self.solvedRizzleIDs != nil {
                self.delegate?.updateLoadStatus(update: "Searching for new Rizzles")
                self.findRandomUnsolvedRizzle()
            }
        }
        //Create a new tracker for this rizzle and user
        rizzleQueue.async {
            if self.currentRizzlePFObject != nil {
                self.delegate?.updateLoadStatus(update: "Creating trackers")
                self.createSolvedRizzleTracker()
                self.delegate?.updateLoadStatus(update: "Generating new Rizzle")
                self.generateRizzleObject()
            }
        }
        //Set Rizzle in SolverDelegate
        rizzleQueue.async {
            if self.currentRizzle != nil {
                self.delegate?.setCurrentRizzle(rizzle: self.currentRizzle!)
            }
        }
        
    }
    
    func findSolvedRizzleIDs(){
        // Get all Rizzle trackers with current user
        let query = PFQuery(className: "SolvedRizzle")
        query.includeKey("rizzle")
        query.whereKey("user", equalTo: currentUser)
        
        //Try finding the rizzles solve by the user
        do {
            let objects = try query.findObjects()
            
            //Declare array of all the rizzle solved by the user
            var solvedRizzleID = [String]()
            
            //For all the user trackers get the rizzle ID of each and put it into an array
            for tracker in objects {
                let rizzle = tracker.object(forKey: "rizzle") as! PFObject
                solvedRizzleID.append(rizzle.objectId!)
            }
            
            self.solvedRizzleIDs = solvedRizzleID
            
        } catch {
            print("Problem finding solved rizzles \(error)")
        }
    }
    
    func findRandomUnsolvedRizzle() {
        // Get 100 oldest Rizzles that haven't been started
        let query = PFQuery(className: "Rizzle")
        query.whereKey("objectId", notContainedIn: self.solvedRizzleIDs!)
        query.order(byAscending: "createdAt")
        query.limit = 100
        
        do {
            let rizzles = try query.findObjects()
            let randomNumber = Int(arc4random_uniform(UInt32((rizzles.count))))
            self.currentRizzlePFObject = rizzles[randomNumber]
        } catch {
            print("Problem finding new rizzles \(error)")
        }
    }
    
    func createSolvedRizzleTracker() {
        //Create a new rizzle trackers for current user
        let solvedRizzleTracker = PFObject(className:"SolvedRizzle")
        solvedRizzleTracker["user"] = currentUser
        solvedRizzleTracker["rizzle"] = currentRizzlePFObject
        solvedRizzleTracker["hint1Used"] = false
        solvedRizzleTracker["hint2Used"] = false
        solvedRizzleTracker["hint3Used"] = false
        solvedRizzleTracker["completed"] = false
        solvedRizzleTracker["score"] = 0
        
        solvedRizzleTracker.saveInBackground(block: { (success, error) in
            if (success) {
                print("Rizzle tracker saved")
                self.currentTracker = solvedRizzleTracker
            }else {
                print("Rizzle tracker no saved")
            }
        })
    }
    
    func generateRizzleObject() {
        let rizzle = Rizzle(title: (currentRizzlePFObject?.object(forKey: "title") as? String)!,
                            question: (currentRizzlePFObject?.object(forKey: "question") as? String)!,
                            answer: (currentRizzlePFObject?.object(forKey: "answer") as? String)!,
                            hint1: (currentRizzlePFObject?.object(forKey: "hint1") as? String)!,
                            hint2: (currentRizzlePFObject?.object(forKey: "hint2") as? String)!,
                            hint3: (currentRizzlePFObject?.object(forKey: "hint3") as? String)!,
                            letterBanks: generateLetterBanks()
        )
        currentRizzle = rizzle
    }
    
    func generateLetterBanks () -> Dictionary<String, Array<String>> {
        //Get answer from PFObject
        let answer = currentRizzlePFObject?.object(forKey: "answer") as! String
        
        //Set Letter Limit of how many letters to show in collection view
        if answer.characters.count <= 12 {
            letterBankLimit = 12
        } else {
            letterBankLimit = answer.characters.count
        }
        
        //Take answer and break into array of uppercase characters
        var letterBank = answer.characters.map({ (character) -> String in
            let letter = String(character).uppercased()
            return letter})
        
        //Remove all spaces from letterBank
        letterBank = letterBank.filter { $0 != " " }
        
        //Scramble the letterBank
        let scrambledAnswer = scrambleLetters(array: letterBank)
        
        //Breaking letterBank into starter and feeder sets
        var letterSets = [String: Array<String>]()
        letterSets = createStartingAndFeedingBanks(scramabledAnswer: scrambledAnswer)
        letterSets["answerLetterBank"] = letterBank
        
        return letterSets
    }
    
    
    //MARK: Letter Handlers
    func scrambleLetters(array: Array<String>) -> Array<String> {
        var letterBank = [String]()
        for _ in 0..<50
        {
            letterBank = array.sorted { (_,_) in arc4random() < arc4random() }
        }
        return letterBank
    }
    
    func createStartingAndFeedingBanks (scramabledAnswer: Array<String>) -> Dictionary<String, Array<String>> {
        //Create empty start and feeder arrays
        var feedingLetters = [String]()
        var startingLetters = [String]()
        
        //Based on length of the string, set how many letters to take out
        let removeCount: Int!
        if scramabledAnswer.count <= 5 {
            removeCount = 0
        }else if scramabledAnswer.count <= 6 {
            removeCount = 1
        }else if scramabledAnswer.count <= 10 {
            removeCount = 2
        }else {
            removeCount = 3
        }
        
        //Remove letters from starting and put into feeder
        feedingLetters += scramabledAnswer.suffix(removeCount)
        startingLetters += scramabledAnswer.prefix(scramabledAnswer.count-removeCount)
        
        //Create return dictionary
        let banks: [String: Array] = ["feedingLetterBank": feedingLetters, "startingLetterBank": startingLetters]
        return banks
    }
    
    //MARK: Continue Rizzle
    
}
