//
//  ChatViewController.swift
//  Freegan
//
//  Created by Hammed Opejin on 10/20/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import JSQMessagesViewController
import Firebase
import SwiftKeychainWrapper

class ChatViewController: JSQMessagesViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    //////'''''''''' from legacy code
    @IBOutlet weak var giverUsername: UILabel!
    @IBOutlet weak var giverImg: CircleView!
    @IBOutlet weak var caption: UITextView!
    @IBOutlet weak var postImage: UIImageView!
    
    
    
    var userName:String?
    var postKey:String?
    ///////////'''''''''''
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let chatRef = firebase.child(kMESSAGE)
    let typingRef = firebase.child(kTYPINGPATH)
    
    var loadCount = 0
    var typingCounter = 0
    
    
    var max = 0
    var min = 0
    
    var messages: [JSQMessage] = []
    var objects: [NSDictionary] = []
    var loaded: [NSDictionary] = []
    
    var avatarImagesDictionary: NSMutableDictionary?
    var avatarDictionary: NSMutableDictionary?
    
    var members: [String] = []
    var withUsers: [User] = []
    var titleName: String?
    var currentUser: User?
    
    var chatRoomId: String!
    
    var initialLoadComplete: Bool = false
    var showAvatars = true
    var firstLoad: Bool?
    
    
    var outgoingBubble: JSQMessagesBubbleImage?
    var incomingBubble: JSQMessagesBubbleImage?
    
    
    override func viewWillAppear(_ animated: Bool) {
        clearRecentCounter(chatRoomID: chatRoomId)
        loadUserDefaults()
//        setBackgroundColor()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        clearRecentCounter(chatRoomID: chatRoomId)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inputToolbar.contentView.leftBarButtonItem = nil
        self.navigationController?.setNavigationBarHidden(false, animated: true)

        outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        
        incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        
        avatarDictionary = [ : ]


        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "backArrow"), style: .plain, target: self, action: #selector(ChatViewController.backAction))


        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero

        updateUI()/////
        ///////////
//        DataService.ds.REF_POSTS.child(self.postKey!).observe(.value, with: { (snapshot) in
//
//
//
//            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
//                for snap in snapshot {
//
//
//                    if (snap.value as? String) != nil {
//                        if snap.key == "description"{
//                            self.caption.text = snap.value as! String
//                        }else if snap.key == "imageUrl"{
//                            self.loadImg(imgUrl: snap.value as! String, imagePresent: self.postImage!)
//                        }else if snap.key == "userName"{
//                            self.giverUsername.text = snap.value as? String
//                        }else if snap.key == "profileImgUrl"{
//                            self.loadImg(imgUrl: snap.value as! String, imagePresent: self.giverImg!)
//                        }
//
//
//                    }
//                }
//            }
//
//        })

        firebase.child(kUSER).queryOrdered(byChild: kOBJECTID).queryEqual(toValue: KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID)!).observe(.value, with: {
            snapshot in

            if snapshot.exists() {

                self.currentUser = User.init(_dictionary: ((snapshot.value as! NSDictionary).allValues as NSArray).firstObject! as! NSDictionary)

            }

        })

        self.senderId = (KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID)!)
        self.senderDisplayName = currentUser?.userName

        self.title = titleName

        loadMessegas()
    }
    
    @objc func backAction() {
        clearRecentCounter(chatRoomID: chatRoomId)
        chatRef.child(chatRoomId).removeAllObservers()
        typingRef.child(chatRoomId).removeAllObservers()
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: JSQMessages Data Source functions
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let data = messages[indexPath.row]
        
        if data.senderId == self.currentUser!.objectId {
            
            cell.textView?.textColor = UIColor.white
            
        } else {
            
            cell.textView?.textColor = UIColor.black
        }
        
        return cell
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        
        let data = messages[indexPath.row]
        
        return data
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return messages.count
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let data = messages[indexPath.row]
        
        if data.senderId == self.currentUser!.objectId {
            
            return outgoingBubble
            
        } else {
            
            return incomingBubble
        }
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        
        if indexPath.item % 3 == 0 {
            
            let message = messages[indexPath.item]
            
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        
        let message = objects[indexPath.row]
        
        let status = message[kSTATUS] as! String
        
        if indexPath.row == (messages.count - 1) {
            
            return NSAttributedString(string: status)
        } else {
            return NSAttributedString(string: "")
        }
        
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        
        if outgoing(item: objects[indexPath.row]) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0.0
        }
    }
    
