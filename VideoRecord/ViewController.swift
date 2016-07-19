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

enum Timer {
    
    static let zero: UInt16 = 0
    static let tenSeconds: UInt16 = 10
    static let oneMunute: UInt16 = 60
    static let oneHour: UInt16 = 3600
    static let maxDuration: UInt16 = 90
}

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    @IBOutlet weak var changeCameraBarButton: CameraBarButton!
    @IBOutlet weak var backGroundImageView: UIImageView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var screenView: UIView!
    @IBOutlet weak var recordButton: RecordButton!
    
    var captureSession: AVCaptureSession?
    var customPreviewLayer: AVCaptureVideoPreviewLayer?
    var videoDeviceInput: AVCaptureDeviceInput?
    var audioDeviceInput: AVCaptureDeviceInput?
    var videoDataOutput: AVCaptureVideoDataOutput?
    var sessionQueue: dispatch_queue_t?
    
    var startRecord: Bool = false
    var timer: NSTimer?
    var count: UInt16 = Timer.zero

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.translucent = true
        
        setupCameraSession()
        self.captureSession?.startRunning()
    }
    
// MARK: - Setup Camera Methods
    
    func setupCameraSession() {
        
        self.sessionQueue = dispatch_queue_create("videoQueue", DISPATCH_QUEUE_SERIAL)
        
        // Session
        self.captureSession = AVCaptureSession()
        self.captureSession!.sessionPreset = AVCaptureSessionPreset640x480
        
        self.videoDeviceInput = deviceInputWithMediaType(AVMediaTypeVideo, position: .Front)
        
        if self.captureSession!.canAddInput(self.videoDeviceInput) {
            self.captureSession!.addInput(self.videoDeviceInput)
        }
        
        self.audioDeviceInput = audioInput()
        
        if self.captureSession!.canAddInput(self.audioDeviceInput) {
            self.captureSession!.addInput(self.audioDeviceInput)
        }
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        self.customPreviewLayer = previewLayerWithFrame(self.screenView.bounds, session: self.captureSession!)
        
        self.screenView.layer.addSublayer(customPreviewLayer!)
        
        self.videoDataOutput = captureVideoDataOutput()
        
        if self.captureSession!.canAddOutput(self.videoDataOutput) {
            self.captureSession!.addOutput(self.videoDataOutput)
        }
        
        self.videoDataOutput!.setSampleBufferDelegate(self, queue: self.sessionQueue)
        
        self.captureSession!.commitConfiguration()
    }
    
    func audioInput() -> AVCaptureDeviceInput {
        
        let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        
        var audioInput = AVCaptureDeviceInput()
        
        do {
            audioInput = try AVCaptureDeviceInput(device: audioDevice)
            
        } catch let error as NSError {
            print(error)
        }
        return audioInput
    }
    
    func captureVideoDataOutput() -> AVCaptureVideoDataOutput {
        
        let videoData = AVCaptureVideoDataOutput()
        
        videoData.videoSettings =
        [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA)]
        
        videoData.alwaysDiscardsLateVideoFrames = true
        
        return videoData
    }
    
    func previewLayerWithFrame(frame: CGRect, session: AVCaptureSession) -> AVCaptureVideoPreviewLayer {
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer!.frame = frame
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
        
        return previewLayer
    }
    
    func deviceInputWithMediaType(mediaType: NSString, position: AVCaptureDevicePosition) -> AVCaptureDeviceInput {
        
        let devices = AVCaptureDevice.devicesWithMediaType(mediaType as String)
        var captureDevice: AVCaptureDevice = devices.first as! AVCaptureDevice
        
        for object:AnyObject in devices {
            
            let device = object as! AVCaptureDevice
            
            if (device.position == position) {
                
                captureDevice = device
                break
            }
        }
        
        var videoDeviceInput = AVCaptureDeviceInput()
        
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
        } catch let error as NSError {
            print(error)
        }
        
        return videoDeviceInput
    }
    
