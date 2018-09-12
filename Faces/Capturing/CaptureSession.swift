import AVFoundation

internal class CaptureSession: NSObject {

    internal fileprivate(set) var state: CaptureSessionState = .stopped
    internal fileprivate(set) var previewLayer: AVCaptureVideoPreviewLayer?
    internal fileprivate(set) var metadataFaceObjects: [AVMetadataFaceObject] = []

    internal weak var delegate: CaptureSessionDelegate?
    internal var configuration: CaptureSessionConfiguration? {
        didSet {
            guard let configuration = configuration else {
                stop()
                return
            }
            let configured = reconfigure(configuration: configuration)
            if !configured {
                notifyDelegateConfigurationFailed()
            }
        }
    }

    fileprivate let capturingQueue: DispatchQueue
    fileprivate let metadataQueue: DispatchQueue
    fileprivate var captureSession: AVCaptureSession?
    fileprivate var captureDevice: AVCaptureDevice?
    fileprivate var captureDeviceInput: AVCaptureDeviceInput?
    fileprivate var captureVideoDataOutput: AVCaptureVideoDataOutput?
    fileprivate var captureMetadataOutput: AVCaptureMetadataOutput?

    fileprivate let outputLock = NSLock()
    fileprivate var outputEnabled = true

    internal init(capturingQueue: DispatchQueue,
                  metadataQueue: DispatchQueue) {
        self.capturingQueue = capturingQueue
        self.metadataQueue = metadataQueue
        super.init()
    }

    deinit {
        //Nothing
    }

    internal static var hasPermissions: Bool {
        let audioAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        let videoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        return (audioAuthorizationStatus == .authorized) && (videoAuthorizationStatus == .authorized)
    }

    internal func start() {
        guard self.captureSession == nil else {
            return
        }

        guard let configuration = self.configuration else {
            return
        }

        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.inputPriority
        self.captureSession = captureSession
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        registerForCaptureSessionNotification()

        let configured = reconfigure(configuration: configuration)
        if configured {
            captureSession.startRunning()
        } else {
            stop()
            notifyDelegateConfigurationFailed()
        }
    }

    internal func stop() {
        captureVideoDataOutput?.setSampleBufferDelegate(nil, queue: nil)

        if captureSession?.isRunning ?? false {
            captureSession?.stopRunning()
        }

        unregisterForCaptureSessionNotification()

        captureDeviceInput = nil
        captureVideoDataOutput = nil
        captureDevice = nil
        captureSession = nil
    }

}

// MARK: - Configuration
extension CaptureSession {

    fileprivate func reconfigure(configuration: CaptureSessionConfiguration) -> Bool {
        guard let captureSession = self.captureSession else {
            return true
        }

        guard let captureDevice = retreiveCaptureDevice(captureSession: captureSession, configuration: configuration) else {
            return false
        }

        var result = true
        captureSession.beginConfiguration()
        do {
            self.captureDevice = captureDevice
            try configureVideoInput(captureSession: captureSession, captureDevice: captureDevice)
            try configureVideoOutput(captureSession: captureSession,
                                     captureDevice: captureDevice,
                                     captureVideoOrientation: configuration.videoOrientation)
            try configureMetadataOutput(captureSession: captureSession)
        } catch {
            result = false
        }
        captureSession.commitConfiguration()

        return result
    }

    private func retreiveCaptureDevice(captureSession: AVCaptureSession,
                                       configuration: CaptureSessionConfiguration) -> AVCaptureDevice? {
        let captureDevices = AVCaptureDevice.devices(for: AVMediaType.video)

        let position: AVCaptureDevice.Position = (configuration.position == .back) ? .back : .front
        var selectedCaptureDevice: AVCaptureDevice?
        selectedCaptureDevice = captureDevices
            .filter { $0.position == position }.first

        if selectedCaptureDevice == nil {
            selectedCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        }

        guard let captureDevice = selectedCaptureDevice else {
            return nil
        }

        guard let closestResolution = captureDevice.closestSupportedResolution(resolution: configuration.resolution) else {
            return nil
        }

        guard let captureDeviceFormat = captureDevice.formatForResolution(resolution: closestResolution,
                                                                          andFrameRate: configuration.frameRate) else {
            return nil
        }

        do {
            try captureDevice.lockForConfiguration()
        } catch {
            return nil
        }

        captureDevice.activeFormat = captureDeviceFormat
        captureDevice.activeVideoMinFrameDuration = CMTimeMake(1, Int32(configuration.frameRate))
        captureDevice.activeVideoMaxFrameDuration = CMTimeMake(1, Int32(configuration.frameRate))
        configureDefaultFocus(captureDevice: captureDevice)
        captureDevice.unlockForConfiguration()
        return captureDevice
    }