//    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
//
//        let message = messages[indexPath.row]
//
//        var avatar: JSQMessageAvatarImageDataSource
//
//        if let testAvatar = avatarDictionary!.object(forKey: message.senderId) {
//            avatar = testAvatar as! JSQMessageAvatarImageDataSource
//        } else {
//            avatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
//        }
//
//        return avatar
//
//
//    }
    
    
    //MARK: JSQMesages Delegate functions
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        if text != "" {
            
            sendMessage(text: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
        }
        
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        
        loadMore(maxNumber: max, minNumber: min)
        self.collectionView!.reloadData()
        
    }
    
//    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
//
//        let senderId = messages[indexPath.item].senderId
//        var selectedUser: User?
//
//
//        if senderId == User.currentId() {
//
//            selectedUser = User.currentUser()
//
//        } else {
//
//            for user in withUsers {
//
//                if user.objectId == senderId {
//
//                    selectedUser = user
//                }
//            }
//
//        }
//
//        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
//
//        vc.user = selectedUser!
//
//        self.present(vc, animated: true, completion: nil)
//
//
//    }
    
    //MARK: Send Message
    
    func sendMessage(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?) {
        
        var outgoingMessage: OutgoingMessage?
        
        
        //text message
        if let text = text {
            
            let encryptedText = EncryptText(chatRoomID: chatRoomId, string: text)
            
            outgoingMessage = OutgoingMessage(message: encryptedText, senderId: self.currentUser!.objectId, senderName: self.currentUser!.userName, date: date, status: kDELIVERED, type: kTEXT)
        }
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        
        outgoingMessage!.sendMessage(chatRoomID: chatRoomId, item: outgoingMessage!.messageDictionary)
    }
    
    
    //MARK: Responds to collection view tap events
