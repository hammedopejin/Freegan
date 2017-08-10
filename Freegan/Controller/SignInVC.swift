//
//  SignInVC.swift
//  Freegan
//
//  Created by Hammed Opejin on 8/3/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import UIKit
import Firebase
import SwiftKeychainWrapper

class SignInVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var emailField: FancyField!
    @IBOutlet weak var pwdField: FancyField!
    @IBOutlet weak var userNameField: FancyField!
    @IBOutlet weak var userImg: UIImageView!
    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let _ = KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID){
            print("HAMMED: ID found in keychain")
            performSegue(withIdentifier: "goToFeed", sender: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image =  info[UIImagePickerControllerOriginalImage] as? UIImage{
            userImg.image = image
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    func firebaseAuth(_ credential: AuthCredential) {
        Auth.auth().signIn(with: credential, completion: { (user, error) in
            if error != nil {
                print("HAMMED: Unable to authenticate with Firebase - \(error)")
            } else {
                print("HAMMED: Successfully authenticated with Firebase")
                if let user = user {
                    let userData = ["provider": credential.provider]
                    self.completeSignIn(id: user.uid, userData: userData)
                }
            }
        })
    }
    
    func completeSignIn(id: String, userData: Dictionary<String, Any>) {
        DataService.ds.createFirbaseDBUser(uid: id, userData: userData as Dictionary<String, AnyObject>)
        let keychainResult = KeychainWrapper.defaultKeychainWrapper.set(id, forKey: KEY_UID)
        print("HAMMED: Data saved to keychain \(keychainResult)")
        performSegue(withIdentifier: "goToFeed", sender: nil)
    }
    
    @IBAction func signInTapped(_ sender: Any) {
        if let email = emailField.text, let pwd = pwdField.text {
            Auth.auth().signIn(withEmail: email, password: pwd, completion: { (user, error) in
                if error == nil {
                    print("HAMMED: Email user authenticated with Firebase")
                    if let user = user {
                        let userData = ["provider": user.providerID]
                        self.completeSignIn(id: user.uid, userData: userData)
                    }
                } else {
                    Auth.auth().createUser(withEmail: email, password: pwd, completion: { (user, error) in
                        if error != nil {
                            print("HAMMED: Unable to authenticate with Firebase using email")
                        } else {
                            print("HAMMED: Successfully authenticated with Firebase")
                            if let user = user {
                                let userData = ["provider": user.providerID, "userName": self.userNameField.text ?? "username"] as [String : Any]
                                self.completeSignIn(id: user.uid, userData: userData as! Dictionary<String, String>)
                            }
                        }
                    })
                }
            })
        }
    }
    @IBAction func registerTapped(_ sender: Any) {
        if let email = emailField.text, let pwd = pwdField.text {
                    Auth.auth().createUser(withEmail: email, password: pwd, completion: { (user, error) in
                        if error != nil {
                            print("HAMMED: Unable to authenticate with Firebase using email")
                        } else {
                            print("HAMMED: Successfully authenticated with Firebase")
                            if let user = user {
                                
                                if let imgData = UIImageJPEGRepresentation(self.userImg.image!, 0.2) {
                                    
                                    let imgUid = NSUUID().uuidString
                                    let metadata = StorageMetadata()
                                    metadata.contentType = "image/jpeg"
                                    
                                    DataService.ds.REF_USER_IMAGES.child(imgUid).putData(imgData, metadata: metadata) { (metadata, error) in
                                        if error != nil {
                                            print("HAMMED: Unable to upload image to Firebasee torage")
                                        } else {
                                            print("HAMMED: Successfully uploaded image to Firebase storage")
                                            let downloadURL = metadata?.downloadURL()?.absoluteString
                                            if let url = downloadURL {
                                                if self.userNameField.text == nil{ self.userNameField.text = "New User" }
                                                let userData = ["provider": user.providerID, "userImgUrl": url, "userName": self.userNameField.text!] as [String : Any]
                                                self.completeSignIn(id: user.uid, userData: userData)
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                        
                    })
                }
        
    }
    
    
    
    @IBAction func selectImg(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    
}