    fileprivate func configureVideoInput(captureSession: AVCaptureSession, captureDevice: AVCaptureDevice) throws {
        if let captureDeviceInput = self.captureDeviceInput {
            captureSession.removeInput(captureDeviceInput)
            self.captureDeviceInput = nil
        }

        let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
        guard captureSession.canAddInput(captureDeviceInput) else {
            throw CaptureSessionError.videoInputConfiguration
        }
        captureSession.addInput(captureDeviceInput)

        self.captureDeviceInput = captureDeviceInput
    }

    fileprivate func configureVideoOutput(captureSession: AVCaptureSession,
                                          captureDevice: AVCaptureDevice,
                                          captureVideoOrientation: AVCaptureVideoOrientation) throws {
        if self.captureVideoDataOutput != nil {
            guard let captureVideoDataOutput = self.captureVideoDataOutput else {
                return
            }
            try configureCaptureConnection(captureVideoDataOutput: captureVideoDataOutput,
                                           captureVideoOrientation: captureVideoOrientation)
            return
        }

        let captureVideoDataOutput = AVCaptureVideoDataOutput()
        captureVideoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString):
            NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        captureVideoDataOutput.alwaysDiscardsLateVideoFrames = true
        captureVideoDataOutput.setSampleBufferDelegate(self, queue: capturingQueue)

        guard captureSession.canAddOutput(captureVideoDataOutput) else {
            throw CaptureSessionError.videoOutputConfiguration
        }
        captureSession.addOutput(captureVideoDataOutput)

        try configureCaptureConnection(captureVideoDataOutput: captureVideoDataOutput,
                                       captureVideoOrientation: captureVideoOrientation)
        self.captureVideoDataOutput = captureVideoDataOutput
    }

    fileprivate func configureMetadataOutput(captureSession: AVCaptureSession) throws {
        if self.captureMetadataOutput != nil {
            return
        }

        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: metadataQueue)
        guard captureSession.canAddOutput(captureMetadataOutput) else {
            throw CaptureSessionError.videoOutputConfiguration
        }
        captureSession.addOutput(captureMetadataOutput)
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.face]

        self.captureMetadataOutput = captureMetadataOutput
    }

    fileprivate func configureCaptureConnection(captureVideoDataOutput: AVCaptureVideoDataOutput,
                                                captureVideoOrientation: AVCaptureVideoOrientation) throws {
        guard let captureConnection = captureVideoDataOutput.connection(with: AVMediaType.video) else {
            throw CaptureSessionError.videoOutputConfiguration
        }

        guard captureConnection.isVideoOrientationSupported else {
            throw CaptureSessionError.videoOutputConfiguration
        }

        captureConnection.videoOrientation = captureVideoOrientation
        captureConnection.preferredVideoStabilizationMode = .standard
    }

}

// MARK: - Focus
extension CaptureSession {

    fileprivate func configureDefaultFocus(captureDevice: AVCaptureDevice) {
        guard captureDevice.isFocusModeSupported(.continuousAutoFocus) else {
            return
        }

        if captureDevice.isFocusPointOfInterestSupported {
            captureDevice.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
        }

        captureDevice.focusMode = .continuousAutoFocus
    }

}

// MARK: - Notifications
extension CaptureSession {

