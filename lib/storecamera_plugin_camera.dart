import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'camera_data/camera_plugin_device_setting.dart';
import 'camera_data/camera_plugin_status.dart';
import 'camera_data/camera_plugin_type.dart';

class StoreCameraPluginCamera {
  static const CHANNEL = 'io.storecamera.store_camera_plugin_camera';
  static const MethodChannel _channel = MethodChannel(CHANNEL);

  static String getViewId(int id) => '${CHANNEL}_$id';

  final int id;
  late final MethodChannel _viewChannel;
  StoreCameraPluginCameraFlutterViewMethod? _viewMethod;

  StoreCameraPluginCamera(this.id)
      : _viewChannel = MethodChannel(getViewId(id)) {
    _viewChannel.setMethodCallHandler((call) async {
      switch (call.method.toFlutterViewMethod) {
        case FlutterViewMethod.ON_CAMERA_STATUS:
          if (call.arguments is Map) {
            CameraStatus? status = mapToCameraStatus(call.arguments);
            if (status != null) {
              _viewMethod?.onCameraStatus(status);
            }
          }
          break;
        case FlutterViewMethod.ON_CAMERA_MOTION:
          double? degree;
          if (call.arguments is double) {
            degree = call.arguments as double?;
          } else if (call.arguments is int) {
            degree = (call.arguments as int).toDouble();
          }
          if (degree != null) {
            _viewMethod?.onCameraMotion(degree);
          }
          break;
        case null:
          break;
      }

      return null;
    });
  }

  void setPluginFlutterMethod(
      StoreCameraPluginCameraFlutterViewMethod? method) {
    _viewMethod = method;
  }

  // static Future<PermissionResult> hasPermission() async {
  //   return PermissionResult.values.byName(
  //       await _channel.invokeMethod(PlatformMethod.HAS_PERMISSION.method));
  // }
  //
  // static Future<PermissionResult> requestPermission() async {
  //   return PermissionResult.values.byName(
  //       await _channel.invokeMethod(PlatformMethod.REQUEST_PERMISSION.method));
  // }
}

// enum PermissionResult { GRANTED, DENIED, DENIED_TO_APP_SETTING }
//
// enum PlatformMethod {
//   HAS_PERMISSION,
//   REQUEST_PERMISSION,
// }
//
// extension PlatformMethodExtension on PlatformMethod {
//   String get method {
//     switch (this) {
//       case PlatformMethod.HAS_PERMISSION:
//         return '${StoreCameraPluginCamera.CHANNEL}/HAS_PERMISSION';
//       case PlatformMethod.REQUEST_PERMISSION:
//         return '${StoreCameraPluginCamera.CHANNEL}/REQUEST_PERMISSION';
//     }
//   }
// }

extension StoreCameraPluginCameraView on StoreCameraPluginCamera {
  Future<void> pause() =>
      _viewChannel.invokeMethod(PlatformViewMethod.ON_PAUSE.method);

  Future<void> resume() =>
      _viewChannel.invokeMethod(PlatformViewMethod.ON_RESUME.method);

  Future<Uint8List?> capture(
      CameraRatio ratio, CameraResolution resolution) async {
    final result = await _viewChannel.invokeMethod(
        PlatformViewMethod.CAPTURE.method,
        {'ratio': ratio.value, 'resolution': resolution.value});
    if (result is Uint8List) {
      return result;
    } else if (result is String) {
      if (kDebugMode) {
        print('KKH capture $result');
      }
    }
    return null;
  }

  Future<Uint8List?> captureByRatio(double ratio) async {
    final result = await _viewChannel.invokeMethod(
        PlatformViewMethod.CAPTURE_BY_RATIO.method, ratio);
    if (result is Uint8List) {
      return result;
    } else if (result is String) {
      if (kDebugMode) {
        print('###### capture result: $result');
      }
    }
    return null;
  }

  Future<CameraPluginDeviceSetting?> setCameraPosition(
      CameraPosition cameraPosition) async {
    final result = await _viewChannel.invokeMethod(
        PlatformViewMethod.SET_CAMERA_POSITION.method, cameraPosition.value);
    if (result is Map) {
      return CameraPluginDeviceSetting.map(result);
    }
    return null;
  }

