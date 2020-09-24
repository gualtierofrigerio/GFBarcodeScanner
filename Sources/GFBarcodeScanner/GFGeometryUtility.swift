//
//  GFGeometryUtility.swift
//  GFBarcodeScanner
//
//  Created by Gualtiero Frigerio on 05/03/2019.
//

import Foundation
import CoreGraphics
import UIKit

class GFGeometryUtility {
    
    public static func getLayer(withRectangles rectangles:[CGRect], frameSize:CGRect, strokeColor:CGColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.frame = frameSize
        
        var path = UIBezierPath()
        for rect in rectangles {
            let transformedRect = transformRect(rect, forFrame: frameSize)
            path = updatePath(path, withRect: transformedRect)
        }
        drawPath(path, onLayer: layer, strokeColor:strokeColor)
        
        return layer
    }
    
}

// MARK: - Private

extension GFGeometryUtility {
    static private func drawPath(_ path:UIBezierPath, onLayer layer:CAShapeLayer, strokeColor:CGColor) {
        path.close()
        layer.path = path.cgPath
        layer.strokeColor = strokeColor
        layer.fillColor = UIColor.clear.cgColor
    }
    
    // The CGRect coming from AV doesn't have the real size but is scaled between 0 and 1
    // so we need to convert it to real sizes based on the given frame
    // AV rect is landscape so if we're portrait we invert width and height
    static private func transformRect(_ bounds:CGRect,  forFrame frame:CGRect) -> CGRect {
        var returnFrame = CGRect(x: 0, y: 0, width:0, height: 0)
        var size = frame.size
        let orientation = UIApplication.shared.statusBarOrientation
        if  orientation == .portrait || orientation == .portraitUpsideDown {
            let tmp = size.width
            size.width = size.height
            size.height = tmp
        }
        returnFrame.origin.y = bounds.origin.x * size.width
        returnFrame.origin.x = bounds.origin.y * size.height
        returnFrame.size.width = bounds.size.width * size.width
        returnFrame.size.height = bounds.size.height * size.height
        return returnFrame
    }
    
    static private func updatePath(_ path:UIBezierPath?, withRect rect:CGRect) -> UIBezierPath {
        let updatedPath = path ?? UIBezierPath()
        updatedPath.move(to: rect.origin)
        updatedPath.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y))
        updatedPath.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height))
        updatedPath.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height))
        return updatedPath
    }
}
