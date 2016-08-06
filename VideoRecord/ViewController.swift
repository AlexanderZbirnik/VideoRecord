//
//  ViewController.swift
//  VideoRecord
//
//  Created by Alex Zbirnik on 18.07.16.
//  Copyright © 2016 Alex Zbirnik. All rights reserved.
//

import UIKit

import AVFoundation
import AssetsLibrary

enum Time {
    
    static let zero: UInt16 = 0
    static let tenSeconds: UInt16 = 10
    static let oneMunute: UInt16 = 60
    static let oneHour: UInt16 = 3600
    static let maxDuration: UInt16 = 90
}

enum CropSize {
    
    static let width: CGFloat = 300.0
    static let height: CGFloat = 300.0
}

class ViewController: UIViewController, TimerDelegate{
    
    
    @IBOutlet weak var changeCameraBarButton: CameraBarButton!
    @IBOutlet weak var backGroundImageView: UIImageView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var screenView: UIView!
    @IBOutlet weak var recordButton: RecordButton!
    
    var videoRecorder: VideoRecorder?
    
    var startRecord: Bool = false
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.translucent = true
        
        self.timer = Timer(seconds: UInt32(Time.maxDuration))
        self.timer?.delegate = self
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        
        self.videoRecorder = VideoRecorder(preview: self.screenView)
    }
    
    func stopRecoredVideo() {
        
        self.startRecord = false
        
        self.videoRecorder?.stopRecordVideo()
        
        self.recordButton.title("00:00:00")
        self.recordButton.startRecordVideo(false)
    }
        
    func formatDurationTitleWithCountSeconds(count: UInt16) -> String {
        
        var title = ""
        
        if count < Time.oneMunute {
            
            title = "00:00:\(formatString(count))"
            
        } else if count >= Time.oneMunute {
            
            var seconds = UInt16(Float(count) % Float(Time.oneMunute))
            var minuts = count / Time.oneMunute
            
            if minuts >= Time.oneMunute {
                
                let hours = count / Time.oneHour
                
                minuts = UInt16(Float(count) % Float(Time.oneHour)) / Time.oneMunute
                seconds = UInt16(Float(count) % Float(Time.oneHour) % Float(Time.oneMunute))
                
                title = "\(formatString(hours)):\(formatString(minuts)):\(formatString(seconds))"
                
            } else {
                
                title = "00:\(formatString(minuts)):\(formatString(seconds))"
            }
        }
        
        return title
    }
    
    func formatString(number:UInt16) -> String {
        
        if number < Time.tenSeconds {
            
            return "0\(number)"
            
        } else {
            
            return "\(number)"
        }
    }
    
// MARK: TimerDelegate
    
    func timer(timer:Timer, countTimerOnSecond: UInt32) {
        
        self.recordButton.title(formatDurationTitleWithCountSeconds(UInt16(countTimerOnSecond)))
    }
    
    func didFinishTimer(timer: Timer) {
        
        stopRecoredVideo()
    }

// MARK: - Actions
    
    @IBAction func changeCameraAction(sender: CameraBarButton) {
        
        var devicePosition = self.videoRecorder?.changeCamera()
        var activeFront: Bool?
        
        if devicePosition == .Back {
            
            devicePosition = AVCaptureDevicePosition.Front
            activeFront = true

        } else {

            devicePosition = AVCaptureDevicePosition.Back
            activeFront = false
        }
        
        sender.activeFrontCamera(activeFront!)
    }
    
    @IBAction func startOrStopButtonAction(sender: RecordButton) {
        
        if self.startRecord == false {
            
            self.startRecord = true
            self.timer?.startTimer()
            
            self.videoRecorder?.startRecordVideo()
            
        } else {
            
            stopRecoredVideo()
            self.timer?.stopTimer()
        }
        sender.startRecordVideo(self.startRecord)
    }
}













