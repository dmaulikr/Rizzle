//
//  ViewController.swift
//  rizzle
//
//  Created by Erin Luu on 2016-12-15.
//  Copyright © 2016 Erin Luu. All rights reserved.
//

import UIKit
import FacebookLogin
import ParseFacebookUtilsV4

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func FBLoginTapped(_ sender: UIButton) {
        parseFacebookSignIn()
    }
    
    func parseFacebookSignIn() {
        PFFacebookUtils.logInInBackground(withReadPermissions: ["public_profile", "email"], block: {
            (user, error) in
            if let user = user {
                if user.isNew {
                    print("User signed up and logged in through Facebook!")
                    
                } else {
                    print("User logged in through Facebook!")
                }
            } else {
                print("Uh oh. The user cancelled the Facebook login.")
            }
        })
    }
    
}