// MARK: - edit video methods
    
    func imageFromSampleBuffer(sampleBuffer: CMSampleBufferRef) -> UIImage {
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer!, 0)
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!)
        let width = CVPixelBufferGetWidth(imageBuffer!)
        let height = CVPixelBufferGetHeight(imageBuffer!)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue | CGBitmapInfo.ByteOrder32Little.rawValue)
        let context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace,bitmapInfo.rawValue)
        let qImage = CGBitmapContextCreateImage(context)
        CVPixelBufferUnlockBaseAddress(imageBuffer!, 0)
        let image = UIImage.init(CGImage: qImage!, scale: 1.0, orientation: UIImageOrientation.Right)
        return(image)
    }
    
//MARK: - timer methods
    
    func countTimer() {
        
        if self.count < (Timer.maxDuration - 1) {
            
            self.count += 1
            self.recordButton.title(formatDurationTitleWithCountSeconds(self.count))
            
        } else {
            
            self.timer?.invalidate()
            self.count = Timer.zero
            
            self.recordButton.title("00:00:00")
            self.recordButton.startRecordVideo(false)
        }
    }
    
    func formatDurationTitleWithCountSeconds(count: UInt16) -> String {
        
        var title = ""
        
        if count < Timer.oneMunute {
            
            title = "00:00:\(formatString(count))"
            
        } else if count >= Timer.oneMunute {
            
            var seconds = UInt16(Float(count) % Float(Timer.oneMunute))
            var minuts = count / Timer.oneMunute
            
            if minuts >= Timer.oneMunute {
                
                let hours = count / Timer.oneHour
                
                minuts = UInt16(Float(count) % Float(Timer.oneHour)) / Timer.oneMunute
                seconds = UInt16(Float(count) % Float(Timer.oneHour) % Float(Timer.oneMunute))
                
                title = "\(formatString(hours)):\(formatString(minuts)):\(formatString(seconds))"
                
            } else {
                
                title = "00:\(formatString(minuts)):\(formatString(seconds))"
            }
        }
        
        return title
    }
    
    func formatString(number:UInt16) -> String {
        
        if number < Timer.tenSeconds {
            
            return "0\(number)"
            
        } else {
            
            return "\(number)"
        }
    }
    
// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(captureOutput: AVCaptureOutput, didOutputSampleBuffer sampleBuffer: CMSampleBufferRef, fromConnection connection: AVCaptureConnection) {
        
        dispatch_async(dispatch_get_main_queue()) { 
            
            let image = self.imageFromSampleBuffer(sampleBuffer)
            
            self.backGroundImageView.image = image
        }
    }
    
// MARK: - Actions
    
    @IBAction func changeCameraAction(sender: CameraBarButton) {
        
        let videoDevice = self.videoDeviceInput?.device
        var devicePosition = videoDevice?.position
        var sessionPreset: String?
        var activeFront: Bool?
        
        if devicePosition == .Back {
            
            devicePosition = AVCaptureDevicePosition.Front
            sessionPreset = AVCaptureSessionPreset640x480
            activeFront = true
            
        } else {
            
            devicePosition = AVCaptureDevicePosition.Back
            sessionPreset = AVCaptureSessionPreset1920x1080
            activeFront = false
        }
        
        sender.activeFrontCamera(activeFront!)
        
        self.captureSession?.beginConfiguration()
        
        self.captureSession?.removeInput(self.videoDeviceInput)
        self.captureSession?.sessionPreset = sessionPreset
        
        self.videoDeviceInput = deviceInputWithMediaType(AVMediaTypeVideo, position: devicePosition!)

        if self.captureSession!.canAddInput(self.videoDeviceInput) {
            self.captureSession!.addInput(self.videoDeviceInput)
        }
        
        self.captureSession?.commitConfiguration()
    }
    
    @IBAction func startOrStopButtonAction(sender: RecordButton) {
        
        sender.startRecordVideo(self.startRecord)
        
        if self.startRecord == false {
            
            self.startRecord = true
            
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(countTimer), userInfo: nil, repeats: true)
            
        } else {
            
            self.startRecord = false
        }
        sender.startRecordVideo(self.startRecord)
    }
}















