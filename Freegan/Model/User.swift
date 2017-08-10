//
//  User.swift
//  Freegan
//
//  Created by Hammed Opejin on 8/8/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import Foundation
import Firebase

class User {
    private var _userName: String!
    private var _profileImgUrl: String!
    private var _uid: String!
    
    var userName: String {
        return _userName
    }
    
    var profileImgUrl: String {
        return _profileImgUrl
    }
    
    var uid: String {
        return _uid
    }
    
    
    init(uid: String, userName: String, profileImgUrl: String) {
        self._uid = uid
        self._userName = userName
        self._profileImgUrl = profileImgUrl
    }
    
    init(uid: String, postData: Dictionary<String, AnyObject>) {
        self._uid = uid
        
        if let userName = postData["userName"] as? String {
            self._userName = userName
        }
        
        
        if let profileImgUrl = postData["profileImgUrl"] as? String {
            self._profileImgUrl = profileImgUrl
        }
        
    }
    
    
}
