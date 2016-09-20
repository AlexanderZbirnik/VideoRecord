//
//  Timer.swift
//  VideoRecord
//
//  Created by Alex Zbirnik on 01.08.16.
//  Copyright © 2016 Alex Zbirnik. All rights reserved.
//

import UIKit

protocol TimerDelegate: class {
    
    func willStartTimer(_ timer: AZTimer)
    func didStartTimer(_ timer: AZTimer)
    
    func timer(_ timer:AZTimer, countTimerOnSecond: UInt32)
    
    func timer(_ timer:AZTimer, willPauseTimerOnSecond: UInt32)
    func timer(_ timer:AZTimer, didPauseTimerOnSecond: UInt32)
    
    func timer(_ timer:AZTimer, willResumeTimerOnSecond: UInt32)
    func timer(_ timer:AZTimer, didResumeTimerOnSecond: UInt32)
    
    func timer(_ timer:AZTimer, willStopTimerOnSecond: UInt32)
    func timer(_ timer:AZTimer, didStopTimerOnSecond: UInt32)
    
    func willFinishTimer(_ timer: AZTimer)
    func didFinishTimer(_ timer: AZTimer)
}

extension TimerDelegate {
    
    func willStartTimer(_ timer: AZTimer) {}
    func didStartTimer(_ timer: AZTimer) {}
    
    func timer(_ timer:AZTimer, countTimerOnSecond: UInt32) {}
    func timer(_ timer:AZTimer, willPauseTimerOnSecond: UInt32) {}
    func timer(_ timer:AZTimer, didPauseTimerOnSecond: UInt32) {}
    func timer(_ timer:AZTimer, willResumeTimerOnSecond: UInt32) {}
    func timer(_ timer:AZTimer, didResumeTimerOnSecond: UInt32) {}
    func timer(_ timer:AZTimer, willStopTimerOnSecond: UInt32) {}
    func timer(_ timer:AZTimer, didStopTimerOnSecond: UInt32) {}
    
    func willFinishTimer(_ timer: AZTimer) {}
}

class AZTimer: NSObject {
    
    fileprivate let seconds: UInt32
    
    fileprivate var timer: Timer?
    fileprivate var countSeconds: UInt32
    
    var delegate: ViewController?
    
    init(seconds:UInt32) {
        
        self.seconds = seconds
        self.countSeconds = 0
    }
    
    func startTimer() {
        
        self.delegate?.willStartTimer(self)
        startNewTimer()
        self.delegate?.didStartTimer(self)
    }
    
    func pauseTimer() {
        
        self.delegate?.timer(self, willPauseTimerOnSecond: self.countSeconds)
        self.timer?.invalidate()
        self.delegate?.timer(self, didPauseTimerOnSecond: self.countSeconds)
    }
    
    func resumeTime() {
        self.delegate?.timer(self, willResumeTimerOnSecond: self.countSeconds)
        startNewTimer()
        self.delegate?.timer(self, didResumeTimerOnSecond: self.countSeconds)
    }
    
    func stopTimer() {
        
        self.delegate?.timer(self, willStopTimerOnSecond: self.countSeconds)
        self.timer?.invalidate()
        self.delegate?.timer(self, didStopTimerOnSecond: self.countSeconds)
        self.countSeconds = 0
    }
    
    @objc fileprivate func counter() {
        
        if self.countSeconds < self.seconds - 1 {
            
            self.countSeconds += 1
            self.delegate?.timer(self, countTimerOnSecond: self.countSeconds)
            
        } else {
            
            self.delegate?.willFinishTimer(self)
            self.timer?.invalidate()
            self.countSeconds = 0
            self.delegate?.didFinishTimer(self)
        }
    }
    
    fileprivate func startNewTimer() {
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                                            selector: #selector(AZTimer.counter),
                                                            userInfo: nil,
                                                            repeats: true)
    }
}

