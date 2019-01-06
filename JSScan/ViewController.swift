//
//  ViewController.swift
//  JSScan
//
//  Created by Julian Schiavo on 6/1/2019.
//  Copyright © 2019 Julian Schiavo. All rights reserved.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    let videoOutput = AVCaptureVideoDataOutput()

    var previewToolbar = NSView()
    var previewText = NSTextView()
    
    var qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPreviewToolbar()
        
        captureSession = AVCaptureSession()
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            setupCaptureSession()
            
            if captureSession?.isRunning == false {
                captureSession.startRunning()
            }
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupCaptureSession()
                    
                    if self.captureSession?.isRunning == false {
                        self.captureSession.startRunning()
                    }
                }
            }
            
        case .denied: // The user has previously denied access.
            return
        case .restricted: // The user can't grant access due to restrictions.
            return
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func setupCaptureSession() {
        captureSession.beginConfiguration()
        
        guard let inputDevice = AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: inputDevice),
            captureSession.canAddInput(videoInput),
            captureSession.canAddOutput(photoOutput),
            captureSession.canAddOutput(videoOutput) else { fatalError() }
        
        captureSession.addInput(videoInput)
        captureSession.addOutput(photoOutput)
        
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        captureSession.addOutput(videoOutput)
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "output.queue"))
        
        captureSession.commitConfiguration()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        previewLayer.connection?.isVideoMirrored = true
        previewLayer.frame = view.layer!.bounds
        view.layer?.addSublayer(previewLayer)
    }
    
    func setupPreviewToolbar() {
        previewToolbar.layer = CALayer()
        previewToolbar.layer?.backgroundColor = NSColor.darkGray.cgColor
        previewToolbar.layer?.masksToBounds = true
        previewToolbar.layer?.cornerRadius = 10
        
        previewToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewToolbar)
        
        previewToolbar.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        previewToolbar.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        previewToolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
        previewToolbar.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        
        setupPreviewText()
    }
    
    func setupPreviewText() {
        // Hide background
        previewText.isEditable = false
        previewText.drawsBackground = false
        
        // Set font, alignment, and link detection
        let font = NSFont.systemFont(ofSize: 16)
        previewText.font = font
        previewText.string = "Hold a QR code up to scan it"
        previewText.alignment = .center
        previewText.isAutomaticLinkDetectionEnabled = true
        previewText.textContainer?.maximumNumberOfLines = 1
        previewText.translatesAutoresizingMaskIntoConstraints = false
        
        // Calculate height
        let constraintRect = CGSize(width: view.frame.width - 60, height: .greatestFiniteMagnitude)
        let boundingBox = "Lorem ipsum dolor sit amet.".boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        let height = ceil(boundingBox.height)
        
        previewToolbar.addSubview(previewText)
        
        previewText.heightAnchor.constraint(equalToConstant: height).isActive = true
        previewText.topAnchor.constraint(equalTo: previewToolbar.topAnchor, constant: 10).isActive = true
        previewText.leftAnchor.constraint(equalTo: previewToolbar.leftAnchor, constant: 10).isActive = true
        previewText.rightAnchor.constraint(equalTo: previewToolbar.rightAnchor, constant: -10).isActive = true
        previewText.bottomAnchor.constraint(equalTo: previewToolbar.bottomAnchor, constant: -10).isActive = true
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let attachments = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvImageBuffer: pixelBuffer, options: attachments as? [CIImageOption : Any])
        
        guard let results = qrDetector?.features(in: ciImage) as? [CIQRCodeFeature],
            !results.isEmpty else { return }
        
        for result in results {
            foundQRCode(feature: result)
        }
    }
    
    func foundQRCode(feature: CIQRCodeFeature) {
        guard let value = feature.messageString else { return }
        
        DispatchQueue.main.async {
            // Set the value (on the MAIN queue) and check for links
            self.previewText.string = value
            self.previewText.isEditable = true
            self.previewText.checkTextInDocument(nil)
            self.previewText.isEditable = false
        }
        
        print(value)
    }
}
