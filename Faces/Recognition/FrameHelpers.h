#import <UIKit/UIKit.h>

#import <dlib/opencv/cv_image.h>

UIImage *imageFromCvMat(cv::Mat mat);
UIImage *imageFromCvMatWithHighlightedRect(cv::Mat mat, CGRect highlightedRect);
UIImage *imageFromDlibMat(dlib::matrix<dlib::rgb_pixel> mat);
