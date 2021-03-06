//
//  ViewController.swift
//  GFBarcodeScanner
//
//  Created by gualtierofrigerio on 09/01/2018.
//  Copyright (c) 2018 gualtierofrigerio. All rights reserved.
//

import UIKit
import GFBarcodeScanner

class ViewController: UIViewController {

    @IBOutlet var resultLabel:UILabel!
    @IBOutlet var scanView:UIView!

    @IBAction func scanButtonTap(_ sender:Any) {
        if #available(iOS 10.0, *) {
            let barcodeVC = GFBarcodeScannerViewController()
            barcodeVC.modalPresentationStyle = .currentContext
            let options = GFBarcodeScannerOptions(fullScreen:true)
            self.present(barcodeVC, animated: true) {
                barcodeVC.startScanning(options:options, completion: { (codes, error) in
                    if codes.count > 0 {
                        DispatchQueue.main.async {
                            self.resultLabel.text = codes[0]
                            barcodeVC.stopScanning()
                            barcodeVC.dismiss(animated: true, completion: nil)
                        }
                    }
                    else if let err = error {
                        print(err)
                    }
                })
            }
        } else {
            print("not supported")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

