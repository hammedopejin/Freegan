//
//  EditPostTableViewCell.swift
//  Freegan
//
//  Created by Hammed Opejin on 11/5/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import UIKit
import Firebase

class EditPostTableViewCell: UITableViewCell {
    
    @IBOutlet weak var caption: UITextView!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var datePost: UILabel!
    @IBOutlet weak var postImg: UIImageView!
    
    
    var post: Post!
    
        override func awakeFromNib() {
            super.awakeFromNib()
        }
        
        
        func configureCell(post: Post, img: UIImage? = nil) {
            
            self.post = post
            
            self.caption.text = post.caption
            self.likesLbl.text = "\(post.likes)"
            self.datePost.text = post.postDate
            //self.postImg.image =  UIImage(named: "placeholder")
            
            if img != nil {
                self.postImg.image = img
            } else {
                let ref = Storage.storage().reference(forURL: post.imageUrl)
                ref.getData(maxSize: 2 * 1024 * 1024, completion: { (data, error) in
                    if error != nil {
                        print("HAMMED: Unable to download image from Firebase storage \(error.debugDescription)")
                    } else {
                        print("HAMMED: Image downloaded from Firebase storage")
                        if let imgData = data {
                            if let img = UIImage(data: imgData) {
                                self.postImg.image = img
                                MyPostsTableViewController.imageCache.setObject(img, forKey: post.imageUrl as NSString)
                            }
                        }
                    }
                })
            }
      
    }
    
    

}
