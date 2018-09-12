import UIKit
import AVFoundation
import Vision

final class MainViewController: UIViewController {

    // View model

    var currentOrientation: AVCaptureDevice.Position = .front
    var changeOrientation: AVCaptureDevice.Position {
        return self.currentOrientation == .front ? .back : .front
    }

    // MARK: - Data

    private var isSendingImage: Bool = false

    func startRecognize(points: [Float]?) {
        guard let points = points else {
            return
        }

        self.isSendingImage = true
    }

    // MARK: - Outlets

    @IBOutlet fileprivate weak var treshholdLabel: UILabel!
    @IBOutlet fileprivate weak var leftDebugView: UIImageView!
    @IBOutlet fileprivate weak var rightDebugView: UIImageView!
    
    var nameLabel: UILabel?

    let faceDetection = VNDetectFaceRectanglesRequest()
    let faceLandmarks = VNDetectFaceLandmarksRequest()
    let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    let faceDetectionRequest = VNSequenceRequestHandler()

    fileprivate let capturingQueue = DispatchQueue(label: "Faces.Capturing")
    fileprivate let metadataQueue = DispatchQueue(label: "Faces.Metadata")
    fileprivate let processingQueue = DispatchQueue(label: "Faces.Processing")
    fileprivate var captureSession: CaptureSession?
    fileprivate var recognitionSession: RecognitionSession?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red

        let captureSession = CaptureSession(capturingQueue: capturingQueue,
                                            metadataQueue: metadataQueue)
        captureSession.delegate = self
        captureSession.configuration = CaptureSessionConfiguration(position: .back,
                                                                   resolution: CMVideoDimensions(width: 1280, height:720),
                                                                   frameRate: 25.0,
                                                                   videoOrientation: .portrait)
        captureSession.start()
        self.captureSession = captureSession

        if let previewLayer = captureSession.previewLayer {
            previewLayer.frame = view.bounds
            view.layer.insertSublayer(previewLayer, at: 0)
        }

        let recognitionSession = RecognitionSession(processingQueue: self.processingQueue)
        recognitionSession.delegate = self
        recognitionSession.debug = true
        self.recognitionSession = recognitionSession
        
        nameLabel = UILabel.init(frame: CGRect.init(x: 0, y: 400, width: 300, height: 300))
        nameLabel?.font = UIFont.systemFont(ofSize: 24)
        nameLabel?.textColor = .yellow
        nameLabel?.textAlignment = .right
        view.addSubview(nameLabel!)
    }

    override func viewDidLayoutSubviews() {
        captureSession?.previewLayer?.frame = view.bounds
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    @IBAction func changeCameraView(_ sender: Any) {
        currentOrientation = changeOrientation
        captureSession?.configuration = CaptureSessionConfiguration(position: currentOrientation,
                                                                   resolution: CMVideoDimensions(width: 1280, height:720),
                                                                   frameRate: 25.0,
                                                                   videoOrientation: .portrait)
    }

}

extension MainViewController: CaptureSessionDelegate {

    internal func captureSession(_ captureSession: CaptureSession,
                                 didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
                                 withOrientation captureVideoOrientation: AVCaptureVideoOrientation) {
        guard let recognitionSession = self.recognitionSession else {
            return
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvImageBuffer: pixelBuffer, options: (attachments as? [String : Any]?)!)

        // leftMirrored for front camera
//        let ciImageWithOrientation = ciImage.applyingOrientation(Int32(UIImageOrientation.leftMirrored.rawValue))

        detectFace(on: ciImage)

        recognitionSession.process(pixelBufer: pixelBuffer)
        
//        let ashaninImage = UIImage(named: "ASHANIN.jpg")
//        let davydov = UIImage(named: "DAVYDOV.jpg")
//        let kate = UIImage(named: "KATE.jpg")
//        let savin = UIImage(named: "SAVIN.jpg")
//        let toriblack = UIImage(named: "toriblack.jpg")

        
//        recognitionSession.process(pixelBufer: self.buffer(from: toriblack!)!)
    }

