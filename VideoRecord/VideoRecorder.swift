//
//  VideoRecorder.swift
//  VideoRecord
//
//  Created by Alex Zbirnik on 06.08.16.
//  Copyright © 2016 Alex Zbirnik. All rights reserved.
//

import UIKit

import AVFoundation
import AssetsLibrary

class VideoRecorder: NSObject, AVCaptureFileOutputRecordingDelegate {
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var videoDeviceInput: AVCaptureDeviceInput?
    var audioDeviceInput: AVCaptureDeviceInput?
    var movieFileOutput: AVCaptureMovieFileOutput?
    
    init(preview:UIView) {
        
        super.init()
        
        self.captureSession = AVCaptureSession()
        self.videoDeviceInput = deviceInputWithMediaType(AVMediaTypeVideo as NSString, position: .front)
        self.captureSession!.sessionPreset = sessionPresetWithDevice(self.videoDeviceInput!.device)
        
        if self.captureSession!.canAddInput(self.videoDeviceInput) {
            self.captureSession!.addInput(self.videoDeviceInput)
        }
        
        self.audioDeviceInput = audioInput()
        
        if self.captureSession!.canAddInput(self.audioDeviceInput) {
            self.captureSession!.addInput(self.audioDeviceInput)
        }
        
        self.videoPreviewLayer = previewLayerWithFrame(preview.bounds, session: self.captureSession!)
        preview.layer.addSublayer(videoPreviewLayer!)
        
        self.movieFileOutput = captureMovieFileOutput()
        
        if self.captureSession!.canAddOutput(self.movieFileOutput) {
            self.captureSession!.addOutput(self.movieFileOutput)
        }
        
        let connection: AVCaptureConnection?
        
        connection = self.movieFileOutput!.connection(withMediaType: AVMediaTypeVideo)
        
        if connection!.isVideoStabilizationSupported == true{
            
            connection!.preferredVideoStabilizationMode = .standard
        }
        connection!.videoOrientation = .portrait
        
        self.captureSession!.commitConfiguration()
        
        self.captureSession?.startRunning()
    }
    
//MARK: - recording methods
    
    func changeCamera() -> AVCaptureDevicePosition {
        
        let videoDevice = self.videoDeviceInput?.device
        var devicePosition = videoDevice?.position
        
        if devicePosition == .back {
            
            devicePosition = AVCaptureDevicePosition.front
            
        } else {
            
            devicePosition = AVCaptureDevicePosition.back
        }
        
        self.captureSession?.beginConfiguration()
        self.captureSession?.removeInput(self.videoDeviceInput)
        self.videoDeviceInput = deviceInputWithMediaType(AVMediaTypeVideo as NSString, position: devicePosition!)
        self.captureSession!.sessionPreset = sessionPresetWithDevice(self.videoDeviceInput!.device)
        
        if self.captureSession!.canAddInput(self.videoDeviceInput) {
            self.captureSession!.addInput(self.videoDeviceInput)
        }
        
        self.captureSession?.commitConfiguration()
        
        return devicePosition!
    }
    
    func startRecordVideo() {
        
        let connection = self.movieFileOutput?.connection(withMediaType: AVMediaTypeVideo)
        connection?.videoOrientation = (self.videoPreviewLayer?.connection.videoOrientation)!
        
        self.movieFileOutput?.startRecording(toOutputFileURL: uniqueFileURL(), recordingDelegate: self)
    }
    
    func stopRecordVideo() {
        
        self.movieFileOutput?.stopRecording()
    }
    
//MARK: - private init methods
    
     @objc fileprivate func audioInput() -> AVCaptureDeviceInput {
        
        let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        var audioInput = AVCaptureDeviceInput()
        
        do {
            audioInput = try AVCaptureDeviceInput(device: audioDevice)
            
        } catch let error as NSError {
            print(error)
        }
        return audioInput
    }
    
    @objc fileprivate func captureMovieFileOutput() -> AVCaptureMovieFileOutput {
        
        let movieFile = AVCaptureMovieFileOutput()
        
        movieFile.minFreeDiskSpaceLimit = 1024 * 1024
        
        return movieFile
    }
    
    @objc fileprivate func previewLayerWithFrame(_ frame: CGRect, session: AVCaptureSession) -> AVCaptureVideoPreviewLayer {
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer!.frame = frame
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
        
        return previewLayer!
    }
    
