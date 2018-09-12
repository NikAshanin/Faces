import AVFoundation

internal class CaptureSessionConfiguration {

    internal let position: AVCaptureDevice.Position
    internal let resolution: CMVideoDimensions
    internal let frameRate: Double
    internal let videoOrientation: AVCaptureVideoOrientation

    internal init(position: AVCaptureDevice.Position,
                  resolution: CMVideoDimensions,
                  frameRate: Double,
                  videoOrientation: AVCaptureVideoOrientation) {
        self.position = position
        self.resolution = resolution
        self.frameRate = frameRate
        self.videoOrientation = videoOrientation
    }

}
