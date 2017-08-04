//
//  ViewController.swift
//  Freegan
//
//  Created by Hammed Opejin on 8/3/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import UIKit
import Firebase

class SignInVC: UIViewController {
    @IBOutlet weak var emailField: FancyField!
    @IBOutlet weak var pwdField: FancyField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    
    
    func firebaseAuth(_ credential: AuthCredential) {
        Auth.auth().signIn(with: credential, completion: { (user, error) in
            if error != nil {
                print("HAMMED: Unable to authenticate with Firebase - \(error)")
            } else {
                print("HAMMED: Successfully authenticated with Firebase")
//                if let user = user {
//                    let userData = ["provider": credential.provider]
//                    self.completeSignIn(id: user.uid, userData: userData)
//                }
            }
        })
    }

    @IBAction func signInTapped(_ sender: Any) {
        if let email = emailField.text, let pwd = pwdField.text {
            Auth.auth().signIn(withEmail: email, password: pwd, completion: { (user, error) in
                if error == nil {
                    print("HAMMED: Email user authenticated with Firebase")
                    if let user = user {
                        let userData = ["provider": user.providerID]
                        //self.completeSignIn(id: user.uid, userData: userData)
                    }
                } else {
                    Auth.auth().createUser(withEmail: email, password: pwd, completion: { (user, error) in
                        if error != nil {
                            print("HAMMED: Unable to authenticate with Firebase using email")
                        } else {
                            print("HAMMED: Successfully authenticated with Firebase")
                            if let user = user {
                                let userData = ["provider": user.providerID]
                                //self.completeSignIn(id: user.uid, userData: userData)
                            }
                        }
                    })
                }
            })
        }
    }
    
//    func completeSignIn(id: String, userData: Dictionary<String, String>) {
//        DataService.ds.createFirbaseDBUser(uid: id, userData: userData)
//        //let keychainResult = KeychainWrapper.setString(id, forKey: KEY_UID)
//        //let keychainResult = KeychainWrapper.defaultKeychainWrapper.set(id, forKey: KEY_UID)
//        print("HAMMED: Data saved to keychain \(keychainResult)")
//        performSegue(withIdentifier: "goToFeed", sender: nil)
//    }
    
}

