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
    let objectId: String
    var pushId: String?
    
    let createdAt: Date
    var updatedAt: Date
    
    let email: String
    var userName: String
    var userImgUrl: String
    
    var friends: [String]
    
    let loginMethod: String
    
    //MARK: Initializers
    
    init(_objectId: String, _pushId: String?, _createdAt: Date, _updatedAt: Date, _email: String, _username: String, _userimgurl: String = "", _loginMethod: String, _friends: [String]) {
        
        objectId = _objectId
        pushId = _pushId
        
        createdAt = _createdAt
        updatedAt = _updatedAt
        
        email = _email
        userName = _username
        userImgUrl = _userimgurl
        friends = _friends
        
        loginMethod = _loginMethod
        
    }
    
    init(_dictionary: NSDictionary) {
        
        objectId = _dictionary[kOBJECTID] as! String
        pushId = _dictionary[kPUSHID] as? String
        
        createdAt = dateFormatter().date(from: _dictionary[kCREATEDAT] as! String)!
        updatedAt = dateFormatter().date(from:_dictionary[kUPDATEDAT] as! String)!
        
        email = _dictionary[kEMAIL] as! String
        userName = _dictionary[kUSERNAME] as! String
        userImgUrl = _dictionary[kAVATAR] as! String
        
        
        if let friend = _dictionary[kFRIEND] {
            
            friends = friend as! [String]
            
        } else {
            
            friends = []
        }
        
        
        loginMethod = _dictionary[kLOGINMETHOD] as! String
        
    }
    
    
    //MARK: Returning current user funcs
    
    class func currentId() -> String {
        
        return Auth.auth().currentUser!.uid
        
    }
    
//    class func currentUser () -> User? {
//
//        if Auth.auth().currentUser != nil {
//
//            let dictionary = UserDefaults.standard.object(forKey: kCURRENTUSER)
//
//            return User.init(_dictionary: dictionary as! NSDictionary)
//        }
//
//        return nil
//
//    }

    
    //MARK: Register functions
    
    class func registerUserWith(email: String, firuseruid: String, userName: String, userImgUrl: String) {
        
        let fuser = User.init(_objectId: firuseruid, _pushId: "", _createdAt: Date(), _updatedAt: Date(), _email: email, _username: userName, _userimgurl: userImgUrl, _loginMethod: kEMAIL, _friends: [])
            
            fuser.saveUserLocally(fuser: fuser)
            fuser.saveUserInBackground(fuser: fuser)
      
        
    }
    
    
    




//MARK: Save user funcs
func saveUserInBackground(fuser: User, completion: @escaping (_ error: Error?) -> Void) {
    
    let ref = firebase.child(kUSER).child(fuser.objectId)
    
    ref.setValue(userDictionaryFrom(user: fuser)) { (error, ref) -> Void in
        
        completion(error)
        
    }
    
}

func saveUserInBackground(fuser: User) {
    
    let ref = firebase.child(kUSER).child(fuser.objectId)
    
    ref.setValue(userDictionaryFrom(user: fuser))
    
}


func saveUserLocally(fuser: User) {
    
    UserDefaults.standard.set(userDictionaryFrom(user: fuser), forKey: kCURRENTUSER)
    UserDefaults.standard.synchronize()
    
}


//MARK: Fetch User funcs


 class func fetchUser(userId: String) -> User? {
    var user : NSDictionary = NSDictionary()
    firebase.child(kUSER).queryOrdered(byChild: kOBJECTID).queryEqual(toValue: userId).observe(.value, with: {
        snapshot in
        
        if snapshot.exists() {
            
            user = ((snapshot.value as! NSDictionary).allValues as NSArray).firstObject! as! NSDictionary
            //return User(_dictionary: user)
            
        } else {
            
            user = NSDictionary()
            
        }
        
    })
    return User.init(_dictionary: user) as User
    
}


//MARK: Helper funcs

func userDictionaryFrom(user: User) -> NSDictionary {
    
    let createdAt = dateFormatter().string(from: user.createdAt)
    let updatedAt = dateFormatter().string(from: user.updatedAt)
    
    return NSDictionary(objects: [user.objectId,  createdAt, updatedAt, user.email, user.loginMethod, user.pushId!, user.userName, user.userImgUrl, user.friends], forKeys: [kOBJECTID as NSCopying, kCREATEDAT as NSCopying, kUPDATEDAT as NSCopying, kEMAIL as NSCopying, kLOGINMETHOD as NSCopying, kPUSHID as NSCopying, kUSERNAME as NSCopying, kAVATAR as NSCopying, kFRIEND as NSCopying])
    
}

func cleanupFirebaseObservers() {
    
    firebase.child(kUSER).removeAllObservers()
    firebase.child(kRECENT).removeAllObservers()
}


//MARK: Update current user funcs

//func updateUser(withValues : [String : Any], withBlock: @escaping (_ success: Bool) -> Void) {
//
//
//    let currentUser = User.currentUser()!
//
//    let userObject = userDictionaryFrom(user: currentUser).mutableCopy() as! NSMutableDictionary
//
//    userObject.setValuesForKeys(withValues)
//
//    let ref = firebase.child(kUSER).child(User.currentId())
//
//    ref.updateChildValues(withValues, withCompletionBlock: {
//        error, ref in
//
//        if error != nil {
//            print("couldnt update user \(String(describing: error?.localizedDescription))")
//            withBlock(false)
//            return
//        }
//
//        //update current user
//        userDefaults.setValue(userObject, forKeyPath: kCURRENTUSER)
//        userDefaults.synchronize()
//
//        withBlock(true)
//
//    })
//}




//MARK: OneSignal

//func updateOneSignalId() {
//    
//    if User.currentUser() != nil {
//        
//        if let pushId = UserDefaults.standard.string(forKey: "OneSignalId") {
//            
//            setOneSignalId(pushId: pushId)
//            
//        } else {
//            
//            removeOneSignalId()
//        }
//    }
//}


//func setOneSignalId(pushId: String) {
//
//    updateCurrentUserOneSignalId(newId: pushId)
//}
//
//
//func removeOneSignalId() {
//
//    updateCurrentUserOneSignalId(newId: "")
//}

//MARK: Updating Current user funcs

//func updateCurrentUserOneSignalId(newId: String) {
//
//    let user = User.currentUser()
//    user!.pushId = newId
//    user!.updatedAt = Date()
//
//    saveUserLocally(fuser: user!)
//    saveUserInBackground(fuser: user!)
//}

//func updateCurrentUserAvatar(newAvatar: String) {
//
//    let user = User.currentUser()
//    user!.userImgUrl = newAvatar
//    user!.updatedAt = Date()
//
//    saveUserLocally(fuser: user!)
//    saveUserInBackground(fuser: user!)
//}
    
}
