//
//  FeedVC.swift
//  Freegan
//
//  Created by Hammed Opejin on 8/4/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import UIKit
import Firebase
import SwiftKeychainWrapper

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var userImage: CircleView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageAdd: CircleView!
    @IBOutlet weak var captionField: FancyField!
    
    let firebaseUser = DataService.ds.REF_USER_CURRENT
    var posts = [Post]()
    var user: User?
    var postKey: String?
    var imagePicker: UIImagePickerController!
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    var imageSelected = false
    var profileImgUrl: String!
    var userName: String!
    var userImgUrl: String!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        DataService.ds.REF_POSTS.observe(.value, with: { (snapshot) in
            
            self.posts = [] // THIS IS THE NEW LINE
            
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    print("SNAP: \(snap)")
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, postData: postDict)
                        
                        
                        self.posts.append(post)
                    }
                }
            }
            self.tableView.reloadData()
        })
        
        let firebaseUserName = firebaseUser.child("userName")
        let firebaseProfileImgUrl = firebaseUser.child("userImgUrl")
        firebaseUserName.observeSingleEvent(of: .value, with: { (snapshot) in
            if let value = snapshot.value as? String{
                self.userName = value
                print("Hammed:  userName: \(self.userName!)")
            }
        })
        firebaseProfileImgUrl.observeSingleEvent(of: .value, with: { (snapshot) in
            if let value = snapshot.value as? String{
                self.profileImgUrl = value
                print("Hammed:  profileImg: \(self.profileImgUrl!)")
                self.loadUserImg()
            }
        })
        
        
    }
    
    func loadUserImg() {
        if self.profileImgUrl != nil{
            let img = FeedVC.imageCache.object(forKey: self.profileImgUrl as NSString)
            if img != nil{
              self.userImage.image = img
            }else{
            let ref = Storage.storage().reference(forURL: self.profileImgUrl!)
            ref.getData(maxSize: 2 * 1024 * 1024, completion: { (data, error) in
                if error != nil {
                    print("HAMMED: Unable to download image from Firebase storage")
                } else {
                    print("HAMMED: Image downloaded from Firebase storage, goood newwwws")
                    if let imgData = data {
                        if let img = UIImage(data: imgData) {
                            self.userImage.image = img
                            FeedVC.imageCache.setObject(img, forKey: self.profileImgUrl as NSString)

                        }
                    }
                }
            })
        }
        }else{
            print("HAMMED: Image downloaded from Firebase storage, bd newwwws")
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let post = posts[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as? PostCell {
            
            if let img = FeedVC.imageCache.object(forKey: post.imageUrl as NSString), let img2 = FeedVC.imageCache.object(forKey: post.profileImgUrl as NSString) {
                cell.configureCell(post: post, img: img, img2: img2)
            } else {
                cell.configureCell(post: post)
            }
            self.postKey = post.postKey
            return cell
        } else {
            return PostCell()
        }
    }
    
    
    func postToFirebase(imgUrl: String) {
        

        let post: Dictionary<String, AnyObject> = [
            "description": captionField.text! as AnyObject,
            "imageUrl": imgUrl as AnyObject,
            "likes": 0 as AnyObject,
            "profileImgUrl": self.profileImgUrl! as AnyObject,
            "userName": self.userName! as AnyObject
        ]
        
        let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
        firebasePost.setValue(post)
        
        captionField.text = ""
        imageSelected = false
        imageAdd.image = UIImage(named: "add-image")
        
        tableView.reloadData()
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
    
    @IBAction func addImageTapped(_ sender: AnyObject) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func postBtnTapped(_ sender: Any) {
        guard let caption = captionField.text, caption != "" else {
            print("HAMMED: Caption must be entered")
            return
        }
        guard let img = imageAdd.image, imageSelected == true else {
            print("HAMMED: An image must be selected")
            return
        }
        
        if let imgData = UIImageJPEGRepresentation(img, 0.2) {
            
            let imgUid = NSUUID().uuidString
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_POST_IMAGES.child(imgUid).putData(imgData, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print("HAMMED: Unable to upload image to Firebasee torage")
                } else {
                    print("HAMMED: Successfully uploaded image to Firebase storage")
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    if let url = downloadURL {
                        self.postToFirebase(imgUrl: url)
                    }
                }
            }
        }
    }
    
    
    
    @IBAction func contactGvTapped(_ sender: Any) {
        
        performSegue(withIdentifier: "goToContactGv", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToContactGv" {
            
            if let dis = segue.destination as? ContactGvVC {
                dis.userName = self.userName
                dis.postKey = self.postKey
            }
        }
    }
    
    @IBAction func signOutTapped(_ sender: AnyObject) {
        
        let keychainResult = KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        print("HAMMED: ID removed from keychain \(keychainResult)")
        try! Auth.auth().signOut()
        performSegue(withIdentifier: "goToSignIn", sender: nil)
    }
    
    @IBAction func goToProfileTapped(_ sender: Any) {
        
        performSegue(withIdentifier: "goToProfile", sender: nil)
    }
    
}

