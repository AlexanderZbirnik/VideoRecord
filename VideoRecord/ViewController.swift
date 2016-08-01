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

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, TimerDelegate{
    
    
    @IBOutlet weak var changeCameraBarButton: CameraBarButton!
    @IBOutlet weak var backGroundImageView: UIImageView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var screenView: UIView!
    @IBOutlet weak var recordButton: RecordButton!
    
    var captureSession: AVCaptureSession?
    var customPreviewLayer: AVCaptureVideoPreviewLayer?
    var videoDeviceInput: AVCaptureDeviceInput?
    var audioDeviceInput: AVCaptureDeviceInput?
    var movieFileOutput: AVCaptureMovieFileOutput?
    
    var startRecord: Bool = false
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.translucent = true
        
        self.timer = Timer(seconds: UInt32(Time.maxDuration))
        self.timer?.delegate = self
        
        setupCameraSession()
        self.captureSession?.startRunning()
    }
    
// MARK: - Setup Camera Methods
    
    func setupCameraSession() {
                
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
        
        self.movieFileOutput = captureMovieFileOutput()

        if self.captureSession!.canAddOutput(self.movieFileOutput) {
            self.captureSession!.addOutput(self.movieFileOutput)
        }

        let connection: AVCaptureConnection?

       connection = self.movieFileOutput!.connectionWithMediaType(AVMediaTypeVideo)
        
        if connection!.supportsVideoStabilization == true{
            
            connection!.preferredVideoStabilizationMode = .Standard
        }
        connection!.videoOrientation = .Portrait
        
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
    
    func captureMovieFileOutput() -> AVCaptureMovieFileOutput {
        
        let movieFile = AVCaptureMovieFileOutput()
        
        movieFile.minFreeDiskSpaceLimit = 1024 * 1024
        
        return movieFile
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
    
//MARK: - edit video methods
    
    func cropFileWithURL(URL: NSURL) {
        
        let outputhFileUrl = uniqueFileURL()
        
        let asset = AVAsset(URL: URL)
        
        let composition = AVMutableComposition()
        composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let clipVideoTrack = asset.tracksWithMediaType(AVMediaTypeVideo).first
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: (clipVideoTrack?.naturalSize.height)!, height: (clipVideoTrack?.naturalSize.height)!)
        videoComposition.frameDuration = CMTimeMake(1, 30)
        
        let instructions = AVMutableVideoCompositionInstruction()
        instructions.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(Float64(Time.maxDuration), 30))
        
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack!)
        
        let t1 = CGAffineTransformMakeTranslation((clipVideoTrack?.naturalSize.height)!,
                                                  -((clipVideoTrack?.naturalSize.width)! - (clipVideoTrack?.naturalSize.height)!) / 2)
        
        let t2 = CGAffineTransformRotate(t1, CGFloat(M_PI_2))
        
        let finalTransform = t2
        
        transformer.setTransform(finalTransform, atTime: kCMTimeZero)
        
        instructions.layerInstructions = [transformer]
        videoComposition.instructions = [instructions]
        
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        
        exporter?.videoComposition = videoComposition
        exporter?.outputURL = outputhFileUrl
        exporter?.outputFileType = AVFileTypeQuickTimeMovie
        
        exporter?.exportAsynchronouslyWithCompletionHandler({
            
            self.resizeFileWithURL(outputhFileUrl, newSize: CGSize(width: CropSize.width, height: CropSize.height))
        })
    }
    
    func resizeFileWithURL(URL: NSURL, newSize: CGSize) {

        let outputhFileUrl = uniqueFileURL()
        
        let asset = AVAsset(URL: URL)
        
        let composition = AVMutableComposition()
        composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let clipVideoTrack = asset.tracksWithMediaType(AVMediaTypeVideo).first
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: newSize.width, height: newSize.height)
        videoComposition.frameDuration = CMTimeMake(1, 30)
        
        let instructions = AVMutableVideoCompositionInstruction()
        instructions.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(Float64(Time.maxDuration), 30))
        
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack!)
        
        let t1 = CGAffineTransformMakeTranslation(0, 0)
        
        let t3 = CGAffineTransformScale(t1, newSize.height / (clipVideoTrack?.naturalSize.height)!,
                                            newSize.width / (clipVideoTrack?.naturalSize.width)!)
        
        let finalTransform = t3
        
        transformer.setTransform(finalTransform, atTime: kCMTimeZero)
        
        instructions.layerInstructions = [transformer]
        videoComposition.instructions = [instructions]
        
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        
        exporter?.videoComposition = videoComposition
        exporter?.outputURL = outputhFileUrl
        exporter?.outputFileType = AVFileTypeQuickTimeMovie
        
        exporter?.exportAsynchronouslyWithCompletionHandler({
            
            self.saveVieoToAlbumFromURL(outputhFileUrl)
        })
    }
    
    func saveVieoToAlbumFromURL(URL: NSURL) {
        
        let assetsLibrary = ALAssetsLibrary()
        
        if assetsLibrary.videoAtPathIsCompatibleWithSavedPhotosAlbum(URL) {
            
            assetsLibrary.writeVideoAtPathToSavedPhotosAlbum(URL, completionBlock: { (url, error) in
                
                if error != nil {
                    
                    print("error: \(error)")
                    
                } else {
                    
                    print("Save to album! url: \(url)")
                }
            })
        }
    }
    
    func stopRecoredVideo() {
        
        self.startRecord = false
        self.movieFileOutput?.stopRecording()
        
        self.recordButton.title("00:00:00")
        self.recordButton.startRecordVideo(false)
    }
    
    func uniqueFileURL() -> NSURL {
        
        let fileName = NSProcessInfo.processInfo().globallyUniqueString
        let filePath = "file:/\(NSTemporaryDirectory())\(fileName).mov"
        let fileUrl = NSURL(string: filePath)
        
        return fileUrl!
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
    
// MARK: - AVCaptureFileOutputRecordingDelegate
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        print("Started")
        
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!){
        
        cropFileWithURL(outputFileURL)
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
        
        let videoDevice = self.videoDeviceInput?.device
        var devicePosition = videoDevice?.position
        var activeFront: Bool?
        
        if devicePosition == .Back {
            
            devicePosition = AVCaptureDevicePosition.Front
            activeFront = true
            
        } else {
            
            devicePosition = AVCaptureDevicePosition.Back
            activeFront = false
        }
        
        sender.activeFrontCamera(activeFront!)
        
        self.captureSession?.beginConfiguration()
        self.captureSession?.removeInput(self.videoDeviceInput)
        self.videoDeviceInput = deviceInputWithMediaType(AVMediaTypeVideo, position: devicePosition!)

        if self.captureSession!.canAddInput(self.videoDeviceInput) {
            self.captureSession!.addInput(self.videoDeviceInput)
        }
        
        self.captureSession?.commitConfiguration()
    }
    
    @IBAction func startOrStopButtonAction(sender: RecordButton) {
        
        if self.startRecord == false {
            
            self.startRecord = true
            self.timer?.startTimer()
            
            let connection = self.movieFileOutput?.connectionWithMediaType(AVMediaTypeVideo)
            connection?.videoOrientation = (self.customPreviewLayer?.connection.videoOrientation)!

            self.movieFileOutput?.startRecordingToOutputFileURL(uniqueFileURL(), recordingDelegate: self)
            
        } else {
            
            stopRecoredVideo()
            self.timer?.stopTimer()
        }
        sender.startRecordVideo(self.startRecord)
    }
}













