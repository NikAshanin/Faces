#import <dlib/dnn.h>
#import "FrameData.h"
#import "ShapePredictor.h"

using namespace dlib;
using namespace std;

@interface ShapePredictor() {
    shape_predictor sp;
}

@end

@implementation ShapePredictor

#pragma mark - Public

- (instancetype)initWithModelPath:(NSString *)modelPath {
    self = [super init];
    if (self) {
        [self configureWithModelPath:modelPath];
    }
    return self;
}

#pragma mark - Private

- (void)configureWithModelPath:(NSString *)modelPath {
    deserialize(string(modelPath.UTF8String)) >> sp;
}

#pragma mark - FrameProcessor

- (void)processFrame:(Frame *)frame {
    if (!frame) {
        return;
    }

    std::vector<rectangle> face_rectangles = frame.data->dlib_face_rectangles;
    if (face_rectangles.size() == 0) {
        return;
    }

    cv_image<rgb_pixel> image = frame.data->dlib_image;
    matrix<rgb_pixel> image_matrix = mat(image); // perfomance issue, deep copy

    std::vector<matrix<rgb_pixel>> face_matrices;
    for (auto face_rectangle: face_rectangles) {
        auto face_shape = sp(image_matrix, face_rectangle);
        matrix<rgb_pixel> face_chip;
        extract_image_chip(image_matrix, get_face_chip_details(face_shape, 150, 0.25), face_chip);
        face_matrices.push_back(move(face_chip));
    }

    if (face_matrices.size() == 0) {
        return;
    }

    frame.data->dlib_face_matrices = face_matrices;
}

@end
