#import <AVFoundation/AVFoundation.h>

#import <dlib/opencv/cv_image.h>

@interface FrameData : NSObject {
    @public
    cv::Mat opencv_rgb_image;
    dlib::cv_image<dlib::rgb_pixel> dlib_image; //share memory with opencv_rgb_image
    std::vector<dlib::rectangle> dlib_face_rectangles;
    std::vector<dlib::matrix<dlib::rgb_pixel>> dlib_face_matrices;
    std::vector<dlib::matrix<float,0,1>> dlib_face_descriptors;

}

+ (instancetype) __unavailable new;
- (instancetype) __unavailable init;
- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer
                  andFaceRectangles:(NSArray<NSValue *> *)faceRectangles;

@end
