//
//  Utilities.swift
//  Freegan
//
//  Created by Hammed Opejin on 10/20/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import Foundation
import Firebase

private let dateFormat = "yyyyMMddHHmmss"

func dateFormatter() -> DateFormatter {
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = dateFormat
    
    return dateFormatter
}

func userDataFromCallerId(callerId: String, result: @escaping (_ callerName: String?, _ avatar: UIImage?) -> Void) {
    
    var avatarImage = UIImage(named: "avatarPlaceholder")
    
    firebase.child(kUSER).queryOrdered(byChild: kOBJECTID).queryEqual(toValue: callerId).observeSingleEvent(of: .value, with: {
        snapshot in
        
        
        if snapshot.exists() {
            
            let userDictionary = ((snapshot.value as! NSDictionary).allValues as Array).first
            
            let fUser = User.init(_dictionary: userDictionary as! NSDictionary)
            
            
            if fUser.userImgUrl != "" {
                imageFromData(pictureData: fUser.userImgUrl, withBlock: { (image) in
                    
                    avatarImage = image!
                    result(fUser.userName, avatarImage)
                    
                })
                
            } else {
                result(fUser.userName, avatarImage)
            }
            
            
        } else {
            
            result("Unknown Caller", avatarImage)
            
        }
        
    })
    
}

func maskRoundedImage(image: UIImage, radius: Float) -> UIImage {
    
    let imageView: UIImageView = UIImageView(image: image)
    var layer: CALayer = CALayer()
    layer = imageView.layer
    
    layer.masksToBounds = true
    layer.cornerRadius = CGFloat(radius)
    
    UIGraphicsBeginImageContext(imageView.bounds.size)
    layer.render(in: UIGraphicsGetCurrentContext()!)
    let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return roundedImage!
}

func imageFromData(pictureData: String, withBlock: (_ image: UIImage?) -> Void) {
    
    var image: UIImage?
    
    let decodedData = NSData(base64Encoded: pictureData, options: NSData.Base64DecodingOptions(rawValue: 0))
    
    
    image = UIImage(data: decodedData! as Data)
    
    withBlock(image)
    
}


