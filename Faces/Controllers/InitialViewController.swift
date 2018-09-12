import UIKit

final class InitialViewController: UIViewController {

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var countLabel: UILabel!

    private var totalFaceCount: Int = 0
    private var currentFaceCount: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.global().async { [weak self] in
            self?.recognize()
        }
    }

    private func recognize() {
        if let path = Bundle.main.resourcePath {
            let imagePath = path
            let url = NSURL(fileURLWithPath: imagePath)
            let fileManager = FileManager.default

            let properties = [URLResourceKey.localizedNameKey,
                              URLResourceKey.creationDateKey,
                              URLResourceKey.localizedTypeDescriptionKey]

            do {
                let imageURLs = try fileManager.contentsOfDirectory(at: url as URL, includingPropertiesForKeys: properties, options:FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
                totalFaceCount = imageURLs.filter({ (url) -> Bool in
                    return url.absoluteString.contains("_face.jpg") || url.absoluteString.contains("_face.jpeg")
                }).count

                setCount(currentFaceCount)

                imageURLs.forEach { (url) in
                    if url.absoluteString.contains("_face.jpg") || url.absoluteString.contains("_face.jpeg") {
                        print(url)

                        let firstImageData = try! Data(contentsOf: url)
                        let firstImage = UIImage(data: firstImageData)

                        let newUser = FaceUser()
                        newUser.name = url.absoluteString.components(separatedBy: "/").last
                        newUser.faceDescriptors = RecognitionSession.asyncProcess(pixelBufer: MainViewController.buffer(from: firstImage!)!).first

                        AppDelegate.faceDescriptors.append(newUser)
                        currentFaceCount += 1
                        setCount(currentFaceCount)
                    }
                }

                showFaces()
            } catch let error as NSError {
                print(error.description)
            }
        }
    }

    private func setCount(_ count: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.countLabel.text = "\(self?.currentFaceCount ?? 0)/\(self?.totalFaceCount ?? 0) faces recognized"
        }
    }

    private func showFaces() {
        DispatchQueue.main.async {
            UIApplication.shared.delegate?.window.unsafelyUnwrapped?.rootViewController = NavigationHelper.createMainViewController()
        }
    }

}
