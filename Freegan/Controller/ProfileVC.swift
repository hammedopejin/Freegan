//
//  ProfileVC.swift
//  Freegan
//
//  Created by Hammed Opejin on 8/14/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import UIKit
import Firebase

class ProfileVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let firebaseUser = DataService.ds.REF_USER_CURRENT
    
    
    @IBOutlet weak var profileImg: CircleView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userNameTF: FancyField!
    @IBOutlet weak var proflieImgChg: CircleView!
    
    var imagePicker: UIImagePickerController!
    var profileImgUrl: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        let firebaseUserName = firebaseUser.child("userName")
        let firebaseProfileImgUrl = firebaseUser.child("userImgUrl")
        firebaseUserName.observeSingleEvent(of: .value, with: { (snapshot) in
            if let value = snapshot.value as? String{
                self.userName.text = value
                self.userNameTF.placeholder = value
                print("Hammed:  userName: \(self.userName!)")
            }
        })
        firebaseProfileImgUrl.observeSingleEvent(of: .value, with: { (snapshot) in
            if let value = snapshot.value as? String{
                self.profileImgUrl = value
                self.loadImg(imgUrl: self.profileImgUrl, imagePresent: self.profileImg!)
                self.loadImg(imgUrl: self.profileImgUrl, imagePresent: self.proflieImgChg!)
            }
        })
        
        
    }
    
    
    

    func loadImg(imgUrl: String, imagePresent: UIImageView) {
        let ref = Storage.storage().reference(forURL: imgUrl)
        ref.getData(maxSize: 2 * 1024 * 1024, completion: { (data, error) in
            if error != nil {
                print("HAMMED: Unable to download image from Firebase storage")
            } else {
                print("HAMMED: Image downloaded from Firebase storage, goood newwwws")
                if let imgData = data {
                    if let img = UIImage(data: imgData) {
                        imagePresent.image = img
                        
                    }
                }
            }
        })
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image =  info[UIImagePickerControllerOriginalImage] as? UIImage{
            proflieImgChg.image = image
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    
    @IBAction func selectImgTapped(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    @IBAction func updateProfileBtn(_ sender: Any) {
        if let username = userNameTF.text, username != ""{
        firebaseUser.child("userName").setValue(username)
        }
        
        if let imgData = UIImageJPEGRepresentation(self.proflieImgChg.image!, 0.2) {
            
            let imgUid = NSUUID().uuidString
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            _ = Storage.storage().reference(forURL: self.profileImgUrl).delete()
            
            DataService.ds.REF_USER_IMAGES.child(imgUid).putData(imgData, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print("HAMMED: Unable to upload image to Firebasee torage")
                } else {
                    print("HAMMED: Successfully uploaded image to Firebase storage")
                    self.showToast(message: "Profile information successfully updated")
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    if let url = downloadURL {
                        self.firebaseUser.child("userImgUrl").setValue(url)
                    }
                }
            }
        }
        
    }
    @IBAction func goToFeedTapped(_ sender: Any) {
        performSegue(withIdentifier: "profileToFeed", sender: nil)
    }
    
}
