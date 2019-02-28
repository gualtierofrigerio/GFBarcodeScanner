//
//  GFBarcodeScannerViewController.swift
//  GFBarcodeScanner
//
//  Created by Gualtiero Frigerio on 01/09/2018.
//

import AVFoundation
import Foundation
import UIKit

public struct GFBarcodeScannerOptions {
    var closeButtonText:String!
    var closeButtonTextColor:UIColor!
    var backgroundColor:UIColor!
    var toolbarHeight:CGFloat!
    var fullScreen:Bool!
    
    init() {
        self.init(fullScreen: false)
    }
    
    public init(fullScreen:Bool) {
        if fullScreen {
            closeButtonText = "Close"
            closeButtonTextColor = UIColor.black
            backgroundColor = UIColor.white
            toolbarHeight = 60
        }
        else {
            toolbarHeight = 0
            backgroundColor = UIColor.white
            closeButtonText = ""
            closeButtonTextColor = UIColor.white
        }
        self.fullScreen = fullScreen
    }
}

@available(iOS 10.0, *)
public class GFBarcodeScannerViewController : UIViewController {
    let defaultOptions = GFBarcodeScannerOptions()
    public var options:GFBarcodeScannerOptions?
    var scanner:GFBarcodeScanner?
    var completion:(([String], NSError?) -> Void)?
    var cameraView:UIView!
    var isFullScreen = false
    
    override public func viewDidAppear(_ animated: Bool) {
        if let completion = self.completion {
            self.startScanning(options: self.options, completion: completion)
        }
    }
    
    public override func viewWillLayoutSubviews() {
        self.cameraView?.frame = getCameraViewFrame()
        self.scanner?.resizeCameraView()
    }
    
    public func startScanning(options:GFBarcodeScannerOptions?, completion:@escaping(_ results:[String], _ error:NSError?) -> Void) {
        self.completion = completion
        self.options = options
        if cameraView == nil {
            configureView()
        }
        self.scanner = GFBarcodeScanner(cameraView: cameraView, delegate:self)
        scanner?.startScanning()
    }
    
    public func stopScanning() {
        self.scanner?.stopScanning()
    }
}

extension GFBarcodeScannerViewController {
    
    @objc private func closeButtonTap(_ sender:Any) {
        self.scanner?.stopScanning()
        self.completion?([], GFBarcodeScanner.createError(withMessage: "User closed the capture view", code: 0))
    }
    
    private func configureView() {
        var opt = self.defaultOptions
        if let options = self.options {
            opt = options
        }
        self.isFullScreen = opt.fullScreen
        
        var frame = self.view.frame
        
        if opt.toolbarHeight > 0 {
            frame.size.height = opt.toolbarHeight
            let toolbarView = UIView.init(frame: frame)
            toolbarView.backgroundColor = opt.backgroundColor
            
            let closeButton = UIButton.init(frame: toolbarView.frame)
            closeButton.addTarget(self, action: #selector(self.closeButtonTap(_:)), for: .touchUpInside)
            closeButton.setTitle(opt.closeButtonText, for: .normal)
            closeButton.setTitleColor(opt.closeButtonTextColor, for: .normal)
            
            toolbarView.addSubview(closeButton)
            self.view.addSubview(toolbarView)
        }
        
        let cameraViewFrame = getCameraViewFrame()
        cameraView = UIView.init(frame: cameraViewFrame)
        self.view.addSubview(cameraView)
    }
    
    private func getCameraViewFrame() -> CGRect {
        var frame = self.view.frame
        if isFullScreen == false {
            if let superView = self.view.superview {
                frame.origin = CGPoint(x: 0, y: 0)
                frame.size = superView.frame.size
            }
        }
        else if let opt = self.options {
            frame.origin.y = opt.toolbarHeight
            frame.size.height = frame.size.height - opt.toolbarHeight
        }
        return frame
    }
}

/* The original idea was to have this delegate on GFBarcodeScanner
 * and to call GFBarcodeScanner with a completion handler
 * but with Swift the delegate method was never called on that class
 * while it works on this one subclassing UIViewController
 * A similar implementation in Objective-C has a different behaviour
 * and calls the delegate even in GFBarcodeScanner class
 */

extension GFBarcodeScannerViewController:AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let codes = self.scanner?.getBarcodeStringFromCapturedObjects(metadataObjects: metadataObjects) {
            print(codes)
            self.completion?(codes, nil)
        }
    }
}
