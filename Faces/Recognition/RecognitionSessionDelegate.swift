internal protocol RecognitionSessionDelegate: NSObjectProtocol {

    func recognitionSession(_ recognitionSession: RecognitionSession, faceDescriptorsChanged faceDescriptors: [[Float]])
    func recognitionSession(_ recognitionSession: RecognitionSession, debugFrameImage: UIImage?, debugFaceImage: UIImage?)

}