    @objc fileprivate func deviceInputWithMediaType(_ mediaType: NSString, position: AVCaptureDevicePosition) -> AVCaptureDeviceInput {
        
        let devices = AVCaptureDevice.devices(withMediaType: mediaType as String)
        var captureDevice: AVCaptureDevice = devices!.first as! AVCaptureDevice
        
        for object in devices! {
            
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
    
    @objc fileprivate func sessionPresetWithDevice(_ device: AVCaptureDevice) -> String {
        
        var sessionPresets = [AVCaptureSessionPreset1920x1080, AVCaptureSessionPreset1280x720,
                              AVCaptureSessionPreset640x480, AVCaptureSessionPreset352x288]
        
        if #available(iOS 9.0, *) {
            
            sessionPresets.insert(AVCaptureSessionPreset3840x2160, at: 0)
        }
        
        for preset in sessionPresets {
            
            let isSupported = device.supportsAVCaptureSessionPreset(preset)
            
            if isSupported == true {
                
                return preset
            }
        }
        
        return ""
    }
    
//MARK: - private edit videorecord methods
    
    @objc fileprivate func uniqueFileURL() -> URL {
        
        let fileName = ProcessInfo.processInfo.globallyUniqueString
        let filePath = "file:/\(NSTemporaryDirectory())\(fileName).mov"
        let fileUrl = URL(string: filePath)
        
        return fileUrl!
    }
    
    @objc fileprivate func cropFileWithURL(_ URL: Foundation.URL) {
        
        let outputhFileUrl = uniqueFileURL()
        
        let asset = AVAsset(url: URL)
        
        let composition = AVMutableComposition()
        composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let clipVideoTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: (clipVideoTrack?.naturalSize.height)!, height: (clipVideoTrack?.naturalSize.height)!)
        videoComposition.frameDuration = CMTimeMake(1, 30)
        
        let instructions = AVMutableVideoCompositionInstruction()
        instructions.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(Float64(Time.maxDuration), 30))
        
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack!)
        
        let t1 = CGAffineTransform(translationX: (clipVideoTrack?.naturalSize.height)!,
                                                  y: -((clipVideoTrack?.naturalSize.width)! - (clipVideoTrack?.naturalSize.height)!) / 2)
        
        let x = (clipVideoTrack?.naturalSize.height)!
        let y = -((clipVideoTrack?.naturalSize.width)! - (clipVideoTrack?.naturalSize.height)!) / 2
        
        print ("x = \(x), y = \(y)")
        
        let t2 = t1.rotated(by: CGFloat(M_PI_2))
        
        let finalTransform = t2
        
        transformer.setTransform(finalTransform, at: kCMTimeZero)
        
        instructions.layerInstructions = [transformer]
        videoComposition.instructions = [instructions]
        
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        
        exporter?.videoComposition = videoComposition
        exporter?.outputURL = outputhFileUrl
        exporter?.outputFileType = AVFileTypeQuickTimeMovie
        
        exporter?.exportAsynchronously(completionHandler: {
            
            //self.saveVieoToAlbumFromURL(outputhFileUrl)
            
            self.resizeFileWithURL(outputhFileUrl, newSize: CGSize(width: CropSize.width, height: CropSize.height))
        })
    }
    
    @objc fileprivate func resizeFileWithURL(_ URL: Foundation.URL, newSize: CGSize) {
        
        let outputhFileUrl = uniqueFileURL()
        
        let asset = AVAsset(url: URL)
        
        let composition = AVMutableComposition()
        composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let clipVideoTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: newSize.width, height: newSize.height)
        videoComposition.frameDuration = CMTimeMake(1, 30)
        
        let instructions = AVMutableVideoCompositionInstruction()
        instructions.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(Float64(Time.maxDuration), 30))
        
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack!)
        
        let t3 = CGAffineTransform(scaleX: newSize.height / (clipVideoTrack?.naturalSize.height)!,
                                            y: newSize.width / (clipVideoTrack?.naturalSize.width)!)
        
        let finalTransform = t3
        
        transformer.setTransform(finalTransform, at: kCMTimeZero)
        
        instructions.layerInstructions = [transformer]
        videoComposition.instructions = [instructions]
        
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        
        exporter?.videoComposition = videoComposition
        exporter?.outputURL = outputhFileUrl
        exporter?.outputFileType = AVFileTypeQuickTimeMovie
        
        exporter?.exportAsynchronously(completionHandler: {
            
            self.saveVieoToAlbumFromURL(outputhFileUrl)
        })
    }
    
    @objc fileprivate func saveVieoToAlbumFromURL(_ URL: Foundation.URL) {
        
        let assetsLibrary = ALAssetsLibrary()
        
        if assetsLibrary.videoAtPathIs(compatibleWithSavedPhotosAlbum: URL) {
            
            assetsLibrary.writeVideoAtPath(toSavedPhotosAlbum: URL, completionBlock: { (url, error) in
                
                if error != nil {
                    
                    print("error: \(error)")
                    
                } else {
                    
                    print("Save to album! url: \(url)")
                }
            })
        }
    }
    
// MARK: - AVCaptureFileOutputRecordingDelegate
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        print("Started")
        
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!){
        
        cropFileWithURL(outputFileURL)
    }

}
