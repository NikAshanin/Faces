import XCTest
import Faces

class BlurringTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testNonBlurOne() {
        let bundle = Bundle(for: BlurringTests.self)
        let image = UIImage(named: "nonBlurOne.jpg", in: bundle, compatibleWith: nil)
        XCTAssert(BlurringService.isImageBlurred(image: image!) > 240,
                  "Blurring test one failed \(BlurringService.isImageBlurred(image: image!))")    }

    func testNonBlurTwo() {
        let bundle = Bundle(for: BlurringTests.self)
        let image = UIImage(named: "nonBlurTwo.jpg", in: bundle, compatibleWith: nil)
        XCTAssert(BlurringService.isImageBlurred(image: image!) > 240,
                  "Blurring test failed \(BlurringService.isImageBlurred(image: image!))")

    }

    func testBlurOne() {
        let bundle = Bundle(for: BlurringTests.self)
        let image = UIImage(named: "blurOne.jpg", in: bundle, compatibleWith: nil)
        XCTAssert(BlurringService.isImageBlurred(image: image!) < 200,
                  "Blurring test failed \(BlurringService.isImageBlurred(image: image!))")
    }

    func testBlurTwo() {
        let bundle = Bundle(for: BlurringTests.self)
        let image = UIImage(named: "blurTwo.jpg", in: bundle, compatibleWith: nil)
        XCTAssert(BlurringService.isImageBlurred(image: image!) < 200,
                  "Blurring test failed \(BlurringService.isImageBlurred(image: image!))")

    }

    func testBlurThree() {
        let bundle = Bundle(for: BlurringTests.self)
        let image = UIImage(named: "blurThree.jpg", in: bundle, compatibleWith: nil)
        XCTAssert(BlurringService.isImageBlurred(image: image!) < 200,
                  "Blurring test failed \(BlurringService.isImageBlurred(image: image!))")

    }

    func testBlurFour() {
        let bundle = Bundle(for: BlurringTests.self)
        let image = UIImage(named: "blurFour.jpg", in: bundle, compatibleWith: nil)
        XCTAssert(BlurringService.isImageBlurred(image: image!) < 200,
                  "Blurring test failed \(BlurringService.isImageBlurred(image: image!))")

    }

}
