//
//  RecentTableViewCell.swift
//  Freegan
//
//  Created by Hammed Opejin on 10/22/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import UIKit
import Firebase

class RecentTableViewCell: UITableViewCell {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func bindData(recent: NSDictionary) {
        
        avatarImageView.layer.cornerRadius = avatarImageView.frame.size.width/2
        avatarImageView.layer.masksToBounds = true
        
        avatarImageView.image = UIImage(named: "avatarPlaceholder")
        
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.5
        
        if (recent[kTYPE] as? String)! == kPRIVATE {
            
            let withUserId = (recent[kWITHUSERUSERID] as! String)
            
            firebase.child(kUSER).queryOrdered(byChild: kOBJECTID).queryEqual(toValue: withUserId).observe(.value, with: {
                snapshot in
                
                if snapshot.exists() {
                    
                    let userDictionary = ((snapshot.value as! NSDictionary).allValues as Array).first
                    
                    
                    let fUser = User.init(_dictionary: userDictionary as! NSDictionary)
                    
                    if fUser.userImgUrl != "" {
                        
                        let ref = Storage.storage().reference(forURL: fUser.userImgUrl)
                        
                        ref.getData(maxSize: 2 * 1024 * 1024, completion: { (data, error) in
                            if error != nil {
                                print("HAMMED: Unable to download image from Firebase storage \(error.debugDescription)")
                                
                            } else {
                                print("HAMMED: Image downloaded from Firebase storage, goood newwwws")
                                if let imgData = data {
                                    if let img = UIImage(data: imgData) {
                                        self.avatarImageView.image = img
                                        RecentTableViewCell.imageCache.setObject(img, forKey: fUser.userImgUrl as NSString)
                                        
                                    }
                                }
                            }
                        })
                        
                    }
                    
                }
                
            })
            
        }
        
        nameLabel.text = recent[kWITHUSERUSERNAME] as? String
        
        
        lastMessageLabel.text = DecryptText(chatRoomID: (recent[kCHATROOMID] as? String)!, string: (recent[kLASTMESSAGE] as? String)!)
        
        counterLabel.text = ""
        
        if (recent[kCOUNTER] as? Int)! != 0 {
            counterLabel.text = "\(recent[kCOUNTER]!) New"
        }
        
        let date = dateFormatter().date(from: recent[kDATE] as! String)
        
        dateLabel.text = timeElapsed(date: date!)
    }
    
    
    func timeElapsed(date: Date) -> String {
        
        let seconds = NSDate().timeIntervalSince(date)
        
        let elapsed: String?
        
        if seconds < 60 {
            elapsed = "Just Now"
        } else {
            
            let currentDateFormater = dateFormatter()
            currentDateFormater.dateFormat = "dd/MM/YYYY"
            
            elapsed = "\(currentDateFormater.string(from: date))"
            
        }
        
        return elapsed!
    }
    
    
}
