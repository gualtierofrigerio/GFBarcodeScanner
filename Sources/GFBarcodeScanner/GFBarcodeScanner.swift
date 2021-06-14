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

/// Conveniente protocol combining AVCaptureVideoDataOutputSampleBufferDelegate and AVCaptureMetadataOutputObjectsDelegate
protocol AVCaptureMetaAndVideoDelegate: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate {}

@available(iOS 10.0, *)
/// A class used to perform barcode scanning
/// the scanning is performed via AVCaptureDevice
public class GFBarcodeScanner:NSObject {
    /// ``GFBarcodeScannerOptions`` containing options for the scanner
    var options:GFBarcodeScannerOptions!
    /// The optional delegate of AVCapture
    var delegate:AVCaptureMetaAndVideoDelegate?
    /// View containing the camera feed
    var cameraView:UIView?
    /// Layer to show the camera preview
    var previewLayer:AVCaptureVideoPreviewLayer?
    /// Layer containing rectangles with the recognized objects
    var rectanglesLayer:CAShapeLayer?
    /// DispatchQueue used to perform recognition
    var queue:DispatchQueue!
    /// Array of AVMetadataObject we want to recognize
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
    /// The AVCaptureSession used to perform live scanning
    var session:AVCaptureSession?
    
    /// Convenience init with a camera view and the AV delegate
    /// - Parameters:
    ///   - cameraView: UIView where the preview will be displayed
    ///   - delegate: The AVCapture delegate
    convenience init(cameraView:UIView, delegate:AVCaptureMetaAndVideoDelegate) {
        self.init(options:GFBarcodeScannerOptions(), cameraView:cameraView, delegate:delegate)
    }
    
    /// Initialise the scanner with options, a camera view and a delegate
    /// - Parameters:
    ///   - options: ``GFBarcodeScannerOptions`` containing options for the scanner
    ///   - cameraView: UIView where the preview will be displayed
    ///   - delegate: The AVCapture delegate
    init(options:GFBarcodeScannerOptions, cameraView:UIView, delegate:AVCaptureMetaAndVideoDelegate) {
        self.options = options
        self.cameraView = cameraView
        self.delegate = delegate
        queue = DispatchQueue(label: "GFBarcodeScannerQueue")
    }
    
    /// Resizes the previewLayer view and updates the videoOrientation
    /// based on the current orientation of the device
    func resizeCameraView() {
        guard let previewLayer = previewLayer,
              let cameraView = cameraView else {return}
        previewLayer.frame = cameraView.layer.bounds
        
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
    
    /// Begins a scanning session
    /// And asks for the camera permission if it wasn't already granted
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
        self.previewLayer = previewLayer
        queue.async {
            session.startRunning()
        }
}
    
    /// Ends the scanning session
    public func stopScanning() {
        self.session?.stopRunning()
    }
    
    // MARK: - Private
    
    /// Creates an NSError with a string and a code
    /// - Parameters:
    ///   - withMessage: the String with the error message
    ///   - code: the error code
    /// - Returns: An NSError
    static func createError(withMessage:String, code:Int) -> NSError {
        let error = NSError(domain: "GFBarcodeScanner", code: code, userInfo: ["Message" : withMessage])
        return error
    }
    
    /// Configures an AVCaptureSession
    /// setting its delegate and the objectTypes
    /// - Returns: an optional AVCaptureSession
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
    
    /// Returnes a CIImage rotated based on the given orientation
    /// - Parameters:
    ///   - image: The image to rotate
    ///   - orientation: The desired orientation
    /// - Returns: The rotated image
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
    
    /// Callback for AVCaptureDevice.requestAccess
    private func requestAccessCallback() {
        DispatchQueue.main.async {
            self.startScanning()
        }
    }
    
    // MARK: - Drawing rectangles
    
    /// Configure a CAShapeLayer with the same size as the previewLayer
    /// - Returns: A CAShapeLayer
    private func configureRectanglesLayer() -> CAShapeLayer? {
        guard let previewLayer = previewLayer else {return nil}
        if let layer = rectanglesLayer {
            layer.removeFromSuperlayer()
        }
        let rectanglesLayer = CAShapeLayer()
        rectanglesLayer.frame = previewLayer.frame
        self.rectanglesLayer = rectanglesLayer
        return rectanglesLayer
    }
}

// MARK: - Called by AVCaptureMetaAndVideoDelegate

@available(iOS 10.0, *)
extension GFBarcodeScanner {
    /// Returns an array of barcoded from an array of AVMetadataObject
    /// - Parameter metadataObjects: The array of AVMetadataObject containing the codes
    /// - Returns: A String array of barcodes
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
                if let previewLayer = self.previewLayer,
                   let rectanglesLayer = self.rectanglesLayer {
                    previewLayer.addSublayer(rectanglesLayer)
                    previewLayer.setNeedsDisplay()
                }
            }
        }
        return codes
    }
    
    /// Tries to get a UIImage from a CMSampleBuffer with an orientation
    /// - Parameters:
    ///   - sampleBuffer: The CMSampleBuffer containing the image
    ///   - orientation: The desired orientation
    /// - Returns: An optional UIImage
    public func getImageFromSampleBuffer(_ sampleBuffer:CMSampleBuffer, orientation:UIInterfaceOrientation) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return nil}
        var cImage = CIImage(cvImageBuffer: imageBuffer)
        cImage = getOrientedImage(cImage, forOrientation: orientation)
        return UIImage(ciImage: cImage)
    }
}
