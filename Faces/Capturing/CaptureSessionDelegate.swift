import AVFoundation

internal protocol CaptureSessionDelegate: NSObjectProtocol {

    func captureSession(_ captureSession: CaptureSession,
                        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
                        withOrientation captureVideoOrientation: AVCaptureVideoOrientation)
    func captureSession(_ captureSession: CaptureSession, stateChanged state: CaptureSessionState)
    func captureSessionConfigurationFailed(_ captureSession: CaptureSession)
    func captureSessionRuntimeError(_ captureSession: CaptureSession)
    func captureSession(_ captureSession: CaptureSession, interruptionChanged interrupted: Bool)

}
