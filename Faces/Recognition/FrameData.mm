#import <UIKit/UIKit.h>

#import <opencv2/imgproc/imgproc.hpp>

#import "FrameData.h"

using namespace dlib;

@interface FrameData()

@end

@implementation FrameData

#pragma mark - Public

- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer
                  andFaceRectangles:(NSArray<NSValue *> *)faceRectangles {
    self = [super init];
    if (self) {
        [self configureWithPixelBuffer:pixelBuffer];
        [self configureWithFaceRectangles:faceRectangles];
    }
    return self;
}

- (void)dealloc {
    //Nothing
}

#pragma mark - Private

- (void)configureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    cv::Mat opencv_bgra_image(height, width, CV_8UC4, baseAddress, 0);

    //Heavy, about 15% CPU
    cv::cvtColor(opencv_bgra_image, opencv_rgb_image, CV_BGRA2RGB);
    dlib_image = cv_image<rgb_pixel>(opencv_rgb_image);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

- (void)configureWithFaceRectangles:(NSArray<NSValue *> *)faceRectangles {
    for (NSValue *faceRectangleValue in faceRectangles) {
        CGRect faceRectangleRect = faceRectangleValue.CGRectValue;
        rectangle faceRectangle(faceRectangleRect.origin.x,
                                faceRectangleRect.origin.y,
                                faceRectangleRect.origin.x + faceRectangleRect.size.width,
                                faceRectangleRect.origin.y + faceRectangleRect.size.height);
        dlib_face_rectangles.push_back(faceRectangle);
    }
}

@end
