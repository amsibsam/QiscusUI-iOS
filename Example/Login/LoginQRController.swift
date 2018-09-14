//
//  LoginQRController.swift
//  qiscus-sdk-ios-sample-v2
//
//  Created by UziApel on 17/07/18.
//  Copyright © 2018 Qiscus Technology. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftyJSON
import QiscusCore

class LoginQRController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    
    // show alert message while cannot connect with qiscus sdk
    var withMessage: String? {
        didSet {
            guard let message = withMessage else { return }
            if !(message.isEmpty) {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                    //self.showError(message: message)
                    
                })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
         self.navigationController?.isNavigationBarHidden = false
        self.title = "Scan Your QR Code Here"
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
    
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        
        
        captureSession.startRunning()
    }
    
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
        
        dismiss(animated: true)
    }
    
    func found(code: String) {
        let payload = JSON.init(parseJSON: code)
        let appId = payload["app_id"].stringValue
        let identityToken = payload["identity_token"].stringValue
        QiscusCore.setup(WithAppID: appId)
        let local = UserDefaults.standard
        local.set(appId, forKey: "AppID")
        QiscusCore.login(withIdentityToken: identityToken) { (user, error) in
            if user != nil {
                self.navigationController?.pushViewController(ListChatViewController(), animated: true)
            }else {
                print("error \(String(describing: error))")
                let alert = UIAlertController(title: "Failed to Login?", message: String(describing: error?.message), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Try Again", style: .cancel, handler: nil))
                
                self.present(alert, animated: true)
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
