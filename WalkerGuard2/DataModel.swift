import AVFoundation
import SwiftUI

final class DataModel: NSObject,ObservableObject {
    var camera = Camera()
    var detector = ObjectDetection()
    var labeler = Labeling()
    var observations : [ProcessedObservation] = []
    
    @Published var viewfinderImage: Image?
    @Published var thumbnailImage: Image?
    
    var isPhotosLoaded = false
    
    override init() {
        super.init()
        Task {
            await handleCameraPreviews()
        }
        
        Task {
            await handleCameraPhotos()
        }
    }
    
    func handleCameraPreviews() async {
        let imageStream = camera.previewStream
            .map { $0 }

        for await image in imageStream {
            

            Task { @MainActor in
                
                if !self.detector.ready {
                    self.viewfinderImage = image.image
                    return
                }
                let newObservations = self.detector.detectAndProcess(image: image)
                self.observations = newObservations
                
                self.camera.isPreviewPaused = false
                let labeledImage = self.labeler.labelImage(image: UIImage(ciImage: image), observations: self.observations)!
                self.viewfinderImage = Image(uiImage: labeledImage)
                self.camera.isPreviewPaused = false
                
            }
        }
    }
    
    func handleCameraPhotos() async {
        let unpackedPhotoStream = camera.photoStream
            .compactMap { self.unpackPhoto($0) }
        
        for await photoData in unpackedPhotoStream {
            Task { @MainActor in
                thumbnailImage = photoData.thumbnailImage
            }
            
            savePhoto(imageData: photoData.imageData)
        }
    }
    
    private func unpackPhoto(_ photo: AVCapturePhoto) -> PhotoData? {
        if !self.detector.ready { return nil}
        guard let imageData = photo.fileDataRepresentation() else { return nil }
        
        guard let detImage = CIImage(data: imageData,options: [.applyOrientationProperty:true]) else {return nil}
        
        self.observations = self.detector.detectAndProcess(image: detImage)
        
        let labeledImage = labeler.labelImage(image: UIImage(ciImage: detImage), observations: self.observations)!
        
        //let croppedImages = CropPlate.CropPlates(image: detImage, observations: self.observations)
        
        let thumbnailImage = Image(uiImage: labeledImage)
        return PhotoData(thumbnailImage: thumbnailImage, imageData: labeledImage)
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
