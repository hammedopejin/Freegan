//
//  RecentViewController.swift
//  Freegan
//
//  Created by Hammed Opejin on 10/22/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class RecentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    var recents: [NSDictionary] = []
    
    var firstLoad: Bool?
    
    var currentUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        firebase.child(kUSER).queryOrdered(byChild: kOBJECTID).queryEqual(toValue: KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID)!).observe(.value, with: {
            snapshot in
            
            if snapshot.exists() {
                
                self.currentUser = User.init(_dictionary: ((snapshot.value as! NSDictionary).allValues as NSArray).firstObject! as! NSDictionary)
                
            }
            
        })
        
        loadRecents()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    //MARK: UITableviewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return recents.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! RecentTableViewCell
        
        let recent = recents[indexPath.row]
        
        cell.bindData(recent: recent)
        
        return cell
    }
    
    
    //MARK: UITableview Delegate
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        let recent = recents[indexPath.row]
            
            recents.remove(at: indexPath.row)
            
            deleteRecentItem(recentID: (recent[kRECENTID] as? String)!)
            
            tableView.reloadData()
            
        
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let recent = recents[indexPath.row]
        
        restartRecentChat(recent: recent)
        
        let chatVC = ChatViewController()
        
        chatVC.hidesBottomBarWhenPushed = true
        chatVC.titleName = (recent[kWITHUSERUSERNAME] as? String)!
        chatVC.members = (recent[kMEMBERS] as? [String])!
        chatVC.chatRoomId = (recent[kCHATROOMID] as? String)!
        
        navigationController?.pushViewController(chatVC, animated: true)
        
    }
    
    //MARK: Load Recents
    
    func loadRecents() {
        
        firebase.child(kRECENT).queryOrdered(byChild: kUSERID).queryEqual(toValue: KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID)).observe(.value, with: {
            snapshot in
            
            self.recents.removeAll()
            
            if snapshot.exists() {
                
                let sorted = ((snapshot.value as! NSDictionary).allValues as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)])
                
                
                for recent in sorted {
                    
                    let currentRecent = recent as! NSDictionary
                    
                    self.recents.append(currentRecent)
                    
                    
                    firebase.child(kRECENT).queryOrdered(byChild: kCHATROOMID).queryEqual(toValue: currentRecent[kCHATROOMID]).observe(.value, with: {
                        snapshot in
                        
                    })
                    
                }
                
            }
            
            self.tableView.reloadData()
            
        })
        
    }
    

    
}
