
/// 1:1 Full : Original
/// 1:1 Standard : 2048x2048
/// 1:1 Low : 1024x1024
/// 3:4 Full : Original
/// 3:4 Standard : 1536x2048
/// 3:4 Low : 768x1028
/// 9:16 Full : Original
/// 9:16 Standard : 1440x2560
/// 9:16 Low : 720x1280

enum CameraRatio {
  RATIO_1_1,
  RATIO_4_5,
  RATIO_3_4,
  RATIO_9_16
}

extension CameraRatioExtension on CameraRatio {
  double get hRatio {
    switch(this) {
      case CameraRatio.RATIO_1_1:
        return 1;
      case CameraRatio.RATIO_3_4:
        return 4.0 / 3.0;
      case CameraRatio.RATIO_4_5:
        return 5.0 / 4.0;
      case CameraRatio.RATIO_9_16:
        return 16.0 / 9.0;
    }
  }

  double get vRatio {
    switch(this) {
      case CameraRatio.RATIO_1_1:
        return 1;
      case CameraRatio.RATIO_3_4:
        return 3.0 / 4.0;
      case CameraRatio.RATIO_4_5:
        return 4.0 / 5.0;
      case CameraRatio.RATIO_9_16:
        return 9.0 / 16.0;
    }
  }

  String get value {
    switch(this) {
      case CameraRatio.RATIO_1_1:
        return '1:1';
      case CameraRatio.RATIO_3_4:
        return '3:4';
      case CameraRatio.RATIO_4_5:
        return '4:5';
      case CameraRatio.RATIO_9_16:
        return '9:16';
    }
  }

  static CameraRatio? from(String value) {
    for(final ratio in CameraRatio.values) {
      if(ratio.value == value) {
        return ratio;
      }
    }
    return null;
  }
}

enum CameraResolution {
  FULL,
  STANDARD,
  LOW
}

extension CameraResolutionExtension on CameraResolution {
  String get value {
    switch(this) {
      case CameraResolution.FULL:
        return 'FULL';
      case CameraResolution.STANDARD:
        return 'STANDARD';
      case CameraResolution.LOW:
        return 'LOW';
    }
  }

  static CameraResolution? from(String value) {
    for(final resolution in CameraResolution.values) {
      if(resolution.value == value) {
        return resolution;
      }
    }
    return null;
  }
}

enum CameraPosition {
  BACK,
  FRONT
}

extension CameraPositionExtension on CameraPosition {
  String get value {
    switch(this) {
      case CameraPosition.BACK:
        return 'BACK';
      case CameraPosition.FRONT:
        return 'FRONT';
    }
  }
}

CameraPosition? valueToCameraPosition(String? value) {
  for (final _value in CameraPosition.values) {
    if (_value.value == value) {
      return _value;
    }
  }
  return null;
}

class CameraSize {
  final CameraRatio ratio;
  final int width;
  final int height;

  CameraSize(this.ratio, this.width, this.height);

  Map toMap() => {
    'width': width,
    'height': height,
  };
}

enum CameraTorch {
  OFF,
  ON,
}

extension CameraTorchExtension on CameraTorch {
  String get value {
    switch(this) {
      case CameraTorch.OFF:
        return 'OFF';
      case CameraTorch.ON:
        return 'ON';
    }
  }
}

enum CameraFlash {
  OFF,
  ON,
  AUTO
}

extension CameraFlashExtension on CameraFlash {
  String get value {
    switch(this) {
      case CameraFlash.OFF:
        return 'OFF';
      case CameraFlash.ON:
        return 'ON';
      case CameraFlash.AUTO:
        return 'AUTO';
    }
  }
}

enum CameraMotion {
  OFF,
  ON,
}

extension CameraMotionExtension on CameraMotion {
  String get value {
    switch(this) {
      case CameraMotion.OFF:
        return 'OFF';
      case CameraMotion.ON:
        return 'ON';
    }
  }
}