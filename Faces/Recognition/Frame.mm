#import "Frame.h"
#import "FrameData.h"
#import "FrameHelpers.h"

@interface Frame ()

@property (strong, nonatomic) FrameData *data;
@property (assign, nonatomic) CGRect debugFrameImageHighlightedRect;

@end

@implementation Frame

#pragma mark - Public

- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer
                  andFaceRectangles:(NSArray<NSValue *> *)faceRectangles {
    self = [super init];
    if (self) {
        [self configureWithPixelBuffer:pixelBuffer
                     andFaceRectangles:faceRectangles];
    }
    return self;
}

- (void)dealloc {
    //Nothing
}

- (NSArray<NSArray<NSNumber *> *> *)faceDescriptors {
    std::vector<dlib::matrix<float,0,1>> face_descriptors = self.data->dlib_face_descriptors;
    if (face_descriptors.size() == 0) {
        return @[];
    }

    NSMutableArray<NSArray<NSNumber *> *> *faceDescriptors = [NSMutableArray new];
    for (auto face_descriptor : face_descriptors) {
        NSMutableArray<NSNumber *> *faceDescriptor = [NSMutableArray new];
        for (auto face_feature : face_descriptor) {
            [faceDescriptor addObject:[NSNumber numberWithFloat:face_feature]];
        }
        [faceDescriptors addObject:faceDescriptor];
    }

    return [faceDescriptors copy];
}

#pragma mark - Private

- (void)configureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer
               andFaceRectangles:(NSArray<NSValue *> *)faceRectangles {
    self.data = [[FrameData alloc] initWithPixelBuffer:pixelBuffer
                                     andFaceRectangles:faceRectangles];

    if (faceRectangles.count > 0) {
        self.debugFrameImageHighlightedRect = faceRectangles.firstObject.CGRectValue;
    }
}

#pragma mark - Private (Debug)

- (UIImage *)debugFrameImageWithHighlightedFace {
    CGRect highlightedRect = self.debugFrameImageHighlightedRect;
    if (CGRectIsEmpty(highlightedRect)) {
        return nil;
    }

    return imageFromCvMatWithHighlightedRect(self.data->opencv_rgb_image, highlightedRect);
}

- (UIImage *)debugFaceImage {
    std::vector<dlib::matrix<dlib::rgb_pixel>> dlib_face_matrices = self.data->dlib_face_matrices;
    if (dlib_face_matrices.size() == 0) {
        return nil;
    }

    return imageFromDlibMat(dlib_face_matrices.front());
}

@end
