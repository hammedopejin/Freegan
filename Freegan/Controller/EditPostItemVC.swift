//
//  EditPostItemVC.swift
//  Freegan
//
//  Created by Hammed Opejin on 11/5/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import UIKit
import Firebase
import SwiftKeychainWrapper

class EditPostItemVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var caption: UITextView!
    @IBOutlet weak var captionField: FancyField!
    @IBOutlet weak var imageAdd: CircleView!
    
    
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    var postKey: String?
    var postImgUrl: String?
    var postDescription: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        DataService.ds.REF_POSTS.observe(.value, with: {
            snapshot in
            
            
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                
                for snap in snapshot {
                    
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        if (postDict["postUserObjectId"] as? String == KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID)!){
                            if (self.postKey == snap.key){
                                
                                self.postImgUrl = (postDict["imageUrl"] as? NSString)! as String
                                self.postDescription = postDict["description"] as? String
                                
                                self.caption.text = self.postDescription
                                
                                if let img = MyPostsTableViewController.imageCache.object(forKey: (postDict["imageUrl"] as? NSString)!){
                                if img != nil {
                                    self.postImage.image = img
                                } else {
                                    self.loadImg(imgUrl: self.postImgUrl!, imagePresent: self.postImage)
                                   
                                }
                            }
                            }
                        }
                    }
                }
            }
        })
    }

    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            imageAdd.image = image
            imageSelected = true
        } else {
            print("HAMMED: A valid image wasn't selected")
        }
        imagePicker.dismiss(animated: true, completion: nil)
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

    
    @IBAction func addImageTapped(_ sender: AnyObject) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func postBtnTapped(_ sender: Any) {
        if let caption = captionField.text, caption != ""{
            DataService.ds.REF_POSTS.child(self.postKey!).child("description").setValue(caption)
            captionField.text = ""
            self.showToast(message: "Post information successfully updated")
        }
        guard let img = imageAdd.image, imageSelected == true else {
            return
        }
        let spinningActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinningActivity.label.text = "Uploading Post"
        spinningActivity.detailsLabel.text = "Please Wait..."
        
        if let imgData = UIImageJPEGRepresentation(img, 0.2) {
            
            let imgUid = NSUUID().uuidString
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_POST_IMAGES.child(imgUid).putData(imgData, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print("HAMMED: Unable to upload image to Firebasee Storage \(error.debugDescription)")
                } else {
                    print("HAMMED: Successfully uploaded image to Firebase storage")
                    self.showToast(message: "Post pic successfully updated")
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    if let url = downloadURL {
                       // self.postToFirebase(imgUrl: url)
                        _ = Storage.storage().reference(forURL: self.postImgUrl!).delete()
                        DataService.ds.REF_POSTS.child(self.postKey!).child("imageUrl").setValue(url)
                        self.loadImg(imgUrl: url, imagePresent: self.postImage)
                       
                        MBProgressHUD.hide(for: self.view, animated: true)
                        
                    }
                }
            }
   
            
        }
    }
    
    
    @IBAction func backBtnTapped(_ sender: Any) {
        performSegue(withIdentifier: "backToMyPosts", sender: nil)
    }
    
}
