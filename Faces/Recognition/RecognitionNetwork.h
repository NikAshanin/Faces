#import "Frame.h"
#import "FrameProcessor.h"

@interface RecognitionNetwork : NSObject <FrameProcessor>

- (instancetype)initWithModelPath:(NSString *)modelPath;

@end
