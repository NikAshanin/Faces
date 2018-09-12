import UIKit

internal class FaceDetector {

    private let ciContext: CIContext
    private let faceDetector: CIDetector?

    internal init() {
        let ciContextOptions = [kCIContextWorkingColorSpace: NSNull(),
                                kCIContextOutputColorSpace: NSNull(),
                                kCIContextUseSoftwareRenderer: NSNumber(value: false)]
        ciContext = CIContext(options: ciContextOptions)

        let faceDetectorOptions: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: ciContext, options: faceDetectorOptions)
    }

    deinit {
        //Nothing
    }

    internal func process(pixelBuffer: CVPixelBuffer) -> [CGRect] {
        guard let faceDetector = self.faceDetector else {
            return []
        }

        let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let pixelBufferImage = CIImage(cvPixelBuffer: pixelBuffer)
        let features = faceDetector.features(in: pixelBufferImage)

        var faceRectangles = [CGRect]()
        for feature in features {
            var faceRectangle = feature.bounds
            faceRectangle.origin.y = pixelBufferHeight - faceRectangle.origin.y - faceRectangle.size.height
            faceRectangles.append(faceRectangle)
        }

        return faceRectangles
    }

}
