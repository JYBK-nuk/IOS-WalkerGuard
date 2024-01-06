import Foundation
import SwiftUI
import CoreGraphics
import Vision
class CropPlate {
    static func CropPlates(image: UIImage, observations: [ProcessedObservation]) -> [UIImage] {
        UIGraphicsBeginImageContext(image.size)
        image.draw(at: CGPoint.zero)
        let context = UIGraphicsGetCurrentContext()!
        
        var croppedImages: [UIImage] = []
        
        for observation in observations {
            // 在這裡執行對每個observation的圖像裁剪操作
            
            // cropImage是裁剪後的圖像
            if let cropImage = cropImage(image: image, observation: observation) {
                croppedImages.append(cropImage)
            }
        }
        
        UIGraphicsEndImageContext()
        
        print("croppedImages.count = \(croppedImages.count)")
        
        // 假設你想要回傳第一張裁剪後的圖像
        return croppedImages
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
        print("imageSize = \(imageSize)")
        print("boundingBox = \(boundingBox)")
        print(image)
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
