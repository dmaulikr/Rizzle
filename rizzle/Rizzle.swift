//
//  Rizzle.swift
//  rizzle
//
//  Created by Erin Luu on 2016-12-22.
//  Copyright © 2016 Erin Luu. All rights reserved.
//

import UIKit

class Rizzle: NSObject {
    var title: String!
    var question: String!
    var answer: String!
    var hint1: String!
    var hint2: String!
    var hint3: String!
    var letterBanks: Dictionary<String, Array<String>>!
    
    init(title: String, question: String, answer: String, hint1: String, hint2: String, hint3: String, letterBanks: Dictionary<String, Array<String>>) {
        super.init()
        
        self.title = title
        self.question = question
        self.answer = answer
        self.hint1 = hint1
        self.hint2 = hint2
        self.hint3 = hint3
        self.letterBanks = letterBanks
    }
    
    
}
