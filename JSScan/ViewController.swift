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
    let photoOutput = AVCaptureStillImageOutput()
    let videoOutput = AVCaptureVideoDataOutput()

    var previewImageView = NSImageView()
    var previewToolbar = NSView()
    var previewText = NSTextView()
    
    var lastFoundText = ""
    
    var qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        setupPreviewImageView()
        setupPreviewToolbar()
        
        captureSession = AVCaptureSession()
        
        if #available(macOS 10.14, *) {
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
        } else {
            setupCaptureSession()
            
            if captureSession?.isRunning == false {
                captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func reloadTextView() {
        DispatchQueue.main.async {
            self.previewText.isEditable = true
            self.previewText.checkTextInDocument(nil)
            self.previewText.isEditable = false
        }
    }
    
    func setupCaptureSession() {
        captureSession.beginConfiguration()
        
        guard let inputDevice = AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: inputDevice),
            captureSession.canAddInput(videoInput),
            captureSession.canAddOutput(photoOutput),
            captureSession.canAddOutput(videoOutput) else { fatalError() }
        
        captureSession.sessionPreset = .photo
        
        captureSession.addInput(videoInput)
        
        photoOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        captureSession.addOutput(photoOutput)
        
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
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
    
    /* Very hard to get a stable image
    func setupPreviewImageView() {
        previewImageView.isHidden = true
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(previewImageView)
        
        previewImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        previewImageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        previewImageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        previewImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        previewImageView.widthAnchor.constraint(equalToConstant: 400).isActive = true
        previewImageView.heightAnchor.constraint(equalTo: previewImageView.widthAnchor).isActive = true
    }*/
    
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
    
    /* Very hard to get a stable image
    func captureStill(qrCodeLocation: Quadrilateral) {
        guard let connection = photoOutput.connection(with: .video) else {//, connection.isEnabled, connection.isActive else {
            fatalError()
        }
        
        photoOutput.captureStillImageAsynchronously(from: connection) { (buffer, error) in
            guard let buffer = buffer,
                error == nil,
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer),
                let image = NSImage(data: imageData),
                let directory = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true).first else { fatalError() }
     
            DispatchQueue.main.async {
                self.previewImageView.image = image.croppedToQuad(qrCodeLocation)
                self.previewImageView.isHidden = false
            }
            self.captureSession.stopRunning()
        }
    }*/
    
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
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
        guard let value = feature.messageString,
            lastFoundText != value else { return }
        
        lastFoundText = value
        
        if let url = URL(string: value) {
            NSWorkspace.shared.open(url)
        }
        
        DispatchQueue.main.async {
            // Set the value (on the MAIN queue) and check for links
            self.previewText.string = value
            self.reloadTextView()
        }
        
        print(value)
    }
}
