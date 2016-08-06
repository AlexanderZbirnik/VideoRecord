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
        self.captureSession!.sessionPreset = AVCaptureSessionPreset640x480
        
        self.videoDeviceInput = deviceInputWithMediaType(AVMediaTypeVideo, position: .Front)
        
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
        
        connection = self.movieFileOutput!.connectionWithMediaType(AVMediaTypeVideo)
        
        if connection!.supportsVideoStabilization == true{
            
            connection!.preferredVideoStabilizationMode = .Standard
        }
        connection!.videoOrientation = .Portrait
        
        self.captureSession!.commitConfiguration()
        
        self.captureSession?.startRunning()
    }
    
//MARK: - recording methods
    
    func changeCamera() -> AVCaptureDevicePosition {
        
        let videoDevice = self.videoDeviceInput?.device
        var devicePosition = videoDevice?.position
        
        if devicePosition == .Back {
            
            devicePosition = AVCaptureDevicePosition.Front
            
        } else {
            
            devicePosition = AVCaptureDevicePosition.Back
        }
        
        self.captureSession?.beginConfiguration()
        self.captureSession?.removeInput(self.videoDeviceInput)
        self.videoDeviceInput = deviceInputWithMediaType(AVMediaTypeVideo, position: devicePosition!)
        
        if self.captureSession!.canAddInput(self.videoDeviceInput) {
            self.captureSession!.addInput(self.videoDeviceInput)
        }
        
        self.captureSession?.commitConfiguration()
        
        return devicePosition!
    }
    
    func startRecordVideo() {
        
        let connection = self.movieFileOutput?.connectionWithMediaType(AVMediaTypeVideo)
        connection?.videoOrientation = (self.videoPreviewLayer?.connection.videoOrientation)!
        
        self.movieFileOutput?.startRecordingToOutputFileURL(uniqueFileURL(), recordingDelegate: self)
    }
    
    func stopRecordVideo() {
        
        self.movieFileOutput?.stopRecording()
    }
    
//MARK: - private init methods
    
     @objc private func audioInput() -> AVCaptureDeviceInput {
        
        let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        var audioInput = AVCaptureDeviceInput()
        
        do {
            audioInput = try AVCaptureDeviceInput(device: audioDevice)
            
        } catch let error as NSError {
            print(error)
        }
        return audioInput
    }
    
    @objc private func captureMovieFileOutput() -> AVCaptureMovieFileOutput {
        
        let movieFile = AVCaptureMovieFileOutput()
        
        movieFile.minFreeDiskSpaceLimit = 1024 * 1024
        
        return movieFile
    }
    
    @objc private func previewLayerWithFrame(frame: CGRect, session: AVCaptureSession) -> AVCaptureVideoPreviewLayer {
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer!.frame = frame
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
        
        return previewLayer
    }
    
    @objc private func deviceInputWithMediaType(mediaType: NSString, position: AVCaptureDevicePosition) -> AVCaptureDeviceInput {
        
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
    
//MARK: - private edit videorecord methods
    
    @objc private func uniqueFileURL() -> NSURL {
        
        let fileName = NSProcessInfo.processInfo().globallyUniqueString
        let filePath = "file:/\(NSTemporaryDirectory())\(fileName).mov"
        let fileUrl = NSURL(string: filePath)
        
        return fileUrl!
    }
    
    @objc private func cropFileWithURL(URL: NSURL) {
        
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
        
        let x = (clipVideoTrack?.naturalSize.height)!
        let y = -((clipVideoTrack?.naturalSize.width)! - (clipVideoTrack?.naturalSize.height)!) / 2
        
        print ("x = \(x), y = \(y)")
        
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
            
            //self.saveVieoToAlbumFromURL(outputhFileUrl)
            
            self.resizeFileWithURL(outputhFileUrl, newSize: CGSize(width: CropSize.width, height: CropSize.height))
        })
    }
    
    @objc private func resizeFileWithURL(URL: NSURL, newSize: CGSize) {
        
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
        
        let t3 = CGAffineTransformMakeScale(newSize.height / (clipVideoTrack?.naturalSize.height)!,
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
    
    @objc private func saveVieoToAlbumFromURL(URL: NSURL) {
        
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
    
// MARK: - AVCaptureFileOutputRecordingDelegate
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        print("Started")
        
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!){
        
        cropFileWithURL(outputFileURL)
    }

}
