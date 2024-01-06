import AVFoundation
import SwiftUI

final class DataModel: NSObject,ObservableObject {
    var camera = Camera()
    var detector = ObjectDetection()
    private var service = Service()
    var labeler = Labeling()
    var observations : [ProcessedObservation] = []
    var cropImages: [UIImage] = []
    @Published var viewfinderImage: Image?
    @Published var thumbnailImage: Image?
    
    var isPhotosLoaded = false
    var done = true
    override init() {
        super.init()
        
        Task {
            await handleCameraPreviews()
        }
    }
    
    func handleCameraPreviews() async {
        let imageStream = camera.previewStream
            .map { $0 }
        
        for await image in imageStream {
            
            Task { @MainActor in
                if !self.detector.ready {
                    return
                }
                self.camera.isPreviewPaused = true
                self.observations = self.detector.detectAndProcess(image: image)
                self.camera.isPreviewPaused = false
            }
            
            Task { @MainActor in
                if done{
                    done = false
                    let uiImage = UIImage(ciImage: image)
                    // time sleep 1s
                    
                    let labeledImage = self.labeler.labelImage(image: uiImage, observations: self.observations)!
                    self.viewfinderImage = Image(uiImage: labeledImage)
                    done = true
                }
            }
            Task {
                let uiImage = UIImage(ciImage: image)
                var positions = [[Int]]()
                (self.cropImages,positions) = CropPlate.CropPlates(image: uiImage, observations: self.observations)
                if self.cropImages.count > 0{
                    service.addPlates(images: self.cropImages, positions: positions)
                }
            }
        }
    }
    
    
    
    func savePhoto(imageData: UIImage) {
        Task {
            /// Save `image` into Photo Library
            UIImageWriteToSavedPhotosAlbum(imageData, self,
                                           #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            
        }
    }
    
    
    /// Process photo saving result
    @objc func image(_ image: UIImage,
                     didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("ERROR: \(error)")
            
        }
    }
    
}

fileprivate struct PhotoData {
    var thumbnailImage: Image
    var imageData: UIImage
}

fileprivate extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}

fileprivate extension Image.Orientation {
    
    init(_ cgImageOrientation: CGImagePropertyOrientation) {
        switch cgImageOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}
