//
//  RecordButton.swift
//  VideoRecord
//
//  Created by Alex Zbirnik on 19.07.16.
//  Copyright © 2016 Alex Zbirnik. All rights reserved.
//

import UIKit

class RecordButton: UIButton {
    
    func startRecordVideo(start: Bool) {
        
        var activeIcon = UIImage()
        
        if start {
            
            activeIcon = UIImage.init(named: "recordOn")!
            
        } else {
            
            activeIcon = UIImage.init(named: "recordOff")!
        }
        setImage(activeIcon, forState: .Normal)
    }
    
    func title(title: String) {
        
        setTitle(title, forState: .Normal)
    }
}
