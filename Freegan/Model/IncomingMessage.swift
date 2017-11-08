//
//  IncomingMessage.swift
//  Freegan
//
//  Created by Hammed Opejin on 10/23/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import Foundation
import JSQMessagesViewController
import SwiftKeychainWrapper

public class IncomingMessage {
    
    var collectionView: JSQMessagesCollectionView
    
    init(collectionView_: JSQMessagesCollectionView) {
        collectionView = collectionView_
    }
    
    
    
    func createMessage(dictionary: NSDictionary, chatRoomID: String) -> JSQMessage? {
        
        var message: JSQMessage?
        
        let type = dictionary[kTYPE] as? String
        
        if type == kTEXT {
            
            message = createTextMessage(item: dictionary, chatRoomId: chatRoomID)
        }
        
        if message != nil {
            return message
        }
        
        return nil
    }
    
    
    func createTextMessage(item: NSDictionary, chatRoomId: String) -> JSQMessage {
        
        let name = item[kSENDERNAME] as? String
        let userId = item[kSENDERID] as? String
        
        let date = dateFormatter().date(from: (item[kDATE] as? String)!)
        
        
        let decryptedText = DecryptText(chatRoomID: chatRoomId, string: (item[kMESSAGE] as? String)!)
        
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, text: decryptedText)
        
    }
    
    
    func returnOutgoingStatusFromUser(senderId: String) -> Bool {
        
        if (senderId == (KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID)!))  {
            
            //outgoing
            return true
            
        } else {
            
            //incoming
            return false
        }
        
    }
    
}

