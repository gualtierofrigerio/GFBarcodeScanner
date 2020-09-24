//
//  GFBarcodeScanner.swift
//  GFBarcodeScanner
//
//  Created by Gualtiero Frigerio on 01/09/2018.
//

import Foundation
import QuartzCore
import AVFoundation
import UIKit

protocol AVCaptureMetaAndVideoDelegate: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate {}

@available(iOS 10.0, *)
public class GFBarcodeScanner:NSObject {
    
    var options:GFBarcodeScannerOptions!
    var delegate:AVCaptureMetaAndVideoDelegate?
    var cameraView:UIView?
    var previewLayer:AVCaptureVideoPreviewLayer?
    var rectanglesLayer:CAShapeLayer?
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
    
    convenience init(cameraView:UIView, delegate:AVCaptureMetaAndVideoDelegate) {
        self.init(options:GFBarcodeScannerOptions(), cameraView:cameraView, delegate:delegate)
    }
    
    init(options:GFBarcodeScannerOptions, cameraView:UIView, delegate:AVCaptureMetaAndVideoDelegate) {
        self.options = options
        self.cameraView = cameraView
        self.delegate = delegate
        queue = DispatchQueue(label: "GFBarcodeScannerQueue")
    }
    
    func resizeCameraView() {
        guard let previewLayer = previewLayer else {return}
        previewLayer.frame = cameraView!.layer.bounds
        
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            previewLayer.connection?.videoOrientation = .portrait
            break
        case .portraitUpsideDown:
            previewLayer.connection?.videoOrientation = .portraitUpsideDown
            break
        case .landscapeLeft:
            previewLayer.connection?.videoOrientation = .landscapeLeft
            break
        case .landscapeRight:
            previewLayer.connection?.videoOrientation = .landscapeRight
            break
        default:
            break
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
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer!.frame = cameraView.layer.bounds
        previewLayer!.videoGravity = .resizeAspectFill
        cameraView.layer.addSublayer(previewLayer!)
        queue.async {
            session.startRunning()
        }
}
    
    public func stopScanning() {
        self.session?.stopRunning()
    }
    
    // MARK: - Private
    
    static func createError(withMessage:String, code:Int) -> NSError {
        let error = NSError(domain: "GFBarcodeScanner", code: code, userInfo: ["Message" : withMessage])
        return error
    }
    
    private func configureCaptureSession() -> AVCaptureSession? {
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
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(delegate, queue: queue)
            
            session.addOutput(videoOutput)
        }
        metadataOutput.metadataObjectTypes = objectTypes
        
        return session
    }
    
    private func getOrientedImage(_ image:CIImage, forOrientation orientation:UIInterfaceOrientation) -> CIImage {
        var cImage = image
        switch orientation {
        case .portrait:
            cImage = cImage.oriented(forExifOrientation: 6)
            break
        case .portraitUpsideDown:
            cImage = cImage.oriented(forExifOrientation: 8)
            break
        case .landscapeLeft:
            cImage = cImage.oriented(forExifOrientation: 3)
            break
        case .landscapeRight:
            cImage = cImage.oriented(forExifOrientation: 1)
            break
        default:
            break
        }
        return cImage
    }
    
    private func requestAccessCallback() {
        DispatchQueue.main.async {
            self.startScanning()
        }
    }
    
    // MARK: - Drawing rectangles
    
    private func configureRectanglesLayer() -> CAShapeLayer? {
        guard let previewLayer = previewLayer else {return nil}
        if let layer = rectanglesLayer {
            layer.removeFromSuperlayer()
        }
        rectanglesLayer = CAShapeLayer()
        rectanglesLayer!.frame = previewLayer.frame
        return rectanglesLayer!
    }
}

// MARK: - Called by AVCaptureMetaAndVideoDelegate

@available(iOS 10.0, *)
extension GFBarcodeScanner {
    public func getBarcodeStringFromCapturedObjects(metadataObjects:[AVMetadataObject]) -> [String] {
        var rectangles = [CGRect]()
        var codes:[String] = []
        for metadata in metadataObjects {
            if let object = metadata as? AVMetadataMachineReadableCodeObject,
                let stringValue = object.stringValue {
                codes.append(stringValue)
                if options.drawRectangles {
                    rectangles.append(object.bounds)
                }
            }
        }
        if options.drawRectangles, let previewLayer = previewLayer {
            if let layer = rectanglesLayer {
                layer.removeFromSuperlayer()
            }
            rectanglesLayer = GFGeometryUtility.getLayer(withRectangles: rectangles, frameSize: previewLayer.frame, strokeColor: UIColor.green.cgColor)
            DispatchQueue.main.async {
                self.previewLayer!.addSublayer(self.rectanglesLayer!)
                self.previewLayer?.setNeedsDisplay()
            }
        }
        return codes
    }
    
    public func getImageFromSampleBuffer(_ sampleBuffer:CMSampleBuffer, orientation:UIInterfaceOrientation) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return nil}
        var cImage = CIImage(cvImageBuffer: imageBuffer)
        cImage = getOrientedImage(cImage, forOrientation: orientation)
        return UIImage(ciImage: cImage)
    }
}
