import AVFoundation

internal extension AVCaptureDevice {

    internal var supportedResolutions: [CMVideoDimensions] {
        var resolutions: [CMVideoDimensions] = []

        for format in formats {
            guard format.is420YpCbCr8BiPlanarVideo else {
                continue
            }

            let resolution = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            guard !resolutions.contains(where: {($0.width == resolution.width) && ($0.height == resolution.height)}) else {
                continue
            }

            resolutions.append(resolution)
        }

        return resolutions
    }

    internal func closestSupportedResolution(resolution: CMVideoDimensions) -> CMVideoDimensions? {
        let supportedResolutions = self.supportedResolutions
        var closestResolution: CMVideoDimensions?
        var minimalDifference = Int32.max

        for supportedResolution in supportedResolutions {
            if supportedResolution.width > resolution.width {
                continue
            }

            let difference = abs(resolution.width - supportedResolution.width)
            if difference < minimalDifference {
                minimalDifference = difference
                closestResolution = supportedResolution
            }
        }

        return closestResolution
    }

    internal func formatForResolution(resolution: CMVideoDimensions, andFrameRate frameRate: Double) -> AVCaptureDevice.Format? {
        for format in formats {
            guard format.is420YpCbCr8BiPlanarVideo else {
                continue
            }

            let formatResolution = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            guard (formatResolution.width == resolution.width) && (formatResolution.height == resolution.height) else {
                continue
            }

            for formatFrameRateRange in format.videoSupportedFrameRateRanges {
                var frameRateSupported = true
                frameRateSupported = frameRateSupported && (Float64(frameRate) <= formatFrameRateRange.maxFrameRate)
                frameRateSupported = frameRateSupported && (Float64(frameRate) >= formatFrameRateRange.minFrameRate)

                guard frameRateSupported else {
                    continue
                }

                return format
            }
        }

        return nil
    }

}
