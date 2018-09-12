#import <AVFoundation/AVFoundation.h>

@class FrameData;

@interface Frame : NSObject

@property (strong, nonatomic, readonly) FrameData *data;
@property (strong, nonatomic, readonly) NSArray<NSArray<NSNumber *> *> *faceDescriptors;

//Expect pixelBuffer of kCVPixelFormatType_32BGRA format
+ (instancetype) __unavailable new;
- (instancetype) __unavailable init;
- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer
                  andFaceRectangles:(NSArray<NSValue *> *)faceRectangles;

- (UIImage *)debugFrameImageWithHighlightedFace;
- (UIImage *)debugFaceImage;

@end
