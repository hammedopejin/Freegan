//
//  ProfileVC.swift
//  Freegan
//
//  Created by Hammed Opejin on 8/14/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import UIKit

class ProfileVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    
    @IBAction func goToFeedTapped(_ sender: Any) {
        
         performSegue(withIdentifier: "profileToFeed", sender: nil)
    }
    
}
