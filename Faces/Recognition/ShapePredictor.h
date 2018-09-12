#import "Frame.h"
#import "FrameProcessor.h"

@interface ShapePredictor : NSObject <FrameProcessor>

- (instancetype)initWithModelPath:(NSString *)modelPath;

@end
