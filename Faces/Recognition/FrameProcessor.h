#import <Foundation/Foundation.h>

@class Frame;

@protocol FrameProcessor <NSObject>

@required
- (void)processFrame:(Frame *)frame;

@end
