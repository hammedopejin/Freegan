//
//  Chat.swift
//  Freegan
//
//  Created by Hammed Opejin on 8/14/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import UIKit

class Chat  {
    var userName:String?
    var text:String?
    var datePost:String?
    init(userName: String, text: String, datePost: String) {
        self.userName =  userName
        self.text =  text
        self.datePost = datePost
    }
}
