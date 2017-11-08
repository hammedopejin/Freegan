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

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate{
    
    @IBOutlet weak var userImage: CircleView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageAdd: CircleView!
    @IBOutlet weak var captionField: FancyField!
    
    let firebaseUser = DataService.ds.REF_USER_CURRENT
    let searchController = UISearchController(searchResultsController: nil)
    var posts = [Post]()
    var filteredPosts: [Post] = []
    var user: User?
    var currentUser: User?
    var postKey: String?
    var imagePicker: UIImagePickerController!
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    var imageSelected = false
    var profileImgUrl: String!
    var userName: String!
    var userImgUrl: String!
    var username: String!
    var postkey: String!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isEditing = false
        tableView.allowsSelection = true
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        searchBar.delegate = self
        searchBar.addSubview(searchController.searchBar)
        searchBar.returnKeyType = UIReturnKeyType.done
        
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        
        
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
        firebase.child(kUSER).queryOrdered(byChild: kOBJECTID).queryEqual(toValue: KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID)!).observe(.value, with: {
            snapshot in
            
            if snapshot.exists() {
                
                self.currentUser = User.init(_dictionary: ((snapshot.value as! NSDictionary).allValues as NSArray).firstObject! as! NSDictionary)
                
            }
            
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
            let ref = Storage.storage().reference(forURL: self.profileImgUrl!)
            
            ref.getData(maxSize: 2 * 1024 * 1024, completion: { (data, error) in
                if error != nil {
                    print("HAMMED: Unable to download image from Firebase storage \(error.debugDescription)")

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
        }else{
            print("HAMMED: Image downloaded from Firebase storage, bd newwwws")
        }
    }
    
    
    //MARK: TableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            
            return filteredPosts.count
            
        }
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var post: Post
        if searchController.isActive && searchController.searchBar.text != "" {
            
            post = filteredPosts[indexPath.row]
            
        } else {
            
            post = posts[indexPath.row]
        }
        
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
    
    
    //MARK: TablevieDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var post: Post
        if searchController.isActive && searchController.searchBar.text != "" {
            
            post = filteredPosts[indexPath.row]
            
        } else {
            
            post = posts[indexPath.row]
        }
        
        /////////////////////////////
        self.userName = post.userName
        self.postKey = post.postKey
        
        
        let chatVC = ChatViewController()
        
        firebase.child(kUSER).queryOrdered(byChild: kOBJECTID).queryEqual(toValue: post.postUserObjectId).observe(.value, with: {
            snapshot in
            
            if snapshot.exists() {
                
                self.user = User.init(_dictionary: ((snapshot.value as! NSDictionary).allValues as NSArray).firstObject! as! NSDictionary)
                if (self.user != nil) {
                    chatVC.titleName = self.user!.userName
                    chatVC.members = [(self.currentUser?.objectId)!, (self.user!.objectId)]
                    if ((self.currentUser) != nil) {
                    print((self.currentUser?.objectId)!)
                    chatVC.chatRoomId = startChat(user1: self.currentUser!, user2: self.user!)
                    
                    chatVC.hidesBottomBarWhenPushed = true
                    if (self.currentUser?.objectId != self.user!.objectId){
                            self.navigationController?.pushViewController(chatVC, animated: true)
                    }
                    }
                }
            }
            
        })

        
    }
    
    
    func postToFirebase(imgUrl: String) {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let result = formatter.string(from: date)
        
        
        let post: Dictionary<String, AnyObject> = [
            "description": captionField.text! as AnyObject,
            "imageUrl": imgUrl as AnyObject,
            "likes": 0 as AnyObject,
            "profileImgUrl": self.profileImgUrl! as AnyObject,
            "userName": self.currentUser!.userName as AnyObject,
            "postDate": result as AnyObject,
            "postUserObjectId": User.currentId() as AnyObject
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
            showToast(message: "Caption must be entered")
            return
        }
        guard let img = imageAdd.image, imageSelected == true else {
            showToast(message: "An image must be selected")
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
                    print("HAMMED: Unable to upload image to Firebasee torage")
                } else {
                    print("HAMMED: Successfully uploaded image to Firebase storage")
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    if let url = downloadURL {
                        self.postToFirebase(imgUrl: url)
                        
                        MBProgressHUD.hide(for: self.view, animated: true)
                        
                    }
                }
            }
        }
    }
    
    
    //MARK: SearchController functions
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        
        filteredPosts = posts.filter({ (post) -> Bool in
            return post.caption.lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
        
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoContactVC" {
            
            if let dis = segue.destination as? ChatViewController {
                dis.userName = self.userName
                dis.postKey = self.postKey
            }
        }
    }
    
    @IBAction func signOutTapped(_ sender: AnyObject) {
        
        let keychainResult = KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        print("HAMMED: ID removed from keychain \(keychainResult)")
        try! Auth.auth().signOut()
        
        
        //cleanupFirebaseObservers()
        
        
        
        let login = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignInVC")
        self.present(login, animated: true, completion: nil)
    }
    
    @IBAction func goToProfileTapped(_ sender: Any) {
        
        performSegue(withIdentifier: "goToProfile", sender: nil)
    }
    
}
