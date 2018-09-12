import UIKit

final class NavigationHelper {

    static func createInitialViewController() -> InitialViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "InitialViewController")
        guard let initial = vc as? InitialViewController else {
            return InitialViewController()
        }
        return initial
    }

    static func createMainViewController() -> MainViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MainViewController")
        guard let main = vc as? MainViewController else {
            return MainViewController()
        }
        return main
    }

}
