import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'media_map_ext.dart';
import 'storecamera_plugin_media.dart';

class PluginDataSet<T> {
  final int timeMs;
  final bool permission;
  final List<T> list;

  PluginDataSet(this.timeMs, this.permission, this.list);

  @override
  String toString() {
    return 'PluginDataSet{timeMs: $timeMs, permission: $permission, list: $list}';
  }
}

enum PluginSortOrder {
  DATE_DESC,
  DATE_ARC,
}

extension PluginSortOrderExtension on PluginSortOrder {
  String get sortOrder {
    String result = '';
    switch (this) {
      case PluginSortOrder.DATE_DESC:
        result = 'DATE_DESC';
        break;
      case PluginSortOrder.DATE_ARC:
        result = 'DATE_ARC';
        break;
    }

    return result;
  }
}

class PluginFolder {
  final String? id;
  final String displayName;
  final int count;

  PluginFolder(this.id, this.displayName, this.count);

  factory PluginFolder.map(Map map) => PluginFolder(
        map.get('id'),
        map.get('displayName') ?? '',
        map.get('count') ?? 0,
      );

  @override
  String toString() {
    return 'PluginFolder{id: $id, displayName: $displayName, count: $count}';
  }
}

class PluginImageInfo {
  final String fullPath;
  final String displayName;
  final String mimeType;

  /// nullable

  PluginImageInfo(this.fullPath, this.displayName, this.mimeType);

  factory PluginImageInfo.map(Map map) => PluginImageInfo(
        map.get('fullPath') ?? '',
        map.get('displayName') ?? '',
        map.get('mimeType') ?? '',
      );
}

class PluginImage {
  final String id;
  final int width;
  final int height;
  final int modifyTimeMs;
  PluginImageInfo? _info;

  PluginImage(this.id, this.width, this.height, this.modifyTimeMs,
      {PluginImageInfo? info})
      : _info = info;

  static PluginImage? factoryMap(Map map) {
    final String? id = map.get('id');
    if (id != null) {
      return PluginImage(id, map.get('width') ?? 0, map.get('height') ?? 0,
          map.get('modifyTimeMs') ?? 0,
          info: map.get('info', converter: (map) {
            return PluginImageInfo.map(map);
          }));
    }
    return null;
  }

  Future<Uint8List?> readImageData() =>
      StoreCameraPluginMedia.readImageData(id);

  PluginImageInfo? get info => _info;

  Future<PluginImageInfo?> getImageInfo() async {
    _info ??= await StoreCameraPluginMedia.getImageInfo(id);
    return _info;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PluginImage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          modifyTimeMs == other.modifyTimeMs;

  @override
  int get hashCode => id.hashCode ^ modifyTimeMs.hashCode;

  @override
  String toString() {
    return 'PluginImage{id: $id, width: $width, height: $height, modifyTimeMs: $modifyTimeMs}';
  }
}

class PluginBitmap {
  final int width;
  final int? height;
  final Uint8List buffer;

  PluginBitmap(this.width, this.height, this.buffer);

  static PluginBitmap? factoryMap(Map map) {
    int width = map.get('width');
    int? height = map.get('height');
    Uint8List? buffer = map.get('buffer');

    if (width > 0 && height! > 0 && buffer != null) {
      return PluginBitmap(width, height, buffer);
    }
    return null;
  }
}

enum PluginImageFormat { BITMAP, JPG, PNG }

extension PluginImageFormatExtension on PluginImageFormat {
  String get format {
    switch (this) {
      case PluginImageFormat.BITMAP:
        return 'BITMAP';
      case PluginImageFormat.JPG:
        return 'JPG';
      case PluginImageFormat.PNG:
        return 'PNG';
    }
  }

  static PluginImageFormat? from(String? value) {
    for (final format in PluginImageFormat.values) {
      if (format.format == value) {
        return format;
      }
    }
    return null;
  }
}

class PluginImageBuffer {
  final PluginImageFormat format;
  final int width;
  final int height;
  final Uint8List buffer;

  PluginImageBuffer._(this.format, this.width, this.height, this.buffer);

  static PluginImageBuffer? factoryMap(Map? map) {
    int? width = map?.get('width');
    int? height = map?.get('height');
    PluginImageFormat? format =
        PluginImageFormatExtension.from(map?.get('format'));
    Uint8List? buffer = map?.get('buffer');
    if (width != null && height != null && format != null && buffer != null) {
      return PluginImageBuffer._(format, width, height, buffer);
    }
    return null;
  }

  static Future<PluginImageBuffer?> imageToBuffer(ui.Image? image) async {
    if (image == null) {
      return null;
    }
    ByteData byteData = await (image.toByteData(
        format: ui.ImageByteFormat.rawRgba) as FutureOr<ByteData>);
    return PluginImageBuffer._(PluginImageFormat.BITMAP, image.width,
        image.height, byteData.buffer.asUint8List());
  }

  factory PluginImageBuffer.jpg(Uint8List bytes) {
    return PluginImageBuffer._(PluginImageFormat.JPG, 0, 0, bytes);
  }

  factory PluginImageBuffer.png(Uint8List bytes) {
    return PluginImageBuffer._(PluginImageFormat.PNG, 0, 0, bytes);
  }

  Map map() => {
        'width': width,
        'height': height,
        'format': format.format,
        'buffer': buffer,
      };
}
