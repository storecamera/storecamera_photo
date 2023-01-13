import 'camera_plugin_device_setting.dart';
import 'camera_plugin_type.dart';
import 'map_ext.dart';

abstract class CameraStatus {
  CameraStatusType get type;
}

enum CameraStatusType {
  BINDING,
  NO_HAS_PERMISSION,
  ERROR,
}

extension CameraStatusTypeExtension on CameraStatusType {
  String get value {
    switch(this) {
      case CameraStatusType.BINDING:
        return 'BINDING';
      case CameraStatusType.NO_HAS_PERMISSION:
        return 'NO_HAS_PERMISSION';
      case CameraStatusType.ERROR:
        return 'ERROR';
    }
  }
}

CameraStatusType? valueToCameraStatusType(String? value) {
  for (final _value in CameraStatusType.values) {
    if (_value.value == value) {
      return _value;
    }
  }
  return null;
}

CameraStatus? mapToCameraStatus(Map? map) {
  switch(valueToCameraStatusType(map?.get('type'))) {
    case CameraStatusType.BINDING:
      return CameraStatusBinding.map(map!);
    case CameraStatusType.NO_HAS_PERMISSION:
      return CameraStatusNoHasPermission();
    case CameraStatusType.ERROR:
      return CameraStatusError();
    case null:
      return null;
  }
}

class CameraStatusBinding extends CameraStatus {
  
  CameraStatusBinding(this.availablePosition, this.availableMotion, this.setting);

  factory CameraStatusBinding.map(Map map) {
    final availablePosition = <CameraPosition>[];
    for(final value in map.getList<String>('availablePosition')) {
      final position = valueToCameraPosition(value);
      if(position != null) {
        availablePosition.add(position);
      }
    }
    final availableMotion = map.get<bool>('availableMotion') ?? false;
    return CameraStatusBinding(
        availablePosition,
        availableMotion,
        CameraPluginDeviceSetting.map(map.get('setting') ?? {})
    );
  }

  @override
  CameraStatusType get type => CameraStatusType.BINDING;

  final List<CameraPosition> availablePosition;
  final bool availableMotion;
  final CameraPluginDeviceSetting setting;

  @override
  String toString() {
    return 'CameraStatusBinding{availablePosition: $availablePosition setting: $setting}';
  }
}

class CameraStatusNoHasPermission extends CameraStatus {
  @override
  CameraStatusType get type => CameraStatusType.NO_HAS_PERMISSION;
}

class CameraStatusError extends CameraStatus {
  @override
  CameraStatusType get type => CameraStatusType.ERROR;
}