//    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
//
//        let object = objects[indexPath.row]
//
//    }
    
    //MARK: Load Messages
    
    func loadMessegas() {
        
        createTypingObservers()
        
        let legitTypes = [kAUDIO, kVIDEO, kTEXT, kLOCATION, kPICTURE]
        
        
        chatRef.child(chatRoomId).observe(.childAdded, with: {
            snapshot in
            
            //update UI
            
            if snapshot.exists() {
                
                let item = (snapshot.value as? NSDictionary)!
                
                if let type = item[kTYPE] as? String {
                    
                    
                    if legitTypes.contains(type) {
                        
                        if self.initialLoadComplete {
                            
                            let incoming = self.insertMessage(item: item)
                            
                            if incoming {
                                
                                JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                
                            }
                            
                            self.finishReceivingMessage()
                            
                        } else {
                            
                            self.loaded.append(item)
                        }
                    }
                }
            }
        })
        
        
        chatRef.child(chatRoomId).observe(.childChanged, with: {
            snapshot in
            
            self.updateMessage(item: snapshot.value as! NSDictionary)
            
        })
        
        chatRef.child(chatRoomId).observeSingleEvent(of: .value, with: {
            snapshot in
            
            self.insertMessages()
            self.finishReceivingMessage(animated: false)
            self.initialLoadComplete = true
            
        })
        
    }
    
    func updateMessage(item: NSDictionary) {
        
        for index in 0 ..< objects.count {
            
            let temp = objects[index]
            
            if item[kMESSAGEID] as! String == temp[kMESSAGEID] as! String {
                
                objects[index] = item
                self.collectionView!.reloadData()
            }
        }
        
    }
    
    func insertMessages() {
        
        max = loaded.count - loadCount
        min = max - kNUMBEROFMESSAGES
        
        
        if min < 0 {
            min = 0
        }
        
        for i in min ..< max {
            
            let item = loaded[i]
            self.insertMessage(item: item)
            loadCount += 1
        }
        
        self.showLoadEarlierMessagesHeader = (loadCount != loaded.count)
    }
    
    
    func loadMore(maxNumber: Int, minNumber: Int) {
        
        max = minNumber - 1
        min = max - kNUMBEROFMESSAGES
        
        if min < 0 {
            
            min = 0
        }
        
        for i in (min ... max).reversed() {
            
            let item = loaded[i]
            self.insertNewMessage(item: item)
            loadCount += 1
        }
        
        self.showLoadEarlierMessagesHeader = (loadCount != loaded.count)
        
    }
    
    func insertNewMessage(item: NSDictionary) -> Bool {
        
        let incomingMessage = IncomingMessage(collectionView_: self.collectionView!)
        
        let message = incomingMessage.createMessage(dictionary: item, chatRoomID: chatRoomId)
        
        objects.insert(item, at: 0)
        messages.insert(message!, at: 0)
        
        return incoming(item: item)
    }
    
    
    func insertMessage(item: NSDictionary) -> Bool {
        
        let incomingMessage = IncomingMessage(collectionView_: self.collectionView!)
        
        if (((item[kSENDERID] as! String) != KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID)!)) {
            
            updateChatStatus(chat: item, chatRoomId: chatRoomId)
        }
        
        let message = incomingMessage.createMessage(dictionary: item, chatRoomID: chatRoomId)
        
        objects.append(item)
        messages.append(message!)
        
        return incoming(item: item)
        
    }
    
    
    func incoming(item: NSDictionary) -> Bool {
        
        if self.currentUser!.objectId == item[kSENDERID] as! String {
            return false
        } else {
            return true
        }
    }
    
    func outgoing(item: NSDictionary) -> Bool {
        
        if ((KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID)!) == item[kSENDERID] as! String) {
            
            return true
        } else {
            return false
        }
        
    }
    
    
    //MARK: Helper functions
    
    func updateUI() {
        
        getWithUserFromRecent(members: members) { (withUsers) in
            self.withUsers = withUsers
            //self.getAvatars()
        }
        
    }
    
    
    func getWithUserFromRecent(members: [String], result: @escaping (_ withUsers: [User]) -> Void) {
        
        var receivedMembers: [User] = []
        
        for userId in members {
            
            if userId != KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID) {
                
                firebase.child(kUSER).queryOrdered(byChild: kOBJECTID).queryEqual(toValue: userId).observe(.value, with: {
                    snapshot in
                    
                    if snapshot.exists() {
                        
                        let userDictionary = ((snapshot.value as! NSDictionary).allValues as Array).first
                        
                        let cUser = User.init(_dictionary: userDictionary as! NSDictionary)
                        
                        receivedMembers.append(cUser)
                        
                        if receivedMembers.count == (members.count - 1) {
                            
                            result(receivedMembers)
                        }
                        
                        
                    }
                    
                })
                
            }
        }
    }
    
    
    //MARK: UserDefaults
    
    func loadUserDefaults() {
        
        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        
        if !firstLoad! {
            
            userDefaults.set(true, forKey: kFIRSTRUN)
//            userDefaults.set(showAvatars, forKey: kAVATARSTATE)
            
//            userDefaults.set(1.0, forKey: kRED)
//            userDefaults.set(1.0, forKey: kGREEN)
//            userDefaults.set(1.0, forKey: kBLUE)
            
            userDefaults.synchronize()
        }
        
//        showAvatars = userDefaults.bool(forKey: kAVATARSTATE)
    }
    
//    func setBackgroundColor() {
//
//        self.collectionView.backgroundColor = UIColor(red: CGFloat(userDefaults.float(forKey: kRED)), green: CGFloat(userDefaults.float(forKey: kGREEN)), blue: CGFloat(userDefaults.float(forKey: kBLUE)), alpha: 1)
//
//    }
    
    
    
    //MARK: Typing indicator
    
    
    func createTypingObservers() {
        
        
        typingRef.child(chatRoomId).observe(.childChanged, with: {
            snapshot in
            
            if snapshot.key != User.currentId() {
                
                let typing = snapshot.value as! Bool
                self.showTypingIndicator = typing
                
                if typing {
                    
                    self.scrollToBottom(animated: true)
                }
            }
        })
        
    }
    
    
    func typingIndicatorStart() {
        
        typingCounter += 1
        typingIndicatorSave(typing: true)
        
        self.perform(#selector(ChatViewController.typingIndicatorStop), with: nil, afterDelay: 2.0)
    }
    
    @objc func typingIndicatorStop() {
        
        typingCounter -= 1
        
        if typingCounter == 0 {
            
            typingIndicatorSave(typing: false)
        }
    }
    
    func typingIndicatorSave(typing: Bool) {
        
        typingRef.child(chatRoomId).updateChildValues([User.currentId() : typing])
        
    }
    
    
    //MARK:  UITextViewDelegate
    
    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        typingIndicatorStart()
        return true
        
    }
    
  ///'''''''''''''''''''''''''''''''''''''From legacy code
    
    
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
    
    @IBAction func goToFeedTapped(_ sender: Any) {
        performSegue(withIdentifier: "goBcToFeed", sender: nil)
    }
    
    
}
