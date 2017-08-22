//
//  ContactGvVC.swift
//  Freegan
//
//  Created by Hammed Opejin on 8/14/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import UIKit
import Firebase

class ContactGvVC: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    var userName:String?
    var postKey:String?
    var listOfChatInfo = [Chat]()
    
    @IBOutlet weak var giverUsername: UILabel!
    @IBOutlet weak var giverImg: CircleView!
    @IBOutlet weak var caption: UITextView!
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var txtChatText: UITextField!
    @IBOutlet weak var laChatList: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadChatRoom()
        laChatList.delegate = self
        laChatList.dataSource = self
        
        DataService.ds.REF_POSTS.child(self.postKey!).observe(.value, with: { (snapshot) in
            
            
            
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    
                    
                    if let postDict = snap.value as? String {
                        if snap.key == "description"{
                            self.caption.text = snap.value as! String
                        }
                        if snap.key == "imageUrl"{
                            self.loadImg(imgUrl: snap.value as! String, imagePresent: self.postImage!)
                        }
                        if snap.key == "userName"{
                            self.giverUsername.text = snap.value as! String
                        }
                        if snap.key == "profileImgUrl"{
                            self.loadImg(imgUrl: snap.value as! String, imagePresent: self.giverImg!)
                        }
                        
                        
                    }
               }
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
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOfChatInfo.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chat = listOfChatInfo[indexPath.row]
        
        if let cellChat = tableView.dequeueReusableCell(withIdentifier: "TVCChat") as? TVCChat{
            
        cellChat.setChat(chat: chat)
        return cellChat
            
    } else {
            return TVCChat()
    }
    }
    
    
    func loadChatRoom(){
        
        DataService.ds.REF_CHATS.child(postKey!).queryOrdered(byChild: "postDate").observe( .value, with:
            { ( snapshot ) in
                //
                self.listOfChatInfo.removeAll()
                
                if let snapshot =  snapshot.children.allObjects as? [DataSnapshot]{
                    
                    for snap in snapshot {
                        print("SNAP: \(snap)")
                        if let postData = snap.value as? Dictionary<String, AnyObject>{
                            print("Happer: please")
                            let username = postData["name"] as? String
                            let text = postData["text"] as? String
                            
                            var postDate:CLong?
                            if let postdateIn = postData["postDate"] as? CLong {
                                postDate = postdateIn
                            }
                            
                            self.listOfChatInfo.append(Chat(userName: username!, text: text!, datePost: "\(postDate!)"))
                        }
                        
                    }
                    self.laChatList.reloadData()
                    let indexpath = IndexPath(row: self.listOfChatInfo.count-1, section: 0)
                    
                   // self.laChatList.scrollToRow(at: indexpath, at: .bottom, animated: true)
                    
                }
                
        })
    }
    
    
    
    
    @IBAction func buSendToRoom(_ sender: Any) {
        
       self.postToFirebase()
        
        
    }
    
    func postToFirebase() {
        
        let dic: Dictionary<String, AnyObject> = [ "text" : txtChatText.text!  as AnyObject,
                    "name" : userName!  as AnyObject,
                    "postDate" : ServerValue.timestamp()] as Dictionary<String, AnyObject>
        
        let firebasePost = DataService.ds.REF_CHATS.child(postKey!).childByAutoId()
        firebasePost.setValue(dic)
        txtChatText.text = ""
        
    }
    
    
    @IBAction func goToFeedTapped(_ sender: Any) {
         performSegue(withIdentifier: "goBcToFeed", sender: nil)
    }
    
}
