//
//  MyCell.swift
//  Freegan
//
//  Created by Hammed Opejin on 9/23/17.
//  Copyright © 2017 Hammed Opejin. All rights reserved.
//

import UIKit

//1. delegate method
protocol MyCellDelegate {
    func btnCloseTapped(cell: UITableViewCell)
}

class MyCell: UITableViewCell {
    @IBOutlet var btnClose: UIButton!
    
    //2. create delegate variable
    var delegate: MyCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    //3. assign this action to close button
    @IBAction func btnCloseTapped(sender: AnyObject){
        //4. call delegate method
        //check delegate is not nil
        if let _ = delegate {
            delegate?.btnCloseTapped(cell: self)
        }
    }
    
}

