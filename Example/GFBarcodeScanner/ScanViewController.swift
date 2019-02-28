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

    @IBOutlet var resultLabel:UILabel!
    @IBOutlet var scanView:UIView!
    
    @IBAction func closeButtonTap(_ sender:Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func scanInViewButtonTap(_ sender:Any) {
        if #available(iOS 10.0, *) {
            let barcodeVC = GFBarcodeScannerViewController()
            self.addChildViewController(barcodeVC)
            scanView.addSubview(barcodeVC.view)
            barcodeVC.didMove(toParentViewController: self)
            barcodeVC.startScanning(options:nil, completion: { (codes, error) in
                if codes.count > 0 {
                    DispatchQueue.main.async {
                        self.resultLabel.text = codes[0]
//                        barcodeVC.stopScanning()
//                        barcodeVC.willMove(toParentViewController: nil)
//                        barcodeVC.removeFromParentViewController()
//                        barcodeVC.view.removeFromSuperview()
                    }
                }
                else if let err = error {
                    print(err)
                }
            })
        } else {
            print("not supported")
        }
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