  Future<bool> setTorch(CameraTorch torch) async {
    final result = await _viewChannel.invokeMethod(
        PlatformViewMethod.SET_TORCH.method, torch.value);
    if (result is bool) {
      return result;
    }
    return false;
  }

  Future<bool> setFlash(CameraFlash flash) async {
    final result = await _viewChannel.invokeMethod(
        PlatformViewMethod.SET_FLASH.method, flash.value);
    if (result is bool) {
      return result;
    }
    return false;
  }

  Future<void> setZoom(double zoom) {
    return _viewChannel.invokeMethod(PlatformViewMethod.SET_ZOOM.method, zoom);
  }

  Future<void> setExposure(double exposure) {
    return _viewChannel.invokeMethod(
        PlatformViewMethod.SET_EXPOSURE.method, exposure);
  }

  Future<void> setMotion(CameraMotion motion) {
    return _viewChannel.invokeMethod(
        PlatformViewMethod.SET_MOTION.method, motion.value);
  }

  Future<void> onTap(double dx, double dy) {
    return _viewChannel.invokeMethod(PlatformViewMethod.ON_TAP.method, {
      'dx': dx,
      'dy': dy,
    });
  }
}

abstract class StoreCameraPluginCameraFlutterViewMethod {
  void onCameraStatus(CameraStatus status);

  void onCameraMotion(double radian);
}

enum PlatformViewMethod {
  ON_PAUSE,
  ON_RESUME,
  CAPTURE,
  CAPTURE_BY_RATIO,
  SET_CAMERA_POSITION,
  SET_TORCH,
  SET_FLASH,
  SET_ZOOM,
  SET_EXPOSURE,
  SET_MOTION,
  ON_TAP,
}

extension PlatformViewMethodExtension on PlatformViewMethod {
  String get method {
    switch (this) {
      case PlatformViewMethod.ON_PAUSE:
        return '${StoreCameraPluginCamera.CHANNEL}/ON_PAUSE';
      case PlatformViewMethod.ON_RESUME:
        return '${StoreCameraPluginCamera.CHANNEL}/ON_RESUME';
      case PlatformViewMethod.CAPTURE:
        return '${StoreCameraPluginCamera.CHANNEL}/CAPTURE';
      case PlatformViewMethod.CAPTURE_BY_RATIO:
        return '${StoreCameraPluginCamera.CHANNEL}/CAPTURE_BY_RATIO';
      case PlatformViewMethod.SET_CAMERA_POSITION:
        return '${StoreCameraPluginCamera.CHANNEL}/SET_CAMERA_POSITION';
      case PlatformViewMethod.SET_TORCH:
        return '${StoreCameraPluginCamera.CHANNEL}/SET_TORCH';
      case PlatformViewMethod.SET_FLASH:
        return '${StoreCameraPluginCamera.CHANNEL}/SET_FLASH';
      case PlatformViewMethod.SET_ZOOM:
        return '${StoreCameraPluginCamera.CHANNEL}/SET_ZOOM';
      case PlatformViewMethod.SET_EXPOSURE:
        return '${StoreCameraPluginCamera.CHANNEL}/SET_EXPOSURE';
      case PlatformViewMethod.SET_MOTION:
        return '${StoreCameraPluginCamera.CHANNEL}/SET_MOTION';
      case PlatformViewMethod.ON_TAP:
        return '${StoreCameraPluginCamera.CHANNEL}/ON_TAP';
    }
  }
}

enum FlutterViewMethod {
  ON_CAMERA_STATUS,
  ON_CAMERA_MOTION,
}

extension StringToFlutterViewMethod on String {
  FlutterViewMethod? get toFlutterViewMethod {
    try {
      return FlutterViewMethod.values.byName(
          substring('${StoreCameraPluginCamera.CHANNEL}/'.length, length));
    } catch (_) {}

    return null;
  }
}

// FlutterMethod? methodToFlutter(String method) {
//   final index = method.
//   method.substring(method.indexOf(pattern))
//   switch (method) {
//     case '${StoreCameraPluginCamera.CHANNEL}/ON_CAMERA_STATUS':
//       return FlutterMethod.ON_CAMERA_STATUS;
//     case '${StoreCameraPluginCamera.CHANNEL}/ON_CAMERA_MOTION':
//       return FlutterMethod.ON_CAMERA_MOTION;
//   }
//   return null;
// }
