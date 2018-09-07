//
//  GFBarcodeScanner.swift
//  GFBarcodeScanner
//
//  Created by Gualtiero Frigerio on 01/09/2018.
//

import Foundation
import QuartzCore
import AVFoundation

@available(iOS 10.0, *)
public class GFBarcodeScanner:NSObject {
    
    var options:GFBarcodeScannerOptions!
    var delegate:AVCaptureMetadataOutputObjectsDelegate?
    var cameraView:UIView?
    var previewLayer:AVCaptureVideoPreviewLayer?
    var queue:DispatchQueue!
    let objectTypes:[AVMetadataObject.ObjectType] = [AVMetadataObject.ObjectType.aztec,
                                                     AVMetadataObject.ObjectType.code39,
                                                     AVMetadataObject.ObjectType.code39Mod43,
                                                     AVMetadataObject.ObjectType.code93,
                                                     AVMetadataObject.ObjectType.code128,
                                                     AVMetadataObject.ObjectType.dataMatrix,
                                                     AVMetadataObject.ObjectType.ean8,
                                                     AVMetadataObject.ObjectType.ean13,
                                                     AVMetadataObject.ObjectType.interleaved2of5,
                                                     AVMetadataObject.ObjectType.itf14,
                                                     AVMetadataObject.ObjectType.pdf417,
                                                     AVMetadataObject.ObjectType.qr,
                                                     AVMetadataObject.ObjectType.upce
                                                     ]
    var session:AVCaptureSession?
    
    convenience init(cameraView:UIView, delegate:AVCaptureMetadataOutputObjectsDelegate) {
        self.init(options:GFBarcodeScannerOptions(), cameraView:cameraView, delegate:delegate)
    }
    
    init(options:GFBarcodeScannerOptions, cameraView:UIView, delegate:AVCaptureMetadataOutputObjectsDelegate) {
        self.options = options
        self.cameraView = cameraView
        self.delegate = delegate
        queue = DispatchQueue(label: "GFBarcodeScannerQueue")
    }
    
    static func createError(withMessage:String, code:Int) -> NSError {
        let error = NSError(domain: "GFBarcodeScanner", code: code, userInfo: ["Message" : withMessage])
        return error
    }
    
    func configureCaptureSession() -> AVCaptureSession? {
        let session = AVCaptureSession()
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes:[.builtInWideAngleCamera, .builtInTelephotoCamera],
            mediaType: AVMediaType.video,
            position: .unspecified)
        
        guard let captureDevice = deviceDiscoverySession.devices.first,
            let videoDeviceInput = try? AVCaptureDeviceInput(device: captureDevice),
            session.canAddInput(videoDeviceInput)
            else { return nil }
        session.addInput(videoDeviceInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        session.addOutput(metadataOutput)
        if let delegate = self.delegate {
            metadataOutput.setMetadataObjectsDelegate(delegate, queue: queue)
        }
        metadataOutput.metadataObjectTypes = objectTypes
        
        return session
    }
    
    func requestAccessCallback() {
        DispatchQueue.main.async {
            self.startScanning()
        }
    }
    
    public func startScanning() {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authorizationStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video,
                                          completionHandler: { (granted:Bool) -> Void in
                                          self.requestAccessCallback();
            })
            return
        }
        else if authorizationStatus == .restricted || authorizationStatus == .denied {
            print("You don't have permission to access the camera")
            return
        }
        guard let cameraView = self.cameraView,
              let _ = cameraView.superview else {
                print("You need to set camera view")
            return
        }
        guard let session = configureCaptureSession() else {
            print("Cannot configure capture session")
            return
        }
        self.session = session
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = cameraView.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        cameraView.layer.addSublayer(previewLayer)
        queue.async {
            session.startRunning()
        }
    }
    
    public func stopScanning() {
        self.session?.stopRunning()
    }
    
    public func getBarcodeStringFromCapturedObjects(metadataObjects:[AVMetadataObject]) -> [String] {
        var codes:[String] = []
        for metadata in metadataObjects {
            if let object = metadata as? AVMetadataMachineReadableCodeObject,
               let stringValue = object.stringValue {
                codes.append(stringValue)
            }
        }
        return codes
    }
}
