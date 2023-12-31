//
//  CropPlate.swift
//  WalkerGuard2
//
//  Created by Henry on 2023/12/31.
//


import Foundation
import SwiftUI
import CoreGraphics
import Vision

class CropPlate{
    static func CropPlates(image:CGImage,observations:[ProcessedObservation],viewSize:CGSize) -> [UIImage]?{
        
        var croppedImages:[UIImage] = []
        print("observations.count = \(observations.count)")
        for observation in observations{
            let boundingBox = observation.boundingBox
            // 將觀測結果的邊界框轉換為圖像座標空間
            print(image)
            // 裁剪圖像
            if let croppedImage = cropImage(image: image, rect: boundingBox,viewSize: viewSize) {
                croppedImages.append(croppedImage)
            }
            
        }
        
        print("croppedImages.count = \(croppedImages.count)")
        return croppedImages
    }
    static private func cropImage(image: CGImage, rect: CGRect,viewSize:CGSize) -> UIImage? {
        // 裁剪圖像
        // scale rect multiplier image.size/previewSize
        let scale = CGFloat(image.width)/viewSize.height
        print("scale = \(scale)")
        let rect = CGRect(x: rect.minX*scale, y: rect.minY*scale, width: rect.width*scale, height: rect.height*scale)
        
        let transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2) // 逆時針旋轉90度
        let rotatedRect = rect.applying(transform).applying(CGAffineTransform(translationX: 0, y: CGFloat(image.height)))
        

        let croppedCGImage = image.cropping(to: rotatedRect)
        if croppedCGImage == nil {
            print("croppedCGImage == nil")
            return nil
        }
        // 將CGImage轉換為UIImage
        let croppedImage = UIImage(cgImage: croppedCGImage!)
        
        return croppedImage
    }
}