    fileprivate func registerForCaptureSessionNotification() {
        registerForNotification(notificationName: .AVCaptureSessionDidStartRunning,
                                selector: #selector(captureSessionDidStartRunning(notification:)))
        registerForNotification(notificationName: .AVCaptureSessionDidStopRunning,
                                selector: #selector(captureSessionDidStopRunning(notification:)))
        registerForNotification(notificationName: .AVCaptureSessionRuntimeError,
                                selector: #selector(captureSessionRuntimeError(notification:)))
        registerForNotification(notificationName: .AVCaptureSessionWasInterrupted,
                                selector: #selector(captureSessionWasInterrupted(notification:)))
        registerForNotification(notificationName: .AVCaptureSessionInterruptionEnded,
                                selector: #selector(captureSessionInterruptionEnded(notification:)))
        registerForNotification(notificationName: .UIApplicationWillResignActive,
                                selector: #selector(applicationWillResignActive(notification:)))
        registerForNotification(notificationName: .UIApplicationDidBecomeActive,
                                selector: #selector(applicationDidBecomeActive(notification:)))
    }

    fileprivate func unregisterForCaptureSessionNotification() {
        let notificationNames: [NSNotification.Name] = [.AVCaptureSessionDidStartRunning,
                                                        .AVCaptureSessionDidStopRunning,
                                                        .AVCaptureSessionRuntimeError,
                                                        .AVCaptureSessionWasInterrupted,
                                                        .AVCaptureSessionInterruptionEnded,
                                                        .UIApplicationWillResignActive,
                                                        .UIApplicationDidBecomeActive]
        for notificationName in notificationNames {
            unregisterForNotification(notificationName: notificationName)
        }
    }

    private func registerForNotification(notificationName: NSNotification.Name, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: notificationName, object: nil)
    }

    private func unregisterForNotification(notificationName: NSNotification.Name) {
        NotificationCenter.default.removeObserver(self, name: notificationName, object: nil)
    }

    @objc private func captureSessionDidStartRunning(notification: Notification) {
        changeState(state: .started)
    }

    @objc private func captureSessionDidStopRunning(notification: Notification) {
        changeState(state: .stopped)
    }

    @objc private func captureSessionRuntimeError(notification: Notification) {
        notifyDelegateRuntimeError()
    }

    @objc private func captureSessionWasInterrupted(notification: Notification) {
        notifyDelegateInterruptionChanged(interrupted: true)
    }

    @objc private func captureSessionInterruptionEnded(notification: Notification) {
        notifyDelegateInterruptionChanged(interrupted: false)
    }

    @objc private func applicationWillResignActive(notification: Notification) {
        outputLock.lock()
        outputEnabled = false
        outputLock.unlock()
    }

    @objc private func applicationDidBecomeActive(notification: Notification) {
        outputLock.lock()
        outputEnabled = true
        outputLock.unlock()
    }

    private func changeState(state: CaptureSessionState) {
        DispatchQueue.main.async {[weak self] in
            guard let captureSession = self else {
                return
            }
            let changed = (captureSession.state != state)
            captureSession.state = state

            guard changed else {
                return
            }
            captureSession.notifyDelegateStateChanged(state: state)
        }
    }
}

// MARK: - Delegate
extension CaptureSession {

    fileprivate func notifyDelegateDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer,
                                                         captureVideoOrientation: AVCaptureVideoOrientation) {
        delegate?.captureSession(self, didOutputSampleBuffer: sampleBuffer, withOrientation: captureVideoOrientation)
    }

    fileprivate func notifyDelegateStateChanged(state: CaptureSessionState) {
        delegate?.captureSession(self, stateChanged: state)
    }

    fileprivate func notifyDelegateConfigurationFailed() {
        DispatchQueue.main.async {[weak self] in
            guard let captureSession = self else {
                return
            }
            captureSession.delegate?.captureSessionConfigurationFailed(captureSession)
        }
    }

    fileprivate func notifyDelegateRuntimeError() {
        DispatchQueue.main.async {[weak self] in
            guard let captureSession = self else {
                return
            }
            captureSession.delegate?.captureSessionRuntimeError(captureSession)
        }
    }

    fileprivate func notifyDelegateInterruptionChanged(interrupted: Bool) {
        delegate?.captureSession(self, interruptionChanged: interrupted)
    }

}

extension CaptureSession: AVCaptureVideoDataOutputSampleBufferDelegate {

    public func captureOutput(_ captureOutput: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        outputLock.lock()

        guard outputEnabled else {
            outputLock.unlock()
            return
        }

        if !CMSampleBufferDataIsReady(sampleBuffer) {
            outputLock.unlock()
            return
        }

        if captureOutput != self.captureVideoDataOutput {
            outputLock.unlock()
            return
        }

        guard let configuration = self.configuration else {
            outputLock.unlock()
            return
        }

        notifyDelegateDidOutputSampleBuffer(sampleBuffer: sampleBuffer, captureVideoOrientation: configuration.videoOrientation)

        outputLock.unlock()
    }

    public func captureOutput(_ captureOutput: AVCaptureOutput,
                              didDrop sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        //Nothing
    }

}

extension CaptureSession: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                       didOutput metadataObjects: [AVMetadataObject],
                       from connection: AVCaptureConnection) {
        metadataFaceObjects = metadataObjects
            .compactMap { $0 as? AVMetadataFaceObject }
            .map { metadataFaceObject -> AVMetadataFaceObject? in
            return output.transformedMetadataObject(for: metadataFaceObject, connection: connection) as? AVMetadataFaceObject
        }.compactMap { $0 }
    }

}
