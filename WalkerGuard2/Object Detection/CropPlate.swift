import Foundation
import SwiftUI
import CoreGraphics
import Vision
class CropPlate {
    static func CropPlates(image: UIImage, observations: [ProcessedObservation]) -> ([UIImage],[[Int]]) {
        UIGraphicsBeginImageContext(image.size)
        image.draw(at: CGPoint.zero)
        _ = UIGraphicsGetCurrentContext()!
        
        var croppedImages: [UIImage] = []
        var positions : [[Int]] = []
        for observation in observations {
            // if observation is plate
            if observation.label == "Plate" {
                // cropImage是裁剪後的圖像
                if let cropImage = cropImage(image: image, observation: observation) {
                    croppedImages.append(cropImage)
                    positions.append([
                        Int(observation.boundingBox.midX),
                        Int(observation.boundingBox.maxY)
                    ])
                }
            }
            
        }
        
        UIGraphicsEndImageContext()
        
        //        print("croppedImages.count = \(croppedImages.count)")
        
        // 假設你想要回傳第一張裁剪後的圖像
        return (croppedImages,positions)
    }
    static func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
            return cgImage
        }
        return nil
    }
    static func cropImage(image: UIImage, observation: ProcessedObservation) -> UIImage? {
        // 確保觀察結果有有效的邊界框
        if observation.boundingBox.isEmpty {
            return nil
        }
        let boundingBox = observation.boundingBox
        // 將bounding box轉換為圖像座標
        let imageSize = image.size
        let cgiImage = convertCIImageToCGImage(inputImage: image.ciImage!)
        // 從原始圖像中裁剪出指定的區域
        guard let imageRef = cgiImage?.cropping(to: boundingBox) else {
            return nil
        }
        
        // 將裁剪後的圖像轉換為UIImage並回傳
        let croppedImage = UIImage(cgImage: imageRef)
        return croppedImage
    }
}
