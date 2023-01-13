#import "StoreCameraPhoto.h"
#if __has_include(<storecamera_photo/storecamera_photo-Swift.h>)
#import <storecamera_photo/storecamera_photo-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "storecamera_photo-Swift.h"
#endif

@implementation StoreCameraPhoto
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftStorecameraPhotoPlugin registerWithRegistrar:registrar];
}
@end
