//
//  ScanViewController.swift
//  GFBarcodeScanner_Example
//
//  Created by Gualtiero Frigerio on 28/02/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import GFBarcodeScanner

class ScanViewController: UIViewController {

    var isScanning = false
    var barcodeVC:GFBarcodeScannerViewController?
    var screenshotImageView:UIImageView?
    
    @IBOutlet var resultLabel:UILabel!
    @IBOutlet var scanView:UIView!
    @IBOutlet var scanButton:UIButton!
    
    @IBAction func closeButtonTap(_ sender:Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func scanInViewButtonTap(_ sender:Any) {
        if let imageView = screenshotImageView {
            imageView.removeFromSuperview()
        }
        if #available(iOS 10.0, *) {
            if isScanning {
                removeBarcodeVC()
                scanButton.setTitle("Scan", for: .normal)
                isScanning = false
            }
            else {
                barcodeVC = GFBarcodeScannerViewController()
                self.addChildViewController(barcodeVC!)
                scanView.addSubview(barcodeVC!.view)
                barcodeVC!.didMove(toParentViewController: self)
                barcodeVC!.startScanning(options:nil, completion: { (codes, error) in
                    if codes.count > 0 {
                        DispatchQueue.main.async {
                            self.resultLabel.text = codes[0]
                        }
                    }
                    else if let err = error {
                        print(err)
                    }
                })
                scanButton.setTitle("Stop", for: .normal)
                isScanning = true
            }
        } else {
            print("not supported")
        }
    }
    
    @IBAction func screenshotButtonTap(_ sender:Any) {
        guard let barcodeVC = barcodeVC else {return}
        barcodeVC.getImage(callback: { [unowned self](image) in
            DispatchQueue.main.async {
                self.removeBarcodeVC()
                guard let image = image else {return}
                var frame = self.scanView!.frame
                frame.origin = CGPoint(x:0, y:0)
                self.screenshotImageView = UIImageView(frame: frame)
                self.screenshotImageView!.image = image
                self.screenshotImageView!.contentMode = UIViewContentMode.scaleAspectFit
                self.scanView.addSubview(self.screenshotImageView!)
            }
        })
    }
    
    func removeBarcodeVC() {
        guard let barcodeVC = barcodeVC else {return}
        barcodeVC.stopScanning()
        barcodeVC.willMove(toParentViewController: nil)
        barcodeVC.removeFromParentViewController()
        barcodeVC.view.removeFromSuperview()
        isScanning = false
        scanButton.setTitle("Scan", for: .normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
