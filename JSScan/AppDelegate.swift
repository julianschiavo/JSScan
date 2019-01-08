//
//  AppDelegate.swift
//  JSScan
//
//  Created by Julian Schiavo on 6/1/2019.
//  Copyright © 2019 Julian Schiavo. All rights reserved.
//

import Cocoa
import AVFoundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func startScanning() {
        guard let window = NSApplication.shared.mainWindow,
            let vc = window.contentViewController as? ViewController,
            !vc.captureSession.isRunning else { return }
        
        if #available(macOS 10.14, *) {
            if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                vc.captureSession.startRunning()
            }
        } else {
            vc.captureSession.startRunning()
        }
        
        vc.previewText.string = "Hold a QR code up to scan it"
        vc.reloadTextView()
    }
    
    func pauseScanning() {
        guard let window = NSApplication.shared.mainWindow,
            let vc = window.contentViewController as? ViewController,
            vc.captureSession.isRunning else { return }
        
        vc.captureSession.stopRunning()
        
        vc.previewText.string = "Paused"
        vc.reloadTextView()
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        startScanning()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        startScanning()
    }
    
    func applicationWillUnhide(_ notification: Notification) {
        startScanning()
    }
    
    func applicationDidUnhide(_ notification: Notification) {
        startScanning()
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        pauseScanning()
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        pauseScanning()
    }
    
    func applicationWillHide(_ notification: Notification) {
        startScanning()
    }
    
    func applicationDidHide(_ notification: Notification) {
        startScanning()
    }
}

