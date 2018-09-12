#import <opencv2/imgproc/imgproc.hpp>
#import <dlib/dnn.h>
#import <dlib/opencv.h>

#import "FrameHelpers.h"

UIImage *imageFromCvMat(cv::Mat mat) {
    NSData *matData = [NSData dataWithBytes:mat.data length:mat.elemSize() * mat.total()];

    CGColorSpaceRef colorSpace;
    if (mat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }

    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)matData);
    CGImageRef imageRef = CGImageCreate(mat.cols, mat.rows, 8, 8 * mat.elemSize(), mat.step[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, dataProvider, NULL, false, kCGRenderingIntentDefault);
    UIImage *image = [UIImage imageWithCGImage:imageRef];

    CGImageRelease(imageRef);
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(colorSpace);

    return image;
}

UIImage *imageFromCvMatWithHighlightedRect(cv::Mat mat, CGRect highlightedRect) {
    cv::Mat highlightedMat;
    mat.copyTo(highlightedMat);
    cv::rectangle(highlightedMat, cv::Point(highlightedRect.origin.x, highlightedRect.origin.y), cv::Point(highlightedRect.origin.x + highlightedRect.size.width, highlightedRect.origin.y + highlightedRect.size.height), cv::Scalar(255, 255, 255, 255), 3, CV_AA);
    return imageFromCvMat(highlightedMat);
}

UIImage *imageFromDlibMat(dlib::matrix<dlib::rgb_pixel> mat) {
    return imageFromCvMat(dlib::toMat(mat));
}
