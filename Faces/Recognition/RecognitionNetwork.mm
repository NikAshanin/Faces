#import "FrameData.h"
#import "RecognitionNetwork.h"
#import "RecognitionNetworkTypes.h"

@interface RecognitionNetwork() {
    anet_type net;
}

@end

@implementation RecognitionNetwork

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
    deserialize(string(modelPath.UTF8String)) >> net;
}

#pragma mark - FrameProcessor

- (void)processFrame:(Frame *)frame {
    if (!frame) {
        return;
    }

    std::vector<matrix<rgb_pixel>> face_matrices= frame.data->dlib_face_matrices;
    if (face_matrices.size() == 0) {
        return;
    }

    std::vector<matrix<float,0,1>> face_descriptors = net(face_matrices);
    if (face_descriptors.size() == 0) {
        return;
    }

    frame.data->dlib_face_descriptors = face_descriptors;
}

@end
