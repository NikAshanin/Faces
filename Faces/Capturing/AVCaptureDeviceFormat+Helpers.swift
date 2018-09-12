import AVFoundation

internal extension AVCaptureDevice.Format {

    internal var is420YpCbCr8BiPlanarVideo: Bool {
        let mediaType = CMFormatDescriptionGetMediaType(formatDescription)
        guard mediaType == kCMMediaType_Video else {
            return false
        }

        let mediaSubType = CMFormatDescriptionGetMediaSubType(formatDescription)
        guard mediaSubType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange else {
            return false
        }

        return true
    }

}
