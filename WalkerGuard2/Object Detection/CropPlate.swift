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
    static func CropPlates(image:CIImage,observations:[ProcessedObservation]) -> [UIImage]?{
        var croppedImages:[UIImage] = []
        
        print("observations.count = \(observations.count)")
        for observation in observations{
            let boundingBox = observation.boundingBox
            // 將觀測結果的邊界框轉換為圖像座標空間
            _ = CGRect(x: 0, y: 0, width: image.extent.width, height: image.extent.height)
            let boundingBoxInImageSpace = VNImageRectForNormalizedRect(boundingBox, Int(image.extent.width), Int(image.extent.height))
            print(image)
            // 裁剪圖像
            if let croppedImage = cropImage(image: image, rect: boundingBoxInImageSpace) {
                croppedImages.append(croppedImage)
            }
            
        }
        print("croppedImages.count = \(croppedImages.count)")
        return croppedImages
    }
    static private func cropImage(image: CIImage, rect: CGRect) -> UIImage? {
        // 將CIImage轉換為CGImage
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            return nil
        }
        
        // 裁剪圖像
        let croppedCGImage = cgImage.cropping(to: rect)
        
        // 將CGImage轉換為UIImage
        let croppedImage = UIImage(cgImage: croppedCGImage!)
        
        return croppedImage
    }
}


