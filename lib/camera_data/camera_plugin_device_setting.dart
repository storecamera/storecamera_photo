import 'camera_plugin_type.dart';
import 'map_ext.dart';

class CameraPluginDeviceSetting {
  final CameraPosition? currentPosition;
  final bool isTorchAvailable;
  final bool isFlashAvailable;
  final double minZoom;
  final double maxZoom;

  final bool isExposureAvailable;
  final double minExposure;
  final double maxExposure;
  final double currentExposure;

  CameraPluginDeviceSetting(this.currentPosition, this.isTorchAvailable, this.isFlashAvailable, this.minZoom, this.maxZoom, this.isExposureAvailable, this.minExposure, this.maxExposure, this.currentExposure);

  factory CameraPluginDeviceSetting.map(Map map) {
    return CameraPluginDeviceSetting(
      valueToCameraPosition(map.get<String>('currentPosition')),
      map.get<bool>('isTorchAvailable') ?? false,
      map.get<bool>('isFlashAvailable') ?? false,
      map.get<double>('minZoom') ?? 1.0,
      map.get<double>('maxZoom') ?? 1.0,
      map.get<bool>('isExposureAvailable') ?? false,
      map.get<double>('minExposure') ?? 0.0,
      map.get<double>('maxExposure') ?? 0.0,
      map.get<double>('currentExposure') ?? 0.0,
    );
  }
}