import Foundation
import UIKit

public final class BlurringService {

    public static func isImageBlurred(image: UIImage) -> Int {
        return Blurring.isImageBlurry(image)
    }

}