    internal func captureSession(_ captureSession: CaptureSession, stateChanged state: CaptureSessionState) {
        //Nothing
    }

    internal func captureSessionConfigurationFailed(_ captureSession: CaptureSession) {
        //Nothing
    }

    internal func captureSessionRuntimeError(_ captureSession: CaptureSession) {
        //Nothing
    }

    func captureSession(_ captureSession: CaptureSession, interruptionChanged interrupted: Bool) {
        //Nothing
    }

}

final class FaceUser {
    
    var faceDescriptors: [Float]?
    var name: String?

    
    
}

extension MainViewController: RecognitionSessionDelegate {

    func recognitionSession(_ recognitionSession: RecognitionSession,
                            faceDescriptorsChanged faceDescriptors: [[Float]]) {
        print(faceDescriptors)
        guard faceDescriptors.count != 0 else {
            return
        }
        
//        let ashanin = FaceUser()
//        ashanin.faceDescriptors = AppDelegate.ashaninArr
//        ashanin.name = "ashanin"
//
//        let kate = FaceUser()
//        kate.faceDescriptors = AppDelegate.kateArr
//        kate.name = "kate"
//
//        let savin = FaceUser()
//        savin.faceDescriptors = AppDelegate.savinArr
//        savin.name = "savin"
//
//        let toriblack = FaceUser()
//        toriblack.faceDescriptors = AppDelegate.toriblackArr
//        toriblack.name = "toriblack"

//        let ashanin = AppDelegate.findDiff(arr1: faceDescriptors.first!, arr2: AppDelegate.ashaninArr)
//        let kate = AppDelegate.findDiff(arr1: faceDescriptors.first!, arr2: AppDelegate.kateArr)
//        let savin = AppDelegate.findDiff(arr1: faceDescriptors.first!, arr2: AppDelegate.savinArr)
//        let toriblack = AppDelegate.findDiff(arr1: faceDescriptors.first!, arr2: AppDelegate.toriblackArr)
        
        let arr = AppDelegate.faceDescriptors

        let min = arr.min { (user1, user2) -> Bool in
            let d1 = AppDelegate.findDiff(arr1: faceDescriptors.first!, arr2: user1.faceDescriptors!)
            let d2 = AppDelegate.findDiff(arr1: faceDescriptors.first!, arr2: user2.faceDescriptors!)
            return d1<d2
        }
        
        DispatchQueue.main.async {
            self.nameLabel?.text = min?.name
        }
        
        
//        print(AppDelegate.findDiff(arr1: faceDescriptors.first!, arr2: AppDelegate.davydovArr))
        
//        guard let firstFaceDescriptor = faceDescriptors.first else {
//            viewModel.startRecognize(points: nil)
//            return
//        }
//        viewModel.startRecognize(points: firstFaceDescriptor)
    }

    func recognitionSession(_ recognitionSession: RecognitionSession, debugFrameImage: UIImage?, debugFaceImage: UIImage?) {
//        DispatchQueue.main.async {
//            self.leftDebugView.image = debugFrameImage
//            self.rightDebugView.image = debugFaceImage
//            self.treshholdLabel.text = "Current threshhold: \n \(Blurring.isImageBlurry(debugFaceImage))"
//        }
    }

}

extension MainViewController {

    func detectFace(on image: CIImage) {
//        try? faceDetectionRequest.perform([faceDetection], on: image)
//        let img = UIImage(ciImage: image)
//        if let results = faceDetection.results as? [VNFaceObservation] {
//            if !results.isEmpty {
//                faceLandmarks.inputFaceObservations = results
//            }
//        }
    }
    
    static func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer

        UIApplicationOpenSettingsURLString
        let arr = [1,2,4,3]
        
        let arr2 = arr.sorted(by: { $0 > $1 })
        
//        return challenges.sorted(by: { (left, right) -> Bool in
//            +                left.challengeId < right.challengeId
//            +            })
    }

}
