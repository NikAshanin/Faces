import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    static var faceDescriptors = [FaceUser]()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        window?.rootViewController = NavigationHelper.createInitialViewController()

        return true
    }
    
    static func findDiff(arr1: Array<Float>, arr2: Array<Float>) -> Float {
        var sum: Float = 0.0
        
        var arr3 = Array<Float>()
        for (index, _) in arr1.enumerated() {
            let diff = arr2[index] - arr1[index]
            arr3.append(diff)
            
            sum = sum + arr3[index]*arr3[index]
        }
        
        return sum
    }

}
