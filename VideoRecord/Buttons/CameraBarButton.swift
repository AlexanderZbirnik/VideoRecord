//
//  CameraBarButton.swift
//  VideoRecord
//
//  Created by Alex Zbirnik on 19.07.16.
//  Copyright © 2016 Alex Zbirnik. All rights reserved.
//

import UIKit

class CameraBarButton: UIBarButtonItem {
    
    func activeFrontCamera(active: Bool) {
        
        if active {
            
            image = UIImage.init(named: "ic_camera_rear_white")!
            
        } else {
            
            image = UIImage.init(named: "ic_camera_front_white")!
        }
    }

}
