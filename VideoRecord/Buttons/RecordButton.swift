//
//  RecordButton.swift
//  VideoRecord
//
//  Created by Alex Zbirnik on 19.07.16.
//  Copyright © 2016 Alex Zbirnik. All rights reserved.
//

import UIKit

class RecordButton: UIButton {
    
    func startRecordVideo(_ start: Bool) {
        
        var activeIcon = UIImage()
        
        if start {
            
            activeIcon = UIImage.init(named: "recordOn")!
            
        } else {
            
            activeIcon = UIImage.init(named: "recordOff")!
        }
        setImage(activeIcon, for: UIControlState())
    }
    
    func title(_ title: String) {
        
        setTitle(title, for: UIControlState())
    }
}
