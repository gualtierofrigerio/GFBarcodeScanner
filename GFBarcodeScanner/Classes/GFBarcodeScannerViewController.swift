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
    let closeButtonText:String
    let closeButtonTextColor:UIColor
    let backgroundColor:UIColor
    let toolbarHeight:CGFloat
    
    init() {
        closeButtonText = "Close"
        closeButtonTextColor = UIColor.black
        backgroundColor = UIColor.white
        toolbarHeight = 40
    }
}

@available(iOS 10.0, *)
public class GFBarcodeScannerViewController : UIViewController {
    let defaultOptions = GFBarcodeScannerOptions()
    public var options:GFBarcodeScannerOptions?
    var scanner:GFBarcodeScanner?
    var completion:(([String], NSError?) -> Void)?
    var cameraView:UIView!
    
    override public func viewDidLoad() {
        print("view did load")

        print("finito view did load")
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        print("view did appear")
        if let completion = self.completion {
            self.startScanning(options: self.options, completion: completion)
        }
    }
    
    func configureView() {
        var opt = self.defaultOptions
        if let options = self.options {
            opt = options
        }
        // setup the toolbar with close button
        var frame = self.view.frame
        frame.size.height = opt.toolbarHeight
        let toolbarView = UIView.init(frame: frame)
        toolbarView.backgroundColor = opt.backgroundColor
        
        let closeButton = UIButton.init(frame: toolbarView.frame)
        closeButton.addTarget(self, action: #selector(self.closeButtonTap(_:)), for: .touchUpInside)
        closeButton.setTitle(opt.closeButtonText, for: .normal)
        closeButton.setTitleColor(opt.closeButtonTextColor, for: .normal)
        
        toolbarView.addSubview(closeButton)
        self.view.addSubview(toolbarView)
        
        frame = self.view.frame
        frame.origin.y = opt.toolbarHeight
        frame.size.height = frame.size.height - opt.toolbarHeight
        cameraView = UIView.init(frame: frame)
        self.view.addSubview(cameraView)
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
    
    @objc func closeButtonTap(_ sender:Any) {
        //self.dismiss(animated: true, completion: nil)
        self.scanner?.stopScanning()
        self.completion?([], GFBarcodeScanner.createError(withMessage: "User closed the capture view", code: 0))
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
