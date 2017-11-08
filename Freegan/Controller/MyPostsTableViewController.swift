//
//  MyPostsTableViewController.swift
//  Freegan
//
//  Created by Hammed Opejin on 11/5/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import UIKit
import Firebase
import SwiftKeychainWrapper

class MyPostsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    
    let searchController = UISearchController(searchResultsController: nil)
    var posts = [Post]()
    var filteredPosts: [Post] = []
    var currentUser: User?
    var imagePicker: UIImagePickerController!
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    var imageSelected = false
    var userName: String!
    var postKey: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        definesPresentationContext = true
        
        DataService.ds.REF_POSTS.observe(.value, with: {
            snapshot in
            
            self.posts = []
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                
                for snap in snapshot {

                            if let postDict = snap.value as? Dictionary<String, AnyObject> {
                                if (postDict["postUserObjectId"] as? String == KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID)!){
                                let key = snap.key
                                let post = Post(postKey: key, postData: postDict)
         
                                self.posts.append(post)
                                }
                            
                        }
                    
                    
                    
                }
            }
        })
        
    
        firebase.child(kUSER).queryOrdered(byChild: kOBJECTID).queryEqual(toValue: KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID)!).observe(.value, with: {
            snapshot in
            
            if snapshot.exists() {
                
                self.currentUser = User.init(_dictionary: ((snapshot.value as! NSDictionary).allValues as NSArray).firstObject! as! NSDictionary)
                
            }
            
        })
        
    }


    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return posts.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var post: Post
        
            post = posts[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? EditPostTableViewCell {
            
            if let img = MyPostsTableViewController.imageCache.object(forKey: post.imageUrl as NSString) {
                cell.configureCell(post: post, img: img)
            }else {
                cell.configureCell(post: post)
            }
            return cell
        } else {
            return EditPostTableViewCell()
        }
        
    }
    
    //MARK: TablevieDelegate
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        let post = posts[indexPath.row]
        self.postKey = post.postKey
        
        self.deleteWarning(indexPath: indexPath)
        
        
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var post: Post
        if searchController.isActive && searchController.searchBar.text != "" {
            
            post = filteredPosts[indexPath.row]
            
            
        } else {
            
            post = posts[indexPath.row]
        }
        
        self.postKey = post.postKey
        performSegue(withIdentifier: "goToEditPostItem", sender: nil)
        
        
    }
    
    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEditPostItem" {
            
            if let dis = segue.destination as? EditPostItemVC {
                dis.postKey = self.postKey
            }
        }
    }
    
    //MARK: Helper functions
    
    func deleteWarning(indexPath: IndexPath) {
        
        let alertController = UIAlertController(title: "Attention!", message: "Are you sure you want to delete post?", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (acation: UIAlertAction!) in
            
            DataService.ds.REF_POSTS.child(self.postKey!).removeValue { (error, ref) in
                
                if error != nil {
                    
                    // ProgressHUD.showError("Couldnt delete recent item: \(error!.localizedDescription)")
                }
            }
            self.posts.remove(at: indexPath.row)
            self.tableView.reloadData()
        }
        
        let noAction = UIAlertAction(title: "No", style: .destructive) { (acation: UIAlertAction!) in
            
        }
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func backBtnTapped(_ sender: Any) {
        performSegue(withIdentifier: "backToProfileVC", sender: nil)
    }
    
}
