import CoreVideo

internal class RecognitionSession {

    internal weak var delegate: RecognitionSessionDelegate?
    internal var debug = false

    fileprivate let processingQueue: DispatchQueue
    fileprivate var faceDetector: FaceDetector?
    fileprivate var shapePredictor: ShapePredictor?
    fileprivate var recognitionNetwork: RecognitionNetwork?

    fileprivate let processingLock = NSLock()
    fileprivate var processing: Bool = false

    internal init(processingQueue: DispatchQueue) {
        self.processingQueue = processingQueue

        processingQueue.async { [weak self] in
            self?.commonInit()
        }
    }

    private func commonInit() {
        faceDetector = FaceDetector()

        if let shapePredictorModelPath = Bundle.main.path(forResource: "shape_predictor_68_face_landmarks", ofType: "dat") {
            shapePredictor = ShapePredictor(modelPath: shapePredictorModelPath)
        }

        if let recognitionNetworkModelPath =
            Bundle.main.path(forResource: "dlib_face_recognition_resnet_model_v1", ofType: "dat") {
            recognitionNetwork = RecognitionNetwork(modelPath: recognitionNetworkModelPath)
        }
    }

    func process(pixelBufer: CVPixelBuffer) {
        guard CVPixelBufferGetWidth(pixelBufer) > 0 else {
            return
        }

        guard
            let shapePredictor = self.shapePredictor,
            let recognitionNetwork = self.recognitionNetwork else {
            return
        }

        processingLock.lock()

        guard !processing else {
            processingLock.unlock()
            return
        }


        processing = true
        processingLock.unlock()
        processingQueue.async {[weak self] in
            guard let recognitionSession = self else {
                return
            }

            let faceRectangles = recognitionSession.faceDetector?.process(pixelBuffer: pixelBufer).map {
                return NSValue(cgRect: $0)
            }
            
            guard !faceRectangles!.isEmpty else {
                recognitionSession.processingLock.lock()
                recognitionSession.delegate?.recognitionSession(recognitionSession, faceDescriptorsChanged: [])
                recognitionSession.processing = false
                recognitionSession.processingLock.unlock()
                return
            }

            let frame = Frame(pixelBuffer: pixelBufer, andFaceRectangles: faceRectangles)
            shapePredictor.processFrame(frame)
            recognitionNetwork.processFrame(frame)

            recognitionSession.processingLock.lock()
            let faceDescriptors = frame?.faceDescriptors.map {
                return $0.map {
                    return $0.floatValue
                }
            }

            if recognitionSession.debug {
                recognitionSession.delegate?.recognitionSession(recognitionSession,
                                                                debugFrameImage: frame?.debugFrameImageWithHighlightedFace(),
                                                                debugFaceImage: frame?.debugFaceImage())
            }
            recognitionSession.delegate?.recognitionSession(recognitionSession, faceDescriptorsChanged: faceDescriptors ?? [])
            recognitionSession.processing = false
            recognitionSession.processingLock.unlock()
        }
    }
    
    static func asyncProcess(pixelBufer: CVPixelBuffer) -> [[Float]] {
        let faceDetector = FaceDetector()
        var sp: ShapePredictor?
        var rn: RecognitionNetwork?

        if let shapePredictorModelPath = Bundle.main.path(forResource: "shape_predictor_68_face_landmarks", ofType: "dat") {
            sp = ShapePredictor(modelPath: shapePredictorModelPath)
        }

        if let recognitionNetworkModelPath =
            Bundle.main.path(forResource: "dlib_face_recognition_resnet_model_v1", ofType: "dat") {
            rn = RecognitionNetwork(modelPath: recognitionNetworkModelPath)
        }

        guard CVPixelBufferGetWidth(pixelBufer) > 0 else {
            return [[]]
        }

        guard let shapePredictor = sp,
            let recognitionNetwork = rn else {
                return [[]]
        }

//        processingLock.lock()
//
//        guard !processing else {
//            processingLock.unlock()
//            return [[]]
//        }
        
        
//        processing = true
//        processingLock.unlock()
//        processingQueue.async {[weak self] in
//            guard let recognitionSession = self else {
//                return [[]]
//            }
        
            let faceRectangles = faceDetector.process(pixelBuffer: pixelBufer).map {
                return NSValue(cgRect: $0)
            }
            
            guard !faceRectangles.isEmpty else {
//                recognitionSession.processingLock.lock()
//                recognitionSession.delegate?.recognitionSession(recognitionSession, faceDescriptorsChanged: [])
//                recognitionSession.processing = false
//                recognitionSession.processingLock.unlock()
                return [[]]
            }
            
            let frame = Frame(pixelBuffer: pixelBufer, andFaceRectangles: faceRectangles)
            shapePredictor.processFrame(frame)
            recognitionNetwork.processFrame(frame)
            
//            recognitionSession.processingLock.lock()
            let faceDescriptors = frame?.faceDescriptors.map {
                return $0.map {
                    return $0.floatValue
                }
            }
        
            return faceDescriptors!
        
//            if recognitionSession.debug {
//                recognitionSession.delegate?.recognitionSession(recognitionSession,
//                                                                debugFrameImage: frame?.debugFrameImageWithHighlightedFace(),
//                                                                debugFaceImage: frame?.debugFaceImage())
//            }
//            recognitionSession.delegate?.recognitionSession(recognitionSession, faceDescriptorsChanged: faceDescriptors ?? [])
//            recognitionSession.processing = false
//            recognitionSession.processingLock.unlock()
//        }
    }

}
