//
//  Timer.swift
//  VideoRecord
//
//  Created by Alex Zbirnik on 01.08.16.
//  Copyright © 2016 Alex Zbirnik. All rights reserved.
//

import UIKit

protocol TimerDelegate: class {
    
    func willStartTimer(timer: Timer)
    func didStartTimer(timer: Timer)
    
    func timer(timer:Timer, countTimerOnSecond: UInt32)
    
    func timer(timer:Timer, willPauseTimerOnSecond: UInt32)
    func timer(timer:Timer, didPauseTimerOnSecond: UInt32)
    
    func timer(timer:Timer, willResumeTimerOnSecond: UInt32)
    func timer(timer:Timer, didResumeTimerOnSecond: UInt32)
    
    func timer(timer:Timer, willStopTimerOnSecond: UInt32)
    func timer(timer:Timer, didStopTimerOnSecond: UInt32)
    
    func willFinishTimer(timer: Timer)
    func didFinishTimer(timer: Timer)
}

extension TimerDelegate {
    
    func willStartTimer(timer: Timer) {}
    func didStartTimer(timer: Timer) {}
    
    func timer(timer:Timer, countTimerOnSecond: UInt32) {}
    func timer(timer:Timer, willPauseTimerOnSecond: UInt32) {}
    func timer(timer:Timer, didPauseTimerOnSecond: UInt32) {}
    func timer(timer:Timer, willResumeTimerOnSecond: UInt32) {}
    func timer(timer:Timer, didResumeTimerOnSecond: UInt32) {}
    func timer(timer:Timer, willStopTimerOnSecond: UInt32) {}
    func timer(timer:Timer, didStopTimerOnSecond: UInt32) {}
    
    func willFinishTimer(timer: Timer) {}
}

class Timer: NSObject {
    
    private let seconds: UInt32
    
    private var timer: NSTimer?
    private var countSeconds: UInt32
    
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
    
    @objc private func counter() {
        
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
    
    private func startNewTimer() {
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self,
                                                            selector: #selector(Timer.counter),
                                                            userInfo: nil,
                                                            repeats: true)
    }
}

